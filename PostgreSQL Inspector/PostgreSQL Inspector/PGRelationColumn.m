//
//  PGRelationColumn.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 06/11/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PGRelationColumn.h"
#import "PGSchemaObject.h"

@implementation PGRelationColumn
@synthesize relationId, name, typeId, typeName, typeModifier, length, number, dimensionCount, notNull, defaultValue;

-(NSString *)fullType
{
    if (length <= 0)
    {
        return typeName;
    }
    else
    {
        return [[NSString alloc] initWithFormat:@"%@(%li)", typeName, length];
    }
}

-(NSString *)createTableDdl
{
    NSMutableString *str = [[NSMutableString alloc] init];
    @autoreleasepool
    {
        [str appendString:[PGSchemaObject escapeIdentifier:name]];
        [str appendString:@" "];
        [str appendString:typeName];
        
        if (length > 0)
        {
            [str appendFormat:@"(%li)", length];
        }
        
        if (notNull)
        {
            [str appendString:@" not null"];
        }
        
        if ([defaultValue length] >0)
        {
            [str appendString:@" default "];
            [str appendString:defaultValue];
        }
    }
    return str;
}

@end
