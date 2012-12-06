//
//  PGError.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 08/01/2012.
//
//

#import "PGError.h"
#import "PGError+Internal.h"

@implementation PGError
@synthesize sqlErrorMessage;

-(NSString *)description
{
    return sqlErrorMessage;
}

@end
