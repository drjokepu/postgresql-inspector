//
//  SqliteParamNull.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 17/05/2011.
//  Copyright 2011 Tamas Czinege. All rights reserved.
//

#import "SqliteParamNull.h"


@implementation SqliteParamNull

-(void)bindTo:(sqlite3_stmt *)command
{
    sqlite3_bind_null(command, [self getIndex:command]);
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@ = NULL", name];
}

@end
