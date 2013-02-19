//
//  PGConstraint.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 06/13/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PGConstraint.h"
#import "PGConstraintColumn.h"
#import "PGRelationColumn.h"

@implementation PGConstraint

-(NSString *)constraintTypeDescription
{
    return [PGConstraint describeContraintType:self.type];
}

-(NSString *)referencedTableDescription
{
    if (self.relationId == 0)
        return @"";
    else if ([self.relationNamespaceName isEqualToString:@"public"])
        return self.relationName;
    else
        return [NSString stringWithFormat:@"%@.%@", self.relationNamespaceName, self.relationName];
}

-(BOOL)needsColumns
{
    // for the time being
    return YES;
}

+(NSString *)describeContraintType:(PGConstraintType)constraintType
{
    switch (constraintType)
    {
        case PGConstraintTypeCheck:
            return @"Check";
        case PGConstraintTypeExclusion:
            return @"Exclusion";
        case PGConstraintTypePrimaryKey:
            return @"Primary Key";
        case PGConstraintTypeForeignKey:
            return @"Foreign Key";
        case PGConstraintTypeTrigger:
            return @"Trigger";
        case PGConstraintTypeUniqueKey:
            return @"Unique Key";
        case PGConstraintTypeNone:
        default:
            return @"";
    }
}

+(NSString*)constraintUIDefinition:(PGConstraint *)constraint inColumns:(NSArray*)columns
{
    switch (constraint.type)
    {
        case PGConstraintTypePrimaryKey:
        case PGConstraintTypeUniqueKey:
            return [PGConstraint listOfColumnsNamesOfConstraint:constraint inColumns:columns];
        case PGConstraintTypeForeignKey:
            return [PGConstraint foreignKeyUIDescription:constraint inColumns:columns];
        case PGConstraintTypeCheck:
            return constraint.src;
        default:
            return @"";
    }
}

+(NSString*)foreignKeyUIDescription:(PGConstraint*)constraint inColumns:(NSArray*)columns
{
    NSString *columnList = [PGConstraint listOfColumnsNamesOfConstraint:constraint
                                                                            inColumns:columns];
    if ([constraint.relationNamespaceName isEqualToString:@"public"])
    {
        return [NSString stringWithFormat:@"%@, referencing %@", columnList, constraint.relationName];
    }
    else
    {
        return [NSString stringWithFormat:@"%@, referencing %@.%@", columnList, constraint.relationNamespaceName, constraint.relationName];
    }
}

+(NSString*)listOfColumnsNamesOfConstraint:(PGConstraint*)constraint inColumns:(NSArray*)columns
{
    if (constraint == nil || [constraint.columns count] == 0) return @"";
    
    NSMutableArray *columnNames = [[NSMutableArray alloc] initWithCapacity:[constraint.columns count]];
    for (NSUInteger i = 0; i < [constraint.columns count]; i++)
    {
        const PGConstraintColumn *constraintColumn = constraint.columns[i];
        if (constraintColumn.columnNumber == -1)
        {
            if ([constraintColumn.columnName length] > 0)
                [columnNames addObject:constraintColumn.columnName];
        }
        else
        {
            [columnNames addObject:((PGRelationColumn*)columns[constraintColumn.columnNumber]).name];
        }
    }
    return [columnNames componentsJoinedByString:@", "];
}

@end
