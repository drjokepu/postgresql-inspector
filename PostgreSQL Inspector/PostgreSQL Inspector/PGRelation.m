//
//  PGRelation.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 24/05/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import "PGRelation.h"
#import "PGConnection.h"
#import "PGOid.h"
#import "PGRelationColumn.h"

@implementation PGRelation

@synthesize namespace, tablespace, owner, tuples, kind, columns;

-(void)loadRelationFromCatalog:(PGConnection *)connection
{
//    @autoreleasepool
//    {
//        static const NSString *commandText =
//            @"select relname, relnamespace, relowner, reltuples, relkind from pg_catalog.pg_class where oid = $1";
//    
//        PGCommand *command = [[PGCommand alloc] initWithConnection:connection commandText:commandText];
//        [command addParameter:[[PGOid alloc] initWithValue:(unsigned int)self.oid]];
//        
//        NSArray *resultSet = [command execute];
//        PGResult *result = [resultSet objectAtIndex:0];
//        resultSet = nil;
//        
//        self.name = (NSString*)[[result.rows objectAtIndex:0] objectAtIndex:0];
//        self.namespace = [(NSNumber*)[[result.rows objectAtIndex:0] objectAtIndex:1] integerValue];
//        self.owner = [(NSNumber*)[[result.rows objectAtIndex:0] objectAtIndex:2] unsignedIntegerValue];
//        self.kind = [(NSString*)[[result.rows objectAtIndex:0] objectAtIndex:0] characterAtIndex:0];
//        
//        self.columns = [[NSMutableArray alloc] initWithArray:[PGRelationColumn loadColumnsInRelation:self.oid fromCatalog:connection]];
//    }
}

@end
