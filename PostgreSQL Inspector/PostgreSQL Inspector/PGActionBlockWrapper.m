//
//  PGActionBlockWrapper.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 05/06/2013.
//
//

#import "PGActionBlockWrapper.h"

@implementation PGActionBlockWrapper
@synthesize block;

-(id)initWithBlock:(void (^)())theBlock
{
    if ((self = [super init]))
    {
        self.block = theBlock;
    }
    return self;
}

-(void)action
{
    block();
}

@end
