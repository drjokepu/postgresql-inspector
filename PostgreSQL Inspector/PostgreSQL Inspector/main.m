//
//  main.m
//  DatabaseInspector
//
//  Created by Tamas Czinege on 23/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PGAppDelegate.h"
#import "PGConnectionManager.h"
#import "PGDatabaseManager.h"
#import "PGCommand.h"

static void setup(void);
static void teardown(void);

int main(int argc, char *argv[])
{
    @autoreleasepool
    {
        setup();
        int result = NSApplicationMain(argc, (const char **)argv);
        teardown();
        return result;
    }
}

void setup(void)
{
    PGConnectionManagerInitMutexes();
    PGDatabaseManagerInitMutexes();
    PGCommandInitOperationQueue();
    PGAppDelegateInitSharedBackgroundQueue();
}

static void teardown(void)
{
    PGConnectionManagerDestroyMutexes();
    PGDatabaseManagerDestroyMutexes();
    PGCommandDestroyOperationQueue();
    PGAppDelegateDestroySharedBackgroundQueue();
}