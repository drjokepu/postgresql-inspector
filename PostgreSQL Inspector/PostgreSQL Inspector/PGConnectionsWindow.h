//
//  ConnectionSheet.h
//  DatabaseInspector
//
//  Created by Tamas Czinege on 23/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PGConnectionsWindow : NSWindowController <NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSTableView *connectionsTableView;
@property (weak) IBOutlet NSSegmentedControl *addRemoveSegmentedControl;
@property (weak) IBOutlet NSButton *spaceButton;
@property (weak) IBOutlet NSTextField *hostTextField;
@property (weak) IBOutlet NSTextField *portTextField;
@property (weak) IBOutlet NSTextField *databaseTextField;
@property (weak) IBOutlet NSTextField *usernameTextField;
@property (weak) IBOutlet NSSecureTextField *passwordTextField;
@property (weak) IBOutlet NSButton *connectButton;

-(IBAction)closeWindow:(id)sender;
-(IBAction)didClickOnAddRemoveSegmentedControl:(id)sender;
-(IBAction)addConnection:(id)sender;
-(IBAction)removeConnection:(id)sender;
-(IBAction)didChangeConnectionProperty:(id)sender;
-(IBAction)didClickOnConnectButton:(id)sender;

@end
