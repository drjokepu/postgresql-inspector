//
//  PGUUID.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 03/02/2013.
//
//

#import "PGUUID.h"

@interface PGUUID()
{
    CFUUIDRef uuid;
}
@end

@implementation PGUUID

-(void)dealloc
{
    if (uuid != NULL)
    {
        CFRelease(uuid);
        uuid = NULL;
    }
}

-(id)init
{
    if ((self = [super init]))
    {
        self->uuid = CFUUIDCreate(NULL);
    }
    return self;
}

-(id)initWithUUIDBytes:(const uuid_t)bytes
{
    if ((self = [super init]))
    {
        
        self->uuid = CFUUIDCreateFromUUIDBytes(NULL, (CFUUIDBytes){
            .byte0 = bytes[0],
            .byte1 = bytes[1],
            .byte2 = bytes[2],
            .byte3 = bytes[3],
            .byte4 = bytes[4],
            .byte5 = bytes[5],
            .byte6 = bytes[6],
            .byte7 = bytes[7],
            .byte8 = bytes[8],
            .byte9 = bytes[9],
            .byte10 = bytes[10],
            .byte11 = bytes[11],
            .byte12 = bytes[12],
            .byte13 = bytes[13],
            .byte14 = bytes[14],
            .byte15 = bytes[15]
        });
    }
    return self;
}

-(id)initWithUUIDString:(NSString *)string
{
    if ((self = [super init]))
    {
        self->uuid = CFUUIDCreateFromString(NULL, (__bridge CFStringRef)string);
    }
    return self;
}

+(id)UUID
{
    return [[PGUUID alloc] init];
}

-(NSString *)UUIDString
{
    return (__bridge_transfer NSString*)CFUUIDCreateString(NULL, self->uuid);
}

-(void)getUUIDBytes:(uuid_t)uuidBytes
{
    const CFUUIDBytes cfBytes = CFUUIDGetUUIDBytes(self->uuid);
    uuidBytes[0] = cfBytes.byte0;
    uuidBytes[1] = cfBytes.byte1;
    uuidBytes[2] = cfBytes.byte2;
    uuidBytes[3] = cfBytes.byte3;
    uuidBytes[4] = cfBytes.byte4;
    uuidBytes[5] = cfBytes.byte5;
    uuidBytes[6] = cfBytes.byte6;
    uuidBytes[7] = cfBytes.byte7;
    uuidBytes[8] = cfBytes.byte8;
    uuidBytes[9] = cfBytes.byte9;
    uuidBytes[10] = cfBytes.byte10;
    uuidBytes[11] = cfBytes.byte11;
    uuidBytes[12] = cfBytes.byte12;
    uuidBytes[13] = cfBytes.byte13;
    uuidBytes[14] = cfBytes.byte14;
    uuidBytes[15] = cfBytes.byte15;
}

@end

bool system_has_NSUUID(void)
{
    static bool system_has_NSUUID_value_has_been_cached = false, system_has_NSUUID_value = false;
    
    if (!system_has_NSUUID_value_has_been_cached)
    {
        system_has_NSUUID_value = (NSClassFromString(@"NSUUID") != nil);
        system_has_NSUUID_value_has_been_cached = true;
    }
    
    return system_has_NSUUID_value;
}
