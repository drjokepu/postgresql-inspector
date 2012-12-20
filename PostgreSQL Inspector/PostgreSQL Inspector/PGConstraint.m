//
//  PGConstraint.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 06/13/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PGConstraint.h"
#import "PGOid.h"
#import "PGConstraintColumn.h"

@interface PGConstraint()

+(NSArray*)columnsInRow:(NSArray*)row;

@end

@implementation PGConstraint

+(NSArray *)columnsInRow:(NSArray *)row
{
    NSArray *columnNumbers = [row objectAtIndex:15];
    NSArray *pkFkOperators = [row objectAtIndex:16];
    NSArray *pkPkOperators = [row objectAtIndex:17];
    NSArray *fkFkOperators = [row objectAtIndex:18];
    NSArray *exclusionOperators = [row objectAtIndex:19];
    
    if ([columnNumbers isKindOfClass:[NSNull class]]) columnNumbers = [[NSArray alloc] init];
    if ([pkFkOperators isKindOfClass:[NSNull class]]) pkFkOperators = [[NSArray alloc] init];
    if ([pkPkOperators isKindOfClass:[NSNull class]]) pkPkOperators = [[NSArray alloc] init];
    if ([fkFkOperators isKindOfClass:[NSNull class]]) fkFkOperators = [[NSArray alloc] init];
    if ([exclusionOperators isKindOfClass:[NSNull class]]) exclusionOperators = [[NSArray alloc] init];
    
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
