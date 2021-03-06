//
//  PGUserDefaults.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 13/12/2012.
//
//

#import "PGUserDefaults.h"

static NSString *isIPv6EnabledKey = @"isIPv6Enabled";
static NSString *uppercaseUUIDsKey = @"uppercaseUUIDs";

@implementation PGUserDefaults

+(void)registerDefaults
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:
     @{
           isIPv6EnabledKey: @NO
     }];
}

+(void)sync
{
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(BOOL)isIPv6Enabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:isIPv6EnabledKey];
}

+(void)setIPv6Enabled:(BOOL)isEnabled
{
    [[NSUserDefaults standardUserDefaults] setBool:isEnabled forKey:isIPv6EnabledKey];
}

+(BOOL)uppercaseUUIDs
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:uppercaseUUIDsKey];
}

+(void)setUppercaseUUIDs:(BOOL)areEnabled
{
    [[NSUserDefaults standardUserDefaults] setBool:areEnabled forKey:uppercaseUUIDsKey];
}

@end
