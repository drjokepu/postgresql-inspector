//
//  SqliteParamInt32.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 15/04/2011.
//  Copyright 2011 Tamas Czinege. All rights reserved.
//

#import "SqliteParamInt32.h"

@implementation SqliteParamInt32

@synthesize value;

-(id)initWithName:(NSString *)theName int32Value:(int)theValue
{
    if ((self = [super initWithName:theName]))
    {
        self.value = theValue;
    }
    return self;
}

- (void)bindTo:(sqlite3_stmt *)command
{
    sqlite3_bind_int(command, [self getIndex:command], value);
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@ = %i", name, value];
}

@end
