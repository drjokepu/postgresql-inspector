//
//  PGAuthWindowController.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 29/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PGAuthWindowControllerDelegate.h"

@class PGConnectionEntry;

@interface PGAuthWindowController : NSWindowController

@property (nonatomic, strong) PGConnectionEntry *connectionEntry;
@property (nonatomic, strong) id<PGAuthWindowControllerDelegate> delegate;

@property (weak) IBOutlet NSTextField *labelTextField;
@property (weak) IBOutlet NSTextField *usernameTextField;
@property (weak) IBOutlet NSSecureTextField *passwordTextField;
@property (weak) IBOutlet NSButton *keychainCheckbox;

-(IBAction)didClickOnCancel:(id)sender;
-(IBAction)didClickOnConnect:(id)sender;

@end
