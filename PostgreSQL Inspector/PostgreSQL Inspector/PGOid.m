//
//  PGOid.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 06/11/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PGOid.h"

@implementation PGOid
@synthesize value;

-(id)initWithValue:(unsigned int)theValue
{
    if ((self = [super init]))
    {
        self.value = theValue;
    }
    return self;
}

@end
