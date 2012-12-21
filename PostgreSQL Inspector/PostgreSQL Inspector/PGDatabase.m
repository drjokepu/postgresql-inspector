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
         "select c.relname, c.relkind, c.oid, n.nspname from pg_catalog.pg_class c inner join pg_catalog.pg_namespace n on n.oid = c.relnamespace order by c.relname";

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
        NSInteger oid = [[[result.rows objectAtIndex:i] objectAtIndex:1] integerValue];
        if ([schemaName isEqualToString:@"public"]) publicSchemaIndex = i;
        
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
        NSInteger relOid = [[row objectAtIndex:2] integerValue];
        NSString *schemaName = [row objectAtIndex:3];
        
        switch ([relKind charValue])
        {
            case 'r':
                [[[schemaNameLookup valueForKey:schemaName] tableNames] addObject:[[PGTableIdentifier alloc] initWithName:relName oid:relOid]];
                break;
            case 'v':
                [[[schemaNameLookup valueForKey:schemaName] viewNames] addObject:[[PGTableIdentifier alloc] initWithName:relName oid:relOid]];
                break;
        }
    }
}

@end
