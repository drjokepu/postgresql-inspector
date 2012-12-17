//
//  ConnectionSheet.m
//  DatabaseInspector
//
//  Created by Tamas Czinege on 23/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PGConnectionsWindow.h"
#import "PGConnectionEntry.h"
#import "PGConnectionController.h"
#import "PGAppDelegate.h"

@interface PGConnectionsWindow ()

@property (nonatomic, strong) NSMutableArray *connectionEntries;
@property (nonatomic, strong) PGConnectionEntry *selectedConnectionEntry;

-(void)loadConnectionEntries;
-(void)loadConnectionEntriesInBackground;
-(void)loadConnectionEntriesOnMainThread:(NSArray*)entries;
-(void)updateSelectedRow;
-(void)updateConnectButton;

-(void)connectTo:(PGConnectionEntry*)connectionEntry;
-(IBAction)didDoubleClickOnConnectionsTableView:(id)sender;

@end

@implementation PGConnectionsWindow
@synthesize connectionsTableView;
@synthesize addRemoveSegmentedControl;
@synthesize spaceButton;
@synthesize hostTextField;
@synthesize portTextField;
@synthesize databaseTextField;
@synthesize usernameTextField;
@synthesize passwordTextField;
@synthesize connectButton;

@synthesize connectionEntries;
@synthesize selectedConnectionEntry;

-(NSString *)windowNibName
{
    return @"PGConnectionsWindow";
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    [connectionsTableView setDoubleAction:@selector(didDoubleClickedOnConnectionsTableView:)];
    
    NSButtonCell* spaceButtonCell = [spaceButton cell];
    [spaceButtonCell setHighlightsBy:NSNoCellMask];
    [spaceButtonCell setShowsStateBy:NSNoCellMask];
    [self loadConnectionEntries];
    
}

-(void)loadConnectionEntries
{
    [self performSelectorInBackground:@selector(loadConnectionEntriesInBackground) withObject:nil];
}

-(void)loadConnectionEntriesInBackground
{
    NSArray *entries = [PGConnectionEntry getConnectionEntries];
    [self performSelectorOnMainThread:@selector(loadConnectionEntriesOnMainThread:)
                           withObject:entries
                        waitUntilDone:NO];
}

-(void)loadConnectionEntriesOnMainThread:(NSArray *)entries
{
    self.connectionEntries = [[NSMutableArray alloc] initWithArray:entries];
    [self.connectionsTableView reloadData];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [connectionEntries count];
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    PGConnectionEntry *entry = [connectionEntries objectAtIndex:row];
    
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:@"cellView" owner:self];
    
    NSTextField *mainTextField = [cellView viewWithTag:6000];
    [entry lock];
    [mainTextField setStringValue:[entry description]];
    [entry unlock];
    
    return cellView;
}

-(void)closeWindow:(id)sender
{
    [self close];
}

-(void)windowWillClose:(NSNotification *)notification
{
    [PGAppDelegate connectionWindowWillClose];
}

-(void)didClickOnAddRemoveSegmentedControl:(id)sender
{
    switch ([addRemoveSegmentedControl selectedSegment])
    {
        case 0:
            [self addConnection:sender];
            break;
        case 1:
            [self removeConnection:sender];
            break;
    }
}

-(void)addConnection:(id)sender
{
    PGConnectionEntry *entry = [[PGConnectionEntry alloc] init];
    [entry lock];
    entry.host = @"";
    entry.database = entry.host;
    entry.username = entry.host;
    entry.port = -1;
    [entry insert];
    [entry unlock];
    
    [connectionEntries addObject:entry];
    [connectionsTableView reloadData];
    
    [connectionsTableView selectRowIndexes:[[NSIndexSet alloc] initWithIndex:[connectionEntries count] - 1]
                      byExtendingSelection:NO];
    [self updateSelectedRow];
    [hostTextField becomeFirstResponder];
}

