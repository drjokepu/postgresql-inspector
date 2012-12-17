//
//  PGOid.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 06/11/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PGOid.h"

@implementation PGOid
@synthesize type;

-(id)initWithType:(PGType)theType
{
    if ((self = [super init]))
    {
        self.type = theType;
    }
    return self;
}

@end
