//
//  PGColumnEditorWindowController.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 05/02/2013.
//
//

#import "PGColumnEditorWindowController.h"
#import "PGRelationColumn.h"

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

-(PGRelationColumn *)getColumn
{
    PGRelationColumn *column = [[PGRelationColumn alloc] init];
    column.name = [self.columnNameTextField stringValue];
    column.typeName = [self.columnTypeComboBox stringValue];
    if ([[self.columnTypeComboBox stringValue] length] > 0)
        column.length = [self.columnTypeComboBox integerValue];
    column.defaultValue = [[self.columnDefaultValueTextField stringValue] length] > 0 ? [self.columnDefaultValueTextField stringValue] : nil;
    column.notNull = [self.columnNotNullCheckBox state] == NSOnState;
    
    return column;
}

@end
