//
//  PGSchemaObject.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 02/05/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import "PGSchemaObject.h"
#import "PGConnection.h"

@implementation PGSchemaObject
@synthesize oid, name;

-(id)initWithOid:(NSInteger)theOid
{
    if ((self = [super init]))
    {
        self.oid = theOid;
    }
    return self;
}

@end
