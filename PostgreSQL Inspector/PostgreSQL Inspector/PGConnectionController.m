//
//  PGConnectionController.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 25/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import <unistd.h>
#import "PGConnectionController.h"
#import "PGConnection.h"
#import "PGConnectionEntry.h"
#import "PGDatabase.h"
#import "PGConnectionProgressWindow.h"
#import "PGAuthWindowController.h"
#import "PGDatabaseWindowController.h"
#import "PGConnectionManager.h"
#import "PGDatabaseManager.h"

@interface PGConnectionController()

@property (nonatomic, strong) PGConnectionProgressWindow *progressWindow;
@property (nonatomic, strong) PGAuthWindowController *authWindow;

-(void)connectAsyncBackground;
-(void)showConnectionProgressWindow;
-(void)showConnectionProgressWindowMainThread;
-(void)closeConnectionProgressWindow;
-(void)closeConnectionProgressWindowMainThread;
-(void)releaseAuthWindow;

@end

@implementation PGConnectionController

@synthesize connection;
@synthesize connectionEntry;
@synthesize progressWindow;
@synthesize authWindow;

-(id)initWithConnectionEntry:(PGConnectionEntry *)theConnectionEntry
{
    if ((self = [super init]))
    {
        self.connectionEntry = theConnectionEntry;
    }
    return self;
}

-(void)connectAsync
{
    [[PGConnectionManager sharedManager] addConnectionController:self];
    [self performSelectorInBackground:@selector(connectAsyncBackground) withObject:nil];
}

-(void)reconnectAsync
{
    [self performSelectorInBackground:@selector(connectAsyncBackground) withObject:nil];
}

-(void)connectAsyncBackground
{
    [self showConnectionProgressWindow];
    
    self.connection = [[PGConnection alloc] initWithConnectionEntry:connectionEntry];
    connection.delegate = self;
    [connection connect];
}

-(void)connectionSuccessful:(PGConnection *)theConnection
{
    [self closeConnectionProgressWindowMainThread];
    
    PGDatabaseWindowController *databaseWindow = [[PGDatabaseWindowController alloc] init];
    databaseWindow.connection = theConnection;
    databaseWindow.database = [[PGDatabase alloc] initWithConnectionEntry:connectionEntry];
    databaseWindow.database.delegate = databaseWindow;
    [[PGDatabaseManager sharedManager] addDatabaseWindowController:databaseWindow];
    [[databaseWindow window] makeKeyAndOrderFront:self];
    
    self.connection = nil;
    [[PGConnectionManager sharedManager] removeConnectionController:self delayed:YES];
}

-(void)connectionNeedsPassword:(PGConnection *)theConnection
{
    [self closeConnectionProgressWindowMainThread];
    
    self.authWindow = [[PGAuthWindowController alloc] init];
    authWindow.connectionEntry = connectionEntry;
    authWindow.delegate = self;
    [[authWindow window] makeKeyAndOrderFront:self];
}

-(void)connectionFailed:(PGConnection *)theConnection message:(NSString *)theMessage
{
    [self closeConnectionProgressWindowMainThread];
    [connection finish];
    self.connection = nil;
    
    NSAlert *alert = [NSAlert alertWithMessageText:@"Connection Failed"
                                     defaultButton:nil
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@"%@", theMessage, nil];
    [alert runModal];
    alert = nil;
    
    [[PGConnectionManager sharedManager] removeConnectionController:self delayed:YES];
}

-(void)connectionFailed:(PGConnection *)theConnection
{
    [[PGConnectionManager sharedManager] removeConnectionController:self delayed:YES];
}

-(void)showConnectionProgressWindow
{
    [self performSelectorOnMainThread:@selector(showConnectionProgressWindowMainThread) withObject:nil waitUntilDone:YES];
}

-(void)showConnectionProgressWindowMainThread
{
    self.progressWindow = [[PGConnectionProgressWindow alloc] init];
    progressWindow.connectionEntry = connectionEntry;
    [[progressWindow window] makeKeyAndOrderFront:self];
}

-(void)closeConnectionProgressWindow
{
    [self performSelectorOnMainThread:@selector(closeConnectionProgressWindowMainThread) withObject:nil waitUntilDone:YES];
}

-(void)closeConnectionProgressWindowMainThread
{
    [progressWindow close];
    self.progressWindow = nil;
}

-(void)authWindowControllerCancel:(PGAuthWindowController *)theAuthWindowController
{
    [connection finish];
    self.connection = nil;
    [self performSelectorOnMainThread:@selector(releaseAuthWindow) withObject:nil waitUntilDone:NO];
    [[PGConnectionManager sharedManager] removeConnectionController:self delayed:YES];
}

-(void)authWindowControllerConnect:(PGAuthWindowController *)theAuthWindowController
{
    [connection finish];
    self.connection = nil;
    [self reconnectAsync];
    [self performSelectorOnMainThread:@selector(releaseAuthWindow) withObject:nil waitUntilDone:NO];
}

-(void)releaseAuthWindow
{
    self.authWindow = nil;
}

@end
