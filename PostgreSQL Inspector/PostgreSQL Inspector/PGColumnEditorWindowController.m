//
//  PGColumnEditorWindowController.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 05/02/2013.
//
//

#import "PGColumnEditorWindowController.h"

@interface PGColumnEditorWindowController ()

@end

@implementation PGColumnEditorWindowController

-(NSString *)windowNibName
{
    return @"PGColumnEditorWindowController";
}

-(void)windowDidLoad
{
    [super windowDidLoad];
    switch (self.columnEditorAction)
    {
        case PGColumnEditorAdd:
            [self.actionButton setTitle:@"Add"];
            break;
        case PGColumnEditorUpdate:
            [self.actionButton setTitle:@"Update"];
    }
    [self validate];
}

-(BOOL)isValid
{
    return ([[self.columnNameTextField stringValue] length] > 0 &&
            [[self.columnTypeComboBox stringValue] length] > 0);
}

-(void)validate
{
    [self.actionButton setEnabled:[self isValid]];
}

-(void)controlTextDidChange:(NSNotification *)obj
{
    [self validate];
}

-(void)didClickCancel:(id)sender
{
    [[NSApplication sharedApplication] endSheet:[self window] returnCode:0];
}

-(void)didClickAction:(id)sender
{
    [[NSApplication sharedApplication] endSheet:[self window] returnCode:1];
}

@end
