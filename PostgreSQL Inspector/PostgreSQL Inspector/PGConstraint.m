//
//  PGConstraint.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 06/13/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PGConstraint.h"
#import "PGConstraintColumn.h"

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

@end
