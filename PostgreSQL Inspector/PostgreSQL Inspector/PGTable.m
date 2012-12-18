//
//  PGTable.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 02/05/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import "PGTable.h"
#import "PGAppDelegate.h"
#import "PGConnection.h"
#import "PGConstraint.h"
#import "PGConstraintColumn.h"

@interface PGTable()
@end

@implementation PGTable
@synthesize constraints;

+(void)load:(NSInteger)oid fromConnection:(PGConnection*)connection callback:(void(^)(PGTable* table))asyncCallback
{
    [[PGAppDelegate sharedBackgroundQueue] addOperationWithBlock:^{
        PGTable *table = [[PGTable alloc] initWithOid:oid];
        [table loadRelationFromCatalog:connection asyncCallback:^{
//            table.constraints = [[NSMutableArray alloc] initWithArray:[PGConstraint loadConstraintsInRelation:oid fromCatalog:connection]];
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (asyncCallback != NULL) asyncCallback(table);
            }];
        }];
    }];
}

-(BOOL)isColumnInPrimaryKey:(NSInteger)columnNumber
{
    for (PGConstraint *constraint in self.constraints)
    {
        if (constraint.type == PGConstraintTypePrimaryKey)
        {
            for (PGConstraintColumn *constraintColumn in constraint.columns)
            {
                if (constraintColumn.columnNumber == columnNumber) return YES;
            }
            return NO;
        }
    }
    return NO;
}

@end
