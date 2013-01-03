//
//  main.m
//  DatabaseInspector
//
//  Created by Tamas Czinege on 23/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <libpq-fe.h>
#import "PGAppDelegate.h"
#import "PGConnectionManager.h"
#import "PGDatabaseManager.h"
#import "parsing/parsing.h"

static void sanityChecks(void);
static void libPqSanityCheck(void);
static void setup(void);
static void teardown(void);

int main(int argc, char *argv[])
{
    sanityChecks();
    
    @autoreleasepool
    {
        setup();
        atexit(teardown);
        return NSApplicationMain(argc, (const char **)argv);
    }
}

static void sanityChecks()
{
    libPqSanityCheck();
}

static void libPqSanityCheck()
{
    const int pqLibVersion = PQlibVersion();
    const int requiredLibPqVersion = 90201; // 9.2.1 or later
    
    if (pqLibVersion < requiredLibPqVersion)
    {
        fprintf(stderr, "Unsupported libpq version: %i, required: %i or later.\n", pqLibVersion, requiredLibPqVersion);
        exit(1);
    }
}

static void setup(void)
{
    PGConnectionManagerInitMutexes();
    PGDatabaseManagerInitMutexes();
    PGAppDelegateInitSharedBackgroundQueue();
}

static void teardown(void)
{
    PGConnectionManagerDestroyMutexes();
    PGDatabaseManagerDestroyMutexes();
    PGAppDelegateDestroySharedBackgroundQueue();
}