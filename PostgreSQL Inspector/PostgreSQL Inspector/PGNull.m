//
//  PGNull.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 30/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PGNull.h"

static PGNull *sharedPGNullValue = nil;

@implementation PGNull

+(PGNull *)sharedValue
{
    if (sharedPGNullValue == nil)
    {
        sharedPGNullValue = [[PGNull alloc] init];
    }
    return sharedPGNullValue;
}

-(id)copyWithZone:(NSZone *)zone
{
    return self;
}

-(NSString *)description
{
    return @"";
}

@end
