//
//  SqliteParamInt64.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 17/05/2011.
//  Copyright 2011 Tamas Czinege. All rights reserved.
//

#import "SqliteParamInt64.h"


@implementation SqliteParamInt64

@synthesize value;

- (id) initWithName:(NSString *)theName int64Value:(long long)theValue
{
    if ((self = [super initWithName:theName]))
    {
        self.value = theValue;
    }
    return self;
}

- (void)bindTo:(sqlite3_stmt *)command
{
    sqlite3_bind_int64(command, [self getIndex:command], value);
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@ = %lli", name, value];
}

@end
