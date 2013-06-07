//
//  PGUUIDFormatter.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 31/12/2012.
//
//

#import "PGUUIDFormatter.h"
#import "PGUserDefaults.h"
#import "PGUUID.h"

@implementation PGUUIDFormatter

-(NSString *)stringForObjectValue:(id)obj
{
    if ((system_has_NSUUID() && [obj isKindOfClass:[NSUUID class]]) || [obj isKindOfClass:[PGUUID class]])
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
    id uuid = system_has_NSUUID() ? [[NSUUID alloc] initWithUUIDString:string] :  [[PGUUID alloc] initWithUUIDString:string];
    
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
