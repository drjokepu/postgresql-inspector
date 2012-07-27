//
//  PGConnectionManager.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 29/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PGConnectionManager.h"
#import <pthread.h>

static pthread_mutex_t *sharedConnectionManagerMutex = NULL;
static PGConnectionManager *sharedConnectionManager = nil;

@interface PGConnectionManager()

@property (nonatomic, strong) NSMutableArray *connectionControllers;

@end

@implementation PGConnectionManager

@synthesize connectionControllers;

-(id)init
{
    if ((self = [super init]))
    {
        self.connectionControllers = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void)addConnectionController:(PGConnectionController *)theController
{
    [connectionControllers addObject:theController];
}

-(void)removeConnectionController:(PGConnectionController *)theController
{
    [connectionControllers removeObject:theController];
}

-(void)removeConnectionController:(PGConnectionController *)theController delayed:(BOOL)delayed
{
    if (delayed)
    {
        [self performSelectorOnMainThread:@selector(removeConnectionController:) withObject:theController waitUntilDone:NO];
    }
    else
    {
        [self removeConnectionController:theController];
    }
}

+(PGConnectionManager *)sharedManager
{
    PGConnectionManager *returnValue = nil;
    
    pthread_mutex_lock(sharedConnectionManagerMutex);
    if (sharedConnectionManager == nil)
    {
        sharedConnectionManager = [[PGConnectionManager alloc] init];
    }
    returnValue = sharedConnectionManager;
    pthread_mutex_unlock(sharedConnectionManagerMutex);
    
    return returnValue;
}

@end

void PGConnectionManagerInitMutexes(void)
{
    sharedConnectionManagerMutex = malloc(sizeof(pthread_mutex_t));
    pthread_mutex_init(sharedConnectionManagerMutex, NULL);
}

void PGConnectionManagerDestroyMutexes(void)
{
    if (sharedConnectionManagerMutex != NULL)
    {
        pthread_mutex_destroy(sharedConnectionManagerMutex);
        free(sharedConnectionManagerMutex);
        sharedConnectionManagerMutex = NULL;
    }
    sharedConnectionManager = nil;
}
