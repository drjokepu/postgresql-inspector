//
//  SqliteParamString.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 03/05/2011.
//  Copyright 2011 Tamas Czinege. All rights reserved.
//

#import "SqliteParamString.h"


@implementation SqliteParamString

@synthesize value;

- (id) initWithName:(NSString *)theName stringValue:(NSString*)theValue
{
    if ((self = [super initWithName:theName]))
    {
        self.value = theValue;
    }
    return self;
}

- (void)bindTo:(sqlite3_stmt *)command
{
    int result = sqlite3_bind_text(command, [self getIndex:command], [value UTF8String], -1, SQLITE_TRANSIENT);
    if (result != SQLITE_OK)
    {
        NSLog(@"sqlite3_bind_text error: %i %s (%@)", result, sqlite3_errmsg(sqlite3_db_handle(command)), name);
    }
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@ = '%@'", name, value];
}

@end
