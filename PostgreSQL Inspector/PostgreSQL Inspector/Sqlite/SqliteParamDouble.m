//
//  SqliteParamDouble.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 17/05/2011.
//  Copyright 2011 Tamas Czinege. All rights reserved.
//

#import "SqliteParamDouble.h"

@implementation SqliteParamDouble

@synthesize value;

-(id)initWithName:(NSString *)theName doubleValue:(double)theValue
{
    if ((self = [super initWithName:theName]))
    {
        self.value = theValue;
    }
    return self;
}

- (void)bindTo:(sqlite3_stmt *)command
{
    sqlite3_bind_double(command, [self getIndex:command], value);
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@ = %f", name, value];
}

@end
