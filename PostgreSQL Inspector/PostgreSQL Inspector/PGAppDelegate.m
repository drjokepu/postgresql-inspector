//
//  PGAppDelegate.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 23/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import "PGAppDelegate.h"
#import "PGConnectionsWindow.h"

static NSOperationQueue *sharedBackgroundQueue = nil;
static PGConnectionsWindow *connectionWindow = nil;

@interface PGAppDelegate()

-(void)showConnectionsWindow;

@end

@implementation PGAppDelegate

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self showConnectionsWindow];
}

-(void)connectToDatabase:(id)sender
{
    [self showConnectionsWindow];
}

-(BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    return NO;
}

-(void)showConnectionsWindow
{
    if (connectionWindow == nil)
    {
        connectionWindow = [[PGConnectionsWindow alloc] init];
        [connectionWindow showWindow:self];
    }
    [[connectionWindow window] makeKeyWindow];
}

+(void)connectionWindowWillClose
{
    connectionWindow = nil;
}

+(NSOperationQueue *)sharedBackgroundQueue
{
    return sharedBackgroundQueue;
}

@end

void PGAppDelegateInitSharedBackgroundQueue(void)
{
    sharedBackgroundQueue = [[NSOperationQueue alloc] init];
    [sharedBackgroundQueue setName:@"Shared Background Queue"];
}

void PGAppDelegateDestroySharedBackgroundQueue(void)
{
    sharedBackgroundQueue = nil;
}