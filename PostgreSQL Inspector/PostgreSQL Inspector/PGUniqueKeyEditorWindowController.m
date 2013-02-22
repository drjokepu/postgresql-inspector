//
//  PGUniqueKeyEditorWindowController.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 10/02/2013.
//
//

#import "PGUniqueKeyEditorWindowController.h"
#import "NSImage+PGImage.h"
#import "NSMutableArray+PGMutableArray.h"
#import "PGConstraint.h"
#import "PGConstraintColumn.h"
#import "PGRelationColumn.h"
#import "Utils.h"

@interface PGUniqueKeyEditorWindowController ()

@property (strong) NSMutableArray *keyColumns;
@property (strong) IBOutlet NSTextField *constraintNameTextField;
@property (strong) IBOutlet NSTableView *tableColumnsTableView;
@property (strong) IBOutlet NSTableView *keyColumnsTableView;
@property (strong) IBOutlet NSButton *tableColumnsSpaceButton;
@property (strong) IBOutlet NSPopUpButton *keyColumnActionsButton;
@property (strong) IBOutlet NSButton *keyColumnsSpaceButton;
@property (strong) NSMenuItem *keyColumnMoveUpMenuItem;
@property (strong) NSMenuItem *keyColumnMoveDownMenuItem;
@property (strong) IBOutlet NSButton *actionButton;
@property (strong) PGConstraint *initialConstraint;

@end

@implementation PGUniqueKeyEditorWindowController
@synthesize isPrimaryKey, availableColumns, keyColumns, initialConstraint, columnEditorAction;

-(NSString *)windowNibName
{
    return @"PGUniqueKeyEditorWindowController";
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    switch (columnEditorAction)
    {
        case PGEditorAdd:
            [self.actionButton setTitle:@"Add"];
            break;
        case PGEditorUpdate:
            [self.actionButton setTitle:@"Update"];
    }
    
    self.keyColumns = [[NSMutableArray alloc] init];
    
    [[self.tableColumnsSpaceButton cell] setHighlightsBy:NSNoCellMask];
    [[self.tableColumnsSpaceButton cell] setShowsStateBy:NSNoCellMask];
    [[self.keyColumnsSpaceButton cell] setHighlightsBy:NSNoCellMask];
    [[self.keyColumnsSpaceButton cell] setShowsStateBy:NSNoCellMask];
    
    NSButtonCell *checkBoxCell = [[NSButtonCell alloc] init];
    [checkBoxCell setButtonType:NSSwitchButton];
    [checkBoxCell setImagePosition:NSImageOnly];
    [((NSTableColumn*)[self.tableColumnsTableView tableColumns][0]) setDataCell:checkBoxCell];
    
    [self.keyColumnActionsButton addItemWithTitle:@""];
    [[self.keyColumnActionsButton itemAtIndex:0] setImage:[[NSImage imageNamed:NSImageNameActionTemplate] imageScaledToSize:NSMakeSize(10, 10) proportionally:YES]];
    [[self.keyColumnActionsButton itemAtIndex:0] setOnStateImage:nil];
    [[self.keyColumnActionsButton itemAtIndex:0] setMixedStateImage:nil];
    
    // Move Up (column)
    self.keyColumnMoveUpMenuItem = [[NSMenuItem alloc] initWithTitle:@"Move Up" action:@selector(didClickColumnMoveUp:) keyEquivalent:@""];
    [[self.keyColumnActionsButton menu] addItem:self.keyColumnMoveUpMenuItem];
    // Move Down (column)
    self.keyColumnMoveDownMenuItem = [[NSMenuItem alloc] initWithTitle:@"Move Down" action:@selector(didClickColumnMoveDown:) keyEquivalent:@""];
    [[self.keyColumnActionsButton menu] addItem:self.keyColumnMoveDownMenuItem];
    
    [self loadInitialConstraintData];
    
    [self validateActionButton];
    [self validateKeyColumnActions];
}

-(void)loadInitialConstraintData
{
    if (initialConstraint != nil)
    {
        [self.constraintNameTextField setStringValue:initialConstraint.name];
        for (PGConstraintColumn *constraintColumn in initialConstraint.columns)
        {
            if (constraintColumn.columnNumber < 0)
            {
                for (PGRelationColumn *relationColumn in self.availableColumns)
                {
                    if ([relationColumn.name isEqualToString:constraintColumn.columnName])
                    {
                        [keyColumns addObject:relationColumn];
                        break;
                    }
                }
            }
        }
    }
}

