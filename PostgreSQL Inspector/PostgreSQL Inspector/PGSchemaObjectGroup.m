//
//  PGSchemaObjectGroup.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 30/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import "PGSchemaObjectGroup.h"

@implementation PGSchemaObjectGroup
@synthesize groupType;

-(id)initWithName:(NSString *)theName groupType:(PGSchemaObjectGroupType)theGroupType
{
    if ((self = [super initWithName:theName]))
    {
        self.groupType = theGroupType;
    }
    return self;
}

@end
