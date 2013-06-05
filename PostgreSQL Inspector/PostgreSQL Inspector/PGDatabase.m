//
//  PGDatabase.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 30/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import "PGDatabase.h"
#import "PGCommand.h"
#import "PGConnectionEntry.h"
#import "PGConnection.h"
#import "PGSchemaObjectIdentifier.h"
#import "PGSchemaObjectGroup.h"
#import "PGSchemaIdentifier.h"
#import "PGResult.h"
#import "PGTableIdentifier.h"

static NSArray *commonTypes = nil;
static void initCommonTypes(void);

@interface PGDatabase()

@end

@implementation PGDatabase

@synthesize connectionEntry;
@synthesize schemaNames, schemaNameLookup, schemaObjectGroups, publicSchemaIndex;
@synthesize delegate;

-(id)initWithConnectionEntry:(PGConnectionEntry *)theConnectionEntry
{
    if ((self = [super init]))
    {
        self.publicSchemaIndex = -1;
        self.connectionEntry = theConnectionEntry;
        self.schemaObjectGroups =
            [[NSArray alloc] initWithObjects:
                [[PGSchemaObjectGroup alloc] initWithName:@"Tables" groupType:PGSchemaObjectGroupTypeTables],
                [[PGSchemaObjectGroup alloc] initWithName:@"Views" groupType:PGSchemaObjectGroupTypeViews],
                nil];
    }
    return self;
}

-(BOOL)hideSystemSchemas
{
    return NO;
}

-(BOOL)isSystemSchema:(NSString *)schemaName
{
    return ([schemaName isEqualToString:@"information_schema"] ||
            [schemaName isEqualToString:@"pg_catalog"] ||
            [schemaName isEqualToString:@"pg_temp_1"] ||
            [schemaName isEqualToString:@"pg_toast"] ||
            [schemaName isEqualToString:@"pg_toast_temp_1"]);
}

-(void)loadSchema:(PGConnection *)connection
{
    PGCommand *command = [[PGCommand alloc] init];
    command.connection = connection;
    command.commandText =
        @"select nspname, oid from pg_catalog.pg_namespace order by nspname;"
         "select c.relname, c.relkind, c.oid, n.nspname, n.oid from pg_catalog.pg_class c inner join pg_catalog.pg_namespace n on n.oid = c.relnamespace order by c.relname";

    [command execAsyncWithCallback:^(PGResult *result) {
        switch (result.index)
        {
            case 0:
                [self readSchemasFrom:result];
                break;
            case 1:
                [self readClassesFrom:result];
                break;
        }
    } noMoreResultsCallback:^{
        [delegate databaseDidUpdateSchema:self];
    } errorCallback:^(PGError *error) {
        
    }];
}

-(void)readSchemasFrom:(PGResult *)result
{
    NSMutableArray *localSchemaNames = [[NSMutableArray alloc] initWithCapacity:result.rowCount];
    NSMutableDictionary *localSchemaLookup = [[NSMutableDictionary alloc] initWithCapacity:result.rowCount];
    
    for (NSUInteger i = 0; i < result.rowCount; i++)
    {
        NSString *schemaName = [[result.rows objectAtIndex:i] objectAtIndex:0];
        const NSInteger oid = [[[result.rows objectAtIndex:i] objectAtIndex:1] integerValue];
        if ([PGSchemaIdentifier publicSchema:schemaName]) publicSchemaIndex = i;
        
        if (![self hideSystemSchemas] || ![self isSystemSchema:schemaName])
        {
            PGSchemaIdentifier *schema = [[PGSchemaIdentifier alloc] initWithName:schemaName oid:oid];
            [localSchemaNames addObject:schema];
            [localSchemaLookup setObject:schema forKey:schemaName];
        }
    }
    self.schemaNames = localSchemaNames;
    self.schemaNameLookup = localSchemaLookup;
}

-(void)readClassesFrom:(PGResult *)result
{
    for (NSUInteger i = 0; i < result.rowCount; i++)
    {
        NSArray *row = [result.rows objectAtIndex:i];
        NSString *relName = [row objectAtIndex:0];
        NSNumber *relKind = [row objectAtIndex:1];
        const NSInteger relOid = [[row objectAtIndex:2] integerValue];
        NSString *schemaName = [row objectAtIndex:3];
        const NSInteger schemaOid = [[row objectAtIndex:4] integerValue];
        
        PGTableIdentifier *tableIdenfifier = [[PGTableIdentifier alloc] initWithName:relName oid:relOid];
        tableIdenfifier.type = [relKind charValue];
        tableIdenfifier.schemaName = schemaName;
        tableIdenfifier.schemaOid = schemaOid;
        
        switch (tableIdenfifier.type)
        {
            case TABLE_IDENTIFIER_TYPE_TABLE:
                [[schemaNameLookup[schemaName] tableNames] addObject:tableIdenfifier];
                break;
            case TABLE_IDENTIFIER_TYPE_VIEW:
                [[schemaNameLookup[schemaName] viewNames] addObject:tableIdenfifier];
                break;
        }
    }
}

+(NSArray *)commonTypes
{
    if (commonTypes == nil) initCommonTypes();
    return commonTypes;
}

@end

static void initCommonTypes(void)
{
    commonTypes =
    @[
        @"bigint",
        @"bigserial",
        @"boolean",
        @"box",
        @"bytea",
        @"character",
        @"character varying",
        @"cidr",
        @"circle",
        @"date",
        @"daterange",
        @"decimal",
        @"double precision",
        @"inet",
        @"int4range",
        @"int8range",
        @"integer",
        @"interval",
        @"json",
        @"line",
        @"lseg",
        @"macaddr",
        @"money",
        @"numeric",
        @"numrange",
        @"oid",
        @"path",
        @"point",
        @"polygon",
        @"real",
        @"serial",
        @"smallint",
        @"smallserial",
        @"text",
        @"time",
        @"time with time zone",
        @"timestamp",
        @"timestamp with time zone",
        @"tsrange",
        @"tstzrange",
        @"uuid",
        @"xml"
    ];
}
