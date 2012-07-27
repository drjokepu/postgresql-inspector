//
//  SqliteManagedReader.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 15/05/2011.
//  Copyright 2011 Tamas Czinege. All rights reserved.
//

#import "SqliteManagedReader.h"

@implementation SqliteManagedReader

- (void)deallocCommand
{
    if (command != NULL)
    {
        sqlite3_finalize(command);
        command = NULL;
    }
}

- (void)dealloc
{
    [self deallocCommand];
}

-(void)close
{
    [self deallocCommand];
}

-(BOOL)closed
{
    return command == NULL;
}

@end
