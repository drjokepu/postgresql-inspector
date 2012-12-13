//
//  PGUserDefaults.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 13/12/2012.
//
//

#import <Foundation/Foundation.h>

@interface PGUserDefaults : NSObject

+(void)registerDefaults;
+(void)sync;

+(BOOL)isIPv6Enabled;
+(void)setIPv6Enabled:(BOOL)isEnabled;

@end
