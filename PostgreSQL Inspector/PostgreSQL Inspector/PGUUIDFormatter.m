//
//  PGUUIDFormatter.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 31/12/2012.
//
//

#import "PGUUIDFormatter.h"
#import "PGUserDefaults.h"

@implementation PGUUIDFormatter

-(NSString *)stringForObjectValue:(id)obj
{
    if ([obj isKindOfClass:[NSUUID class]])
    {
        NSString *str = [obj UUIDString];
        if (![PGUserDefaults uppercaseUUIDs])
        {
            str = [str lowercaseString];
        }
        return str;
    }
    else
    {
        return nil;
    }
}

-(BOOL)getObjectValue:(out __autoreleasing id *)obj forString:(NSString *)string errorDescription:(out NSString *__autoreleasing *)error
{
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:string];
    if (uuid == nil)
    {
        if (obj != NULL) *obj = nil;
        if (error != NULL) *error = @"Invalid UUID.";
        return NO;
    }
    else
    {
        if (obj != NULL) *obj = uuid;
        if (error != NULL) *error = nil;
        return YES;
    }
}

@end
