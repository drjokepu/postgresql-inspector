//
//  PGSchemaIdentifier.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 30/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import "PGSchemaObjectIdentifier.h"

@implementation PGSchemaObjectIdentifier
@synthesize name, oid;

-(id)initWithName:(NSString *)theName
{
    if ((self = [super init]))
    {
        self.name = theName;
    }
    return self;
}

-(id)initWithName:(NSString *)theName oid:(NSInteger)theOid
{
    if ((self = [super init]))
    {
        self.name = theName;
        self.oid = theOid;
    }
    return self;
}

@end
