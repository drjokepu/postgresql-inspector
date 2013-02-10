//
//  PGColumnEditorWindowController.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 05/02/2013.
//
//

#import "PGColumnEditorWindowController.h"
#import "PGDatabase.h"
#import "PGRelationColumn.h"

@interface PGColumnEditorWindowController ()
@property (nonatomic, strong) PGRelationColumn *initialColumn;
@end

@implementation PGColumnEditorWindowController
@synthesize initialColumn, columnNameTextField, columnTypeComboBox, columnLengthTextField, columnPrecisionTextField, columnDefaultValueTextField, columnNotNullCheckBox, columnEditorAction, actionButton;

-(NSString *)windowNibName
{
    return @"PGColumnEditorWindowController";
}

-(void)windowDidLoad
{
    [super windowDidLoad];
    switch (columnEditorAction)
    {
        case PGEditorAdd:
            [actionButton setTitle:@"Add"];
            break;
        case PGEditorUpdate:
            [actionButton setTitle:@"Update"];
    }
    [columnTypeComboBox addItemsWithObjectValues:[PGDatabase commonTypes]];
    [self loadInitialColumnData];
    [self validate];
}

-(void)loadInitialColumnData
{
    if (initialColumn != nil)
    {
        [columnNameTextField setStringValue:initialColumn.name];
        [columnTypeComboBox setStringValue:initialColumn.typeName];
        if (initialColumn.length > 0) [columnLengthTextField setIntegerValue:initialColumn.length];
        if (initialColumn.defaultValue != nil) [columnDefaultValueTextField setStringValue:initialColumn.defaultValue];
        [columnNotNullCheckBox setState:initialColumn.notNull ? NSOnState : NSOffState];
    }
}

-(BOOL)isValid
{
    return ([[columnNameTextField stringValue] length] > 0 &&
            [[columnTypeComboBox stringValue] length] > 0);
}

-(void)validate
{
    [actionButton setEnabled:[self isValid]];
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

-(void)useColumn:(PGRelationColumn *)column
{
    self.initialColumn = column;
}

-(PGRelationColumn *)getColumn
{
    PGRelationColumn *column = [[PGRelationColumn alloc] init];
    column.name = [columnNameTextField stringValue];
    column.typeName = [columnTypeComboBox stringValue];
    if ([[columnTypeComboBox stringValue] length] > 0)
        column.length = [columnTypeComboBox integerValue];
    column.defaultValue = [[columnDefaultValueTextField stringValue] length] > 0 ? [columnDefaultValueTextField stringValue] : nil;
    column.notNull = [columnNotNullCheckBox state] == NSOnState;
    
    return column;
}

@end
