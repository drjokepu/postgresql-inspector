//
//  PGDatabaseManager.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 30/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PGDatabaseManager.h"
#import <pthread.h>

static pthread_mutex_t *sharedDatabaseManagerMutex = NULL;
static PGDatabaseManager *sharedDatabaseManager = nil;

@interface PGDatabaseManager()
{
    NSMutableArray *controllers;
}

@end

@implementation PGDatabaseManager

-(id)init
{
    if ((self = [super init]))
    {
        controllers = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)addDatabaseWindowController:(PGDatabaseWindowController *)controller
{
    [controllers addObject:controller];
}

-(void)removeDatabaseWindowController:(PGDatabaseWindowController *)controller
{
    [controllers removeObject:controller];
}

-(void)removeDatabaseWindowController:(PGDatabaseWindowController *)controller delayed:(BOOL)delayed
{
    if (delayed)
    {
        [self performSelectorOnMainThread:@selector(removeDatabaseWindowController:) withObject:controller waitUntilDone:NO];
    }
    else
    {
        [self removeDatabaseWindowController:controller];
    }
}

+(PGDatabaseManager *)sharedManager
{
    PGDatabaseManager *returnValue = nil;
    
    pthread_mutex_lock(sharedDatabaseManagerMutex);
    if (sharedDatabaseManager == nil)
    {
        sharedDatabaseManager = [[PGDatabaseManager alloc] init];
    }
    returnValue = sharedDatabaseManager;
    pthread_mutex_unlock(sharedDatabaseManagerMutex);
    
    return returnValue;
}

@end

void PGDatabaseManagerInitMutexes(void)
{
    sharedDatabaseManagerMutex = malloc(sizeof(pthread_mutex_t));
    pthread_mutex_init(sharedDatabaseManagerMutex, NULL);
}

void PGDatabaseManagerDestroyMutexes(void)
{
    if (sharedDatabaseManagerMutex != NULL)
    {
        pthread_mutex_destroy(sharedDatabaseManagerMutex);
        free(sharedDatabaseManagerMutex);
        sharedDatabaseManagerMutex = NULL;
    }
    sharedDatabaseManager = nil;
}