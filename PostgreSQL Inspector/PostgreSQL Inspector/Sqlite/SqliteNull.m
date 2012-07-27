//
//  SqliteNull.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 13/05/2011.
//  Copyright 2011 Tamas Czinege. All rights reserved.
//

#import "SqliteNull.h"

static SqliteNull *sharedNull = nil;

@implementation SqliteNull

-(NSString *)description
{
    return @"NULL";
}

-(id)copyWithZone:(NSZone *)zone
{
    return self;
}

-(int)intValue
{
    return 0;
}

+(SqliteNull *)null
{
    if (sharedNull == nil)
        sharedNull = [[SqliteNull alloc] init];
    
    return sharedNull;
}

@end
