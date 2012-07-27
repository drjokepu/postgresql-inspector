//
//  PGAuthWindowController.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 29/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import "PGAuthWindowController.h"
#import "PGConnectionEntry.h"

@interface PGAuthWindowController ()

@end

@implementation PGAuthWindowController
@synthesize connectionEntry;
@synthesize delegate;
@synthesize labelTextField;
@synthesize usernameTextField;
@synthesize passwordTextField;
@synthesize keychainCheckbox;

-(NSString *)windowNibName
{
    return @"PGAuthWindowController";
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    labelTextField.stringValue = [[NSString alloc] initWithFormat:@"Enter your username and password for the server \"%@\".", connectionEntry.host];
    usernameTextField.stringValue = [[NSString alloc] initWithString:connectionEntry.username];
    passwordTextField.stringValue = @"";
    
    [passwordTextField becomeFirstResponder];
}

-(void)didClickOnCancel:(id)sender
{
    [self close];
    if (delegate != nil) [delegate authWindowControllerCancel:sender];
}

-(void)didClickOnConnect:(id)sender
{
    connectionEntry.username = usernameTextField.stringValue;
    connectionEntry.password = passwordTextField.stringValue;
    connectionEntry.userAskedForStroingPasswordInKeychain = keychainCheckbox.state == NSOnState;
    
    [[self window] orderOut:self];
    if (delegate != nil) [delegate authWindowControllerConnect:sender];
    [self close];
}

@end
