//
//  SqliteParam.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 15/04/2011.
//  Copyright 2011 Tamas Czinege. All rights reserved.
//

#import "SqliteParam.h"
#import "SqliteParamDouble.h"
#import "SqliteParamInt32.h"
#import "SqliteParamInt64.h"
#import "SqliteParamNull.h"
#import "SqliteParamString.h"
#import "SqliteNull.h"

@implementation SqliteParam

@synthesize name;

-(id)initWithName:(NSString *)theName
{
    if ((self = [super init]))
    {
        self.name = theName;
    }
    return self;
}

-(void)bindTo:(sqlite3_stmt*)command
{
    
}

-(int)getIndex:(sqlite3_stmt *)command
{
    return sqlite3_bind_parameter_index(command, [[@"@" stringByAppendingString:name] UTF8String]);
}

+(SqliteParam *)sqliteParamWithName:(NSString *)name value:(id)value
{
    if (value == nil || [value isKindOfClass:[SqliteNull class]])
    {
        return [[SqliteParamNull alloc] initWithName:name];
    }
    else if ([value isKindOfClass:[NSString class]])
    {
        NSString *string = value;
        NSInteger integerValue = [string integerValue];
        if (integerValue != 0 || [string isEqualToString:@"0"])
        {
            NSNumber *number = [[NSNumber alloc] initWithInteger:integerValue];
            SqliteParam *param = [SqliteParam sqliteParamWithName:name value:number];
            return param;
        }
        
        return [[SqliteParamString alloc] initWithName:name stringValue:value];
    }
    else if ([value isKindOfClass:[NSNumber class]])
    {
        NSNumber *number = value;
        const char *numberType = [number objCType];
        
        if (strcmp(numberType, @encode(int)) == 0) // int32
        {
            return [[SqliteParamInt32 alloc] initWithName:name int32Value:[number intValue]];
        }
        else if (strcmp(numberType, @encode(long long)) == 0) // int64
        {
            return [[SqliteParamInt64 alloc] initWithName:name int64Value:[number longLongValue]];
        }
        else if (strcmp(numberType, @encode(double)) == 0)
        {
            return [[SqliteParamDouble alloc] initWithName:name doubleValue:[number doubleValue]];
        }
        else
        {
            [NSException raise:@"InvalidNumberType" format:@"Invalid number type: %s", numberType];
            return nil;
        }
    }
    else
    {
        [NSException raise:@"InvalidParamType" format:@"Invalid parameter type: %@", [value class]];
        return nil;
    }
}

@end
