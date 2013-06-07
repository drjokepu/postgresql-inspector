//
//  PGUUID.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 03/02/2013.
//
//

#import <Foundation/Foundation.h>

bool system_has_NSUUID(void);

@interface PGUUID : NSObject <NSCopying>

+(id)UUID;
-(id)init;
-(id)initWithUUIDBytes:(const uuid_t)bytes;
-(id)initWithUUIDString:(NSString *)string;
-(void)getUUIDBytes:(uuid_t)uuid;
-(NSString *)UUIDString;

@end