-(void)removeConnection:(id)sender
{
    if (selectedConnectionEntry == nil) return;
    [connectionEntries removeObject:selectedConnectionEntry];
    [selectedConnectionEntry lock];
    [selectedConnectionEntry delete];
    [selectedConnectionEntry unlock];
    self.selectedConnectionEntry = nil;
    [connectionsTableView reloadData];
    [connectionsTableView selectRowIndexes:[[NSIndexSet alloc] init] byExtendingSelection:NO];
    [self updateSelectedRow];
}

-(void)didChangeConnectionProperty:(id)sender
{
    [selectedConnectionEntry lock];
    selectedConnectionEntry.host = hostTextField.stringValue;
    NSInteger port = portTextField.stringValue.intValue;
    if (port == 0) port = -1;
    selectedConnectionEntry.port = port;
    selectedConnectionEntry.database = databaseTextField.stringValue;
    selectedConnectionEntry.username = usernameTextField.stringValue;
    
    [selectedConnectionEntry update];
    [selectedConnectionEntry unlock];
    
    [connectionsTableView reloadDataForRowIndexes:[connectionsTableView selectedRowIndexes]
                                    columnIndexes:[[NSIndexSet alloc] initWithIndex:0]];
    [self updateConnectButton];
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    [self updateSelectedRow];
}

-(void)updateSelectedRow
{
    NSInteger selectedRow = [connectionsTableView selectedRow];
    if (selectedRow == -1)
    {
        [hostTextField setStringValue:@""];
        [portTextField setStringValue:@""];
        [databaseTextField setStringValue:@""];
        [usernameTextField setStringValue:@""];
        [passwordTextField setStringValue:@""];
        
        [hostTextField setEnabled:NO];
        [portTextField setEnabled:NO];
        [databaseTextField setEnabled:NO];
        [usernameTextField setEnabled:NO];
        [passwordTextField setEnabled:NO];
        [addRemoveSegmentedControl setEnabled:NO forSegment:1];
    }
    else
    {
        self.selectedConnectionEntry = [connectionEntries objectAtIndex:selectedRow];
        [selectedConnectionEntry lock];
        [hostTextField setStringValue:selectedConnectionEntry.host];
        [databaseTextField setStringValue:selectedConnectionEntry.port < 0 ? @"" : [[NSString alloc] initWithFormat:@"%li", selectedConnectionEntry.port]];
        [databaseTextField setStringValue:selectedConnectionEntry.database];
        [usernameTextField setStringValue:selectedConnectionEntry.username];
        [passwordTextField setStringValue:@""];
        [selectedConnectionEntry unlock];
        
        [hostTextField setEnabled:YES];
        [portTextField setEnabled:YES];
        [databaseTextField setEnabled:YES];
        [usernameTextField setEnabled:YES];
        [passwordTextField setEnabled:YES];
        [addRemoveSegmentedControl setEnabled:YES forSegment:1];
    }
    [self updateConnectButton];
}

-(void)didClickOnConnectButton:(id)sender
{
    [self connectTo:selectedConnectionEntry];
}

-(void)connectTo:(PGConnectionEntry *)connectionEntry
{
    PGConnectionController *controller = [[PGConnectionController alloc] init];
    controller.connectionEntry = connectionEntry;
    [controller connectAsync];
    [self close];
}

-(void)updateConnectButton
{
    BOOL canConnect = NO;
    if (selectedConnectionEntry != nil)
    {
        [selectedConnectionEntry lock];
        canConnect = [selectedConnectionEntry.host length] > 0 && [selectedConnectionEntry.database length] > 0;
        [selectedConnectionEntry unlock];
    }
    
    [connectButton setEnabled:canConnect];
}

-(void)didDoubleClickOnConnectionsTableView:(id)sender
{
    NSInteger row = [connectionsTableView clickedRow];
    if (row == -1) return;
    PGConnectionEntry *connectionEntry = [connectionEntries objectAtIndex:row];
    [self connectTo:connectionEntry];
}

@end
