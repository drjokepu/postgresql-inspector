//
//  PGQueryWindowController.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 07/30/2012.
//
//

#import "PGQueryWindowController.h"
#import "PGConnection.h"

static const NSInteger executeQueryTag = 4001;

@interface PGQueryWindowController ()

@property (nonatomic, strong) PGConnection *connection;
@property (nonatomic, assign) BOOL connectionIsOpen;

@end

@implementation PGQueryWindowController
@synthesize connection, connectionIsOpen, initialQueryString, queryTextView;

-(NSString *)windowNibName
{
    return @"PGQueryWindowController";
}

-(void)windowDidLoad
{
    [super windowDidLoad];
    if (self.initialQueryString == nil) self.initialQueryString = @"";
    [queryTextView setString:initialQueryString];
    [queryTextView setFont:[NSFont fontWithName:@"Menlo" size:12]];
}

-(void)dealloc
{
    if (connection != nil) [connection close];
}

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    return [self validateItem:menuItem.tag];
}

-(BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    return [self validateItem:theItem.tag];
}

-(BOOL)validateItem:(NSInteger)tag
{
    switch (tag)
    {
        case executeQueryTag:
            return connectionIsOpen;
        default:
            return YES;
    }
}

-(void)useConnection:(PGConnection *)theConnection
{
    self.connection = theConnection;
    [self performSelectorInBackground:@selector(openConnection:) withObject:theConnection];
}

-(void)openConnection:(PGConnection *)theConnection
{
    [theConnection open];
    [self performSelectorOnMainThread:@selector(didOpenConnection) withObject:nil waitUntilDone:NO];
}

-(void)didOpenConnection
{
    self.connectionIsOpen = YES;
    [[self window] update];
}

-(void)executeQuery:(id)sender
{
    
}

@end
