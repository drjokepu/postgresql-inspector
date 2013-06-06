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
#import "PGRelationColumn.h"

@interface PGTable()
@end

@implementation PGTable

+(void)load:(NSInteger)oid fromConnection:(PGConnection*)connection callback:(void(^)(PGTable* table))asyncCallback
{
    [[PGAppDelegate sharedBackgroundQueue] addOperationWithBlock:^{
        PGTable *table = [[PGTable alloc] initWithOid:oid];
        [table loadRelationFromCatalog:connection asyncCallback:^{
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

-(NSString *)ddl
{
    NSMutableString *str = [[NSMutableString alloc] init];
    
    @autoreleasepool
    {
        [str appendString:@"create table "];
        [str appendString:[self schemaQualifiedName]];
        [str appendString:@"\n(\n"];
        
        BOOL first = YES;
        
        // columns
        for (PGRelationColumn *relationColumn in self.columns)
        {
            if (first)
            {
                first = NO;
            }
            else
            {
                [str appendString:@",\n"];
            }
            [str appendString:@"    "];
            [str appendString:[relationColumn createTableDdl]];
        }
    
        // constraints
        for (PGConstraint *constraint in self.constraints)
        {
            if (first)
            {
                first = NO;
            }
            else
            {
                [str appendString:@",\n"];
            }
            [str appendString:@"    "];
            [str appendString:[constraint createTableDdl]];
        }
        
        [str appendString:@"\n);\n"];
        [str appendFormat:@"alter table %@ owner to %@;\n", [self schemaQualifiedName], self.ownerName];
    }
    
    return [[NSString alloc] initWithString:str];
}

@end
