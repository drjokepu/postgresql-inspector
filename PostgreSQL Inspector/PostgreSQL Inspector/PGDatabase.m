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
#import "PGRole.h"
#import "PGTableIdentifier.h"

static NSArray *commonTypes = nil;
static void initCommonTypes(void);

@interface PGDatabase()

@end

@implementation PGDatabase
@synthesize connectionEntry, roles, schemaNames, schemaNameLookup, schemaObjectGroups, publicSchemaIndex, delegate;

-(id)initWithConnectionEntry:(PGConnectionEntry *)theConnectionEntry
{
    if ((self = [super init]))
    {
        self.publicSchemaIndex = -1;
        self.connectionEntry = theConnectionEntry;
        self.roles = [[NSArray alloc] init];
        self.schemaObjectGroups =
            [[NSArray alloc] initWithObjects:
                [[PGSchemaObjectGroup alloc] initWithName:@"Tables" groupType:PGSchemaObjectGroupTypeTables],
                [[PGSchemaObjectGroup alloc] initWithName:@"Views" groupType:PGSchemaObjectGroupTypeViews],
                [[PGSchemaObjectGroup alloc] initWithName:@"Roles" groupType:PGSchemaObjectGroupTypeRoles],
                nil];
    }
    return self;
}

-(BOOL)hideSystemSchemas
{
    return NO;
}

-(void)loadSchema:(PGConnection *)connection
{
    PGCommand *command = [[PGCommand alloc] init];
    command.connection = connection;
    command.commandText =
        @"select nspname, oid from pg_catalog.pg_namespace order by nspname;"
    
         "select c.relname, c.relkind, c.oid, n.nspname, n.oid from pg_catalog.pg_class c "
         "inner join pg_catalog.pg_namespace n on n.oid = c.relnamespace order by c.relname;"
    
         "select r.oid, r.rolname, r.rolsuper, r.rolinherit, r.rolcreaterole, r.rolcreatedb, r.rolcanlogin, r.rolconnlimit, r.rolvaliduntil, "
         "array(select b.rolname from pg_catalog.pg_auth_members m join pg_catalog.pg_roles b ON (m.roleid = b.oid) where m.member = r.oid) as memberof, "
         " r.rolreplication from pg_catalog.pg_roles r order by 2;";

    [command execAsyncWithCallback:^(PGResult *result) {
        switch (result.index)
        {
            case 0:
                [self readSchemasFrom:result];
                break;
            case 1:
                [self readClassesFrom:result];
                break;
            case 2:
                [self readRolesFrom:result];
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
        NSString *schemaName = result.rows[i][0];
        const NSInteger oid = [result.rows[i][1] integerValue];
        if ([PGSchemaIdentifier publicSchema:schemaName]) publicSchemaIndex = i;
        
        if (![self hideSystemSchemas] || ![PGSchemaIdentifier systemSchema:schemaName])
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
        NSArray *row = result.rows[i];
        NSString *relName = row[0];
        NSNumber *relKind = row[1];
        const NSInteger relOid = [row[2] integerValue];
        NSString *schemaName = row[3];
        const NSInteger schemaOid = [row[4] integerValue];
        
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

-(void)readRolesFrom:(PGResult *)result
{
    NSMutableArray *localRoles = [[NSMutableArray alloc] initWithCapacity:result.rowCount];
    for (NSUInteger i = 0; i < result.rowCount; i++)
    {
        NSArray *row = result.rows[i];
        PGRole *role = [[PGRole alloc] initWithOid:[row[0] integerValue]];
        role.name = row[1];
        role.superuser = [row[2] boolValue];
        role.inherit = [row[3] boolValue];
        role.createRole = [row[4] boolValue];
        role.createDatabase = [row[5] boolValue];
        role.login = [row[6] boolValue];
        role.connectionLimit = [row[7] integerValue];
        role.validUntil = nil;
        role.memberships = [[NSArray alloc] init];
        role.replication = [row[10] boolValue];
        [localRoles addObject:role];
    }
    
    self.roles = localRoles;
}

+(NSArray *)commonTypes
{
    if (commonTypes == nil) initCommonTypes();
    return commonTypes;
}

-(NSString *)debugDescription
{
    if (self.connectionEntry == nil)
    {
        return @"unnamed database";
    }
    else
    {
        return self.connectionEntry.database;
    }
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
