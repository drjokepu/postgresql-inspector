//
//  PGRelation.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 24/05/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import "PGRelation.h"
#import "PGCommand.h"
#import "PGConnection.h"
#import "PGOid.h"
#import "PGRelationColumn.h"
#import "PGResult.h"

@implementation PGRelation

@synthesize namespace, tablespace, owner, tuples, kind, schemaName, columns;

-(void)loadRelationFromCatalog:(PGConnection *)connection asyncCallback:(void (^)(void))asyncCallback
{
    @autoreleasepool
    {
        static const NSString *commandText =
        @"select c.relname, "
        "       c.relnamespace, "
        "       c.relowner, "
        "       c.reltuples, "
        "       c.relkind, "
        "       n.nspname "
        "  from pg_catalog.pg_class c "
        "       inner join pg_catalog.pg_namespace n "
        "               on n.oid = c.relnamespace "
        " where c.oid = %li;"
        "select a.attrelid, "
        "       a.attname, "
        "       a.atttypid, "
        "       pg_catalog.format_type(a.atttypid, a.atttypmod), "
        "       a.attlen, "
        "       a.atttypmod, "
        "       a.attnum, "
        "       a.attndims, "
        "       a.attnotnull, "
        "       d.adsrc "
        "  from pg_catalog.pg_attribute a "
        "       left outer join pg_catalog.pg_attrdef d "
        "                    on ( d.adrelid = a.attrelid "
        "                         and d.adnum = a.attnum ) "
        " where a.attrelid = $1 "
        "       and a.attnum > 0 "
        "       and a.attisdropped = false "
        " order by a.attnum;";

        
        NSString *queryText = [[NSString alloc] initWithFormat:(NSString*)commandText, self.oid];
    
        PGCommand *command = [[PGCommand alloc] init];
        command.connection = connection;
        command.commandText = queryText;
        
        [command execAsyncWithCallback:^(PGResult *result) {
            switch (result.index)
            {
                case 0:
                    [self loadDetailsFromResult:result];
                    break;
            }
        } noMoreResultsCallback:^{
            if (asyncCallback != nil) asyncCallback();
        } errorCallback:^(PGError *error) {
            
        }];
    }
}

-(void)loadDetailsFromResult:(PGResult*)result
{
    self.name = (NSString*)result.rows[0][0];
    self.namespace = [(NSNumber*)result.rows[0][1] integerValue];
    self.owner = [(NSNumber*)result.rows[0][2] unsignedIntegerValue];
    self.kind = [(NSNumber*)result.rows[0][4] charValue];
    self.schemaName = (NSString*)result.rows[0][5];
}

-(NSString *)description
{
    return [[NSString alloc] initWithFormat:@"%@.%@", self.schemaName, self.name];
}

@end