-(void)didClickCancel:(id)sender
{
    [[NSApplication sharedApplication] endSheet:[self window] returnCode:0];
}

-(void)didClickAction:(id)sender
{
    [[NSApplication sharedApplication] endSheet:[self window] returnCode:1];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == self.tableColumnsTableView)
    {
        return [availableColumns count];
    }
    else if (tableView == self.keyColumnsTableView)
    {
        return [keyColumns count];
    }
    else
    {
        return 0;
    }
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (tableView == self.tableColumnsTableView)
    {
        return [self tableColumnsTableViewObjectValueForTableColumn:[tableColumn identifier] index:row];
    }
    else if (tableView == self.keyColumnsTableView)
    {
        return ((PGRelationColumn*)keyColumns[row]).name;
    }
    else
    {
        return @"";
    }
}

-(id)tableColumnsTableViewObjectValueForTableColumn:(NSString*)identifier index:(NSUInteger)index
{
    const PGRelationColumn *column = availableColumns[index];
    if ([identifier isEqualToString:@"columnSelected"])
    {
        return @([keyColumns indexOfObject:column] != NSNotFound);
    }
    else if ([identifier isEqualToString:@"columnName"])
    {
        return column.name;
    }
    else
    {
        return @"";
    }
}

-(void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (tableView == self.tableColumnsTableView)
    {
        if ([tableColumn.identifier isEqualToString:@"columnSelected"])
        {
            const PGRelationColumn *column = availableColumns[row];
            [keyColumns removeObject:column];
            if ([object boolValue])
                [keyColumns addObject:column];
            [self.keyColumnsTableView reloadData];
            [self validateActionButton];
        }
    }
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if ([notification object] == self.keyColumnsTableView)
    {
        [self validateKeyColumnActions];
    }
}

-(void)validateActionButton
{
    [self.actionButton setEnabled:[keyColumns count] > 0];
}

-(void)validateKeyColumnActions
{
    const NSInteger selectedRow = [self.keyColumnsTableView selectedRow];
    [self.keyColumnActionsButton setEnabled:selectedRow != -1];
    [self.keyColumnMoveUpMenuItem setEnabled:isNotFirstItem(selectedRow)];
    [self.keyColumnMoveDownMenuItem setEnabled:isNotLastItem(selectedRow, [self.keyColumns count])];
}


-(void)didClickColumnMoveUp:(id)sender
{
    const NSInteger selectedRow = [self.keyColumnsTableView selectedRow];
    if (isNotFirstItem(selectedRow))
    {
        [self.keyColumns swapObjectAtIndex:selectedRow withObjectAtIndex:selectedRow - 1];
        [self.keyColumnsTableView reloadData];
        [self.keyColumnsTableView selectRowIndexes:[[NSIndexSet alloc] initWithIndex:selectedRow - 1] byExtendingSelection:NO];
    }
}

-(void)didClickColumnMoveDown:(id)sender
{
    const NSInteger selectedRow = [self.keyColumnsTableView selectedRow];
    if (isNotLastItem(selectedRow, [self.keyColumns count]))
    {
        [self.keyColumns swapObjectAtIndex:selectedRow withObjectAtIndex:selectedRow + 1];
        [self.keyColumnsTableView reloadData];
        [self.keyColumnsTableView selectRowIndexes:[[NSIndexSet alloc] initWithIndex:selectedRow + 1] byExtendingSelection:NO];
    }
}

-(PGConstraint *)getConstraint
{
    PGConstraint *constraint = [[PGConstraint alloc] init];
    constraint.type = isPrimaryKey ? PGConstraintTypePrimaryKey : PGConstraintTypeUniqueKey;
    constraint.name = [self.constraintNameTextField stringValue];
    
    NSMutableArray *constraintColumns = [[NSMutableArray alloc] initWithCapacity:[keyColumns count]];
    for (PGRelationColumn *keyColumn in keyColumns)
    {
        PGConstraintColumn *constraintColumn = [[PGConstraintColumn alloc] init];
        constraintColumn.columnNumber = -1;
        constraintColumn.columnName = keyColumn.name;
        [constraintColumns addObject:constraintColumn];
    }
    constraint.columns = constraintColumns;
    
    return constraint;
}

-(void)useConstraint:(PGConstraint *)constraint
{
    self.initialConstraint = constraint;
}

@end
