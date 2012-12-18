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
        NSString *commandText = [[NSString alloc] initWithFormat:
                                 @"select c.relname, c.relnamespace, c.relowner, c.reltuples, c.relkind, n.nspname from pg_catalog.pg_class c inner join pg_catalog.pg_namespace n on n.oid = c.relnamespace where c.oid = %li", self.oid];
    
        PGCommand *command = [[PGCommand alloc] init];
        command.connection = connection;
        command.commandText = commandText;
        
        [command execAsyncWithCallback:^(PGResult *result) {
            self.name = (NSString*)result.rows[0][0];
            self.namespace = [(NSNumber*)result.rows[0][1] integerValue];
            self.owner = [(NSNumber*)result.rows[0][2] unsignedIntegerValue];
            self.kind = [(NSNumber*)result.rows[0][4] charValue];
            self.schemaName = (NSString*)result.rows[0][5];
            self.columns = [[NSMutableArray alloc] initWithArray:[PGRelationColumn loadColumnsInRelation:self.oid fromCatalog:connection]];
            
            if (asyncCallback != nil) asyncCallback();
        }];
    }
}

-(NSString *)description
{
    return [[NSString alloc] initWithFormat:@"%@.%@", self.schemaName, self.name];
}

@end
