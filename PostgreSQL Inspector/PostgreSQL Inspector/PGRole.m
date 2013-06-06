//
//  PGRole.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 06/06/2013.
//
//

#import "PGRole.h"
#import "PGAppDelegate.h"

@class PGConnection;
@implementation PGRole

-(NSString *)debugDescription
{
    return [NSString stringWithFormat:@"role: %@", self.name];
}

@end
