//
//  PGConstraint.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 06/13/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PGConstraint.h"
#import "PGNull.h"
#import "PGOid.h"
#import "PGConstraintColumn.h"

@interface PGConstraint()

+(NSArray*)columnsInRow:(NSArray*)row;

@end

@implementation PGConstraint
@synthesize namespaceId, type, deferrable, deferred, relationId, domainId, indexId, foreignKeyReferencedTableId, foreignKeyUpdateAction, foreignKeyDeleteAction, foreignKeyMatchType, local, inheritanceAncestorCount, columns, src;

+(NSArray *)loadConstraintsInRelation:(NSUInteger)relationId fromCatalog:(PGConnection *)connection
{
//    static const NSString *commandText =
//    @"select c.oid, c.conname, c.connamespace, c.contype, c.condeferrable, c.condeferred, c.conrelid, "
//     "       c.contypid, c.conindid, c.confrelid, c.confupdtype, c.confdeltype, c.confmatchtype, "
//     "       c.conislocal, c.coninhcount, c.conkey, c.confkey, c.conpfeqop, c.conppeqop, c.conffeqop, "
//     "       c.conexclop, c.consrc "
//     "  from pg_catalog.pg_constraint c "
//     " where c.conrelid = $1 "
//     " order by c.oid ";
//    
//    PGCommand *command = [[PGCommand alloc] initWithConnection:connection commandText:commandText];
//    [command addParameter:[[PGOid alloc] initWithValue:(unsigned int)relationId]];
//    
//    PGResult *result = [[command execute] objectAtIndex:0];
//    NSMutableArray *constraints = [[NSMutableArray alloc] initWithCapacity:result.rows.count];
//    
//    for (NSUInteger i = 0; i < result.rows.count; i++)
//    {
//        @autoreleasepool
//        {
//            NSArray *row = [result.rows objectAtIndex:i];
//            const NSInteger oid = [(NSNumber*)[row objectAtIndex:0] integerValue];
//            PGConstraint *constraint = [[PGConstraint alloc] initWithOid:oid];
//            constraint.name = [row objectAtIndex:1];
//            constraint.namespaceId = [(NSNumber*)[row objectAtIndex:2] unsignedIntegerValue];
//            constraint.type = [[row objectAtIndex:3] characterAtIndex:0];
//            constraint.deferrable = [[row objectAtIndex:4] boolValue];
//            constraint.deferred = [[row objectAtIndex:5] boolValue];
//            constraint.relationId = [(NSNumber*)[row objectAtIndex:6] unsignedIntegerValue];
//            constraint.domainId = [(NSNumber*)[row objectAtIndex:7] unsignedIntegerValue];
//            constraint.indexId = [(NSNumber*)[row objectAtIndex:8] unsignedIntegerValue];
//            constraint.foreignKeyReferencedTableId = [(NSNumber*)[row objectAtIndex:9] unsignedIntegerValue];
//            constraint.foreignKeyUpdateAction = [[row objectAtIndex:10] isKindOfClass:[PGNull class]] ? 0: [[row objectAtIndex:10] characterAtIndex:0];
//            constraint.foreignKeyDeleteAction = [[row objectAtIndex:11] isKindOfClass:[PGNull class]] ? 0: [[row objectAtIndex:11] characterAtIndex:0];
//            constraint.foreignKeyMatchType = [[row objectAtIndex:12] isKindOfClass:[PGNull class]] ? 0: [[row objectAtIndex:12] characterAtIndex:0];
//            constraint.local = [[row objectAtIndex:13] boolValue];
//            constraint.inheritanceAncestorCount = [(NSNumber*)[row objectAtIndex:14] unsignedIntegerValue];
//            constraint.columns = [[NSMutableArray alloc] initWithArray:[PGConstraint columnsInRow:row]];
//            
//            [constraints addObject:constraint];
//        }
//    }
//    
//    return constraints;
    return [NSArray new];
}

+(NSArray *)columnsInRow:(NSArray *)row
{
    NSArray *columnNumbers = [row objectAtIndex:15];
    NSArray *pkFkOperators = [row objectAtIndex:16];
    NSArray *pkPkOperators = [row objectAtIndex:17];
    NSArray *fkFkOperators = [row objectAtIndex:18];
    NSArray *exclusionOperators = [row objectAtIndex:19];
    
    if ([columnNumbers isKindOfClass:[PGNull class]]) columnNumbers = [[NSArray alloc] init];
    if ([pkFkOperators isKindOfClass:[PGNull class]]) pkFkOperators = [[NSArray alloc] init];
    if ([pkPkOperators isKindOfClass:[PGNull class]]) pkPkOperators = [[NSArray alloc] init];
    if ([fkFkOperators isKindOfClass:[PGNull class]]) fkFkOperators = [[NSArray alloc] init];
    if ([exclusionOperators isKindOfClass:[PGNull class]]) exclusionOperators = [[NSArray alloc] init];
    
    NSUInteger columnCount = [columnNumbers count];
    if ([pkFkOperators count] > columnCount) columnCount = [pkFkOperators count];
    if ([pkPkOperators count] > columnCount) columnCount = [pkPkOperators count];
    if ([fkFkOperators count] > columnCount) columnCount = [fkFkOperators count];
    if ([exclusionOperators count] > columnCount) columnCount = [exclusionOperators count];
    
    NSMutableArray *columns = [[NSMutableArray alloc] initWithCapacity:columnCount];
    
    for (NSUInteger i = 0; i < columnCount; i++)
    {
        PGConstraintColumn *column = [[PGConstraintColumn alloc] init];
        if ([columnNumbers count] > i) column.columnNumber = [[columnNumbers objectAtIndex:i] integerValue];
        if ([pkFkOperators count] > i) column.foreignKeyPKFKEqualityOperator = [[pkFkOperators objectAtIndex:i] integerValue];
        if ([pkPkOperators count] > i) column.foreignKeyPKFKEqualityOperator = [[pkPkOperators objectAtIndex:i] integerValue];
        if ([fkFkOperators count] > i) column.foreignKeyFKFKEqualityOperator = [[fkFkOperators objectAtIndex:i] integerValue];
        if ([exclusionOperators count] > i) column.exclusionOperator = [[exclusionOperators objectAtIndex:i] integerValue];
        [columns addObject:column];
    }
    
    return columns;
}

@end
