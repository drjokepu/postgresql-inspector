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

-(id)initWithPxError:(const px_error *)pxError
{
    if ((self = [super init]))
    {
        self.sqlErrorMessage = [[NSString alloc] initWithUTF8String:px_error_get_message(pxError)];
        self.errorPosition = (NSUInteger)atoi(px_error_get_position(pxError)) - 1;
    }
    return self;
}

-(NSString *)description
{
    return sqlErrorMessage;
}

@end
