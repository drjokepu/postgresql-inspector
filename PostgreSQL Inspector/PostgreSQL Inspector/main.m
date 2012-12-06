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
        int result = NSApplicationMain(argc, (const char **)argv);
        teardown();
        return result;
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
#ifdef DEBUG
    else
    {
        printf("libpq %i\n", pqLibVersion);
    }
#endif /* DEBUg */
}

void setup(void)
{
    PGConnectionManagerInitMutexes();
    PGDatabaseManagerInitMutexes();
//    PGCommandInitOperationQueue();
    PGAppDelegateInitSharedBackgroundQueue();
}

static void teardown(void)
{
    PGConnectionManagerDestroyMutexes();
    PGDatabaseManagerDestroyMutexes();
//    PGCommandDestroyOperationQueue();
    PGAppDelegateDestroySharedBackgroundQueue();
}