//
//  PGCreateTableWindowController.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 04/02/2013.
//
//

#import "PGCreateTableWindowController.h"
#import "NSMutableArray+PGMutableArray.h"
#import "PGColumnEditorWindowController.h"
#import "PGConnection.h"
#import "PGConstraint.h"
#import "PGRelationColumn.h"

static inline BOOL isNotFirstItem(const NSInteger selectedRow);
static inline BOOL isNotLastItem(const NSInteger selectedRow, const NSInteger rowCount);

@interface PGCreateTableWindowController ()
@property (nonatomic, strong) PGConnection *connection;
@property (nonatomic, assign) BOOL connectionIsOpen;
@property (nonatomic, strong) NSMutableArray *tableColumns;
@property (nonatomic, strong) NSMutableArray *tableConstraints;
@property (nonatomic, strong) PGColumnEditorWindowController *columnEditorSheet;
@end

@implementation PGCreateTableWindowController

-(NSString *)windowNibName
{
    return @"PGCreateTableWindowController";
}

-(void)windowDidLoad
{
    [super windowDidLoad];
    self.tableColumns = [[NSMutableArray alloc] init];
    self.tableConstraints = [[NSMutableArray alloc] init];
    
    if (self.initialSchemaName != nil)
    {
        if (self.initialSchemaNameList != nil)
            [self.schemaComboBox addItemsWithObjectValues:self.initialSchemaNameList];
        
        if (self.initialSchemaName != nil)
            [self.schemaComboBox setStringValue:self.initialSchemaName];
    }
    
    NSButtonCell* spaceButtonCell = [self.columnSpaceButton cell];
    [spaceButtonCell setHighlightsBy:NSNoCellMask];
    [spaceButtonCell setShowsStateBy:NSNoCellMask];
//    [self.columnActionsPopUpButton setButtonType
    [[self.columnActionsPopUpButton cell] setArrowPosition:NSPopUpArrowAtBottom];
    
    [self validateColumnActions];
    [self validateConstraintActions];
}

-(void)didClickCancel:(id)sender
{
    [self close];
}

-(void)useConnection:(PGConnection *)theConnection
{
    self.connection = theConnection;
    self.connection.delegate = self;
    [self performSelectorInBackground:@selector(openConnection:) withObject:theConnection];
}

-(void)openConnection:(PGConnection *)theConnection
{
    [theConnection openAsync];
}

-(void)connectionSuccessful:(PGConnection *)theConnection
{
    self.connectionIsOpen = YES;
    [[self window] update];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == self.columnsTableView)
    {
        return [self.tableColumns count];
    }
    else
    {
        return 0;
    }
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (tableView == self.columnsTableView)
    {
        return [self viewForColumnAtIndex:row];
    }
    else
    {
        return nil;
    }
}

-(NSView*)viewForColumnAtIndex:(NSInteger)columnIndex
{
    @autoreleasepool
    {
        PGRelationColumn *column = self.tableColumns[columnIndex];
        NSTableCellView *cellView = [self.columnsTableView makeViewWithIdentifier:@"createTableColumnCellView" owner:self];
        
        [[cellView viewWithTag:7500] setStringValue:column.name];
        
        NSMutableArray *typeInfoList = [[NSMutableArray alloc] init];
        [typeInfoList addObject:[column fullType]];
        if (column.notNull)
            [typeInfoList addObject:@"not null"];
        [[cellView viewWithTag:7501] setStringValue:[typeInfoList componentsJoinedByString:@", "]];
        if (column.defaultValue != [NSNull null])
            [typeInfoList addObject:[[NSString alloc] initWithFormat:@"default: %@", column.defaultValue]];
        
        return cellView;
    }
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if ([notification object] == self.columnsTableView)
    {
        [self validateColumnActions];
    }
    else if ([notification object] == self.constraintsTableView)
    {
        [self validateConstraintActions];
    }
}

-(void)validateColumnActions
{
    const NSInteger selectedRow = [self.columnsTableView selectedRow];
    [self setColumnManipulationButtonsEnabled:selectedRow != -1];
    [self.columnMoveUpMenuItem setEnabled:isNotFirstItem(selectedRow)];
    [self.columnMoveDownMenuItem setEnabled:isNotLastItem(selectedRow, [self.tableColumns count])];
}

-(void)setColumnManipulationButtonsEnabled:(BOOL)enabled
{
    [self.removeColumnButton setEnabled:enabled];
    [self.columnActionsPopUpButton setEnabled:enabled];
}

-(void)didClickAddColumn:(id)sender
{
    [self openAddColumnSheet];
}

-(void)openAddColumnSheet
{
    PGColumnEditorWindowController *columnEditorSheet = [[PGColumnEditorWindowController alloc] init];
    columnEditorSheet.columnEditorAction = PGEditorAdd;
    [[NSApplication sharedApplication] beginSheet:[columnEditorSheet window]
                                   modalForWindow:[self window]
                                    modalDelegate:self
                                   didEndSelector:@selector(didEndAddColumnSheet:returnCode:contextInfo:)
                                      contextInfo:NULL];
    
    self.columnEditorSheet = columnEditorSheet;
}

-(void)didEndAddColumnSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == 1)
    {
        [self.tableColumns addObject:[self.columnEditorSheet getColumn]];
        [self.columnsTableView reloadData];
    }
    
    [sheet orderOut:self];
    self.columnEditorSheet = nil;
}

-(void)didClickRemoveColumn:(id)sender
{
    const NSInteger columnIndex = [self.columnsTableView selectedRow];
    if (columnIndex != -1)
    {
        [self.tableColumns removeObjectAtIndex:columnIndex];
        [self.columnsTableView reloadData];
    }
}

-(void)didClickEditColumn:(id)sender
{
    const NSInteger columnIndex = [self.columnsTableView selectedRow];
    if (columnIndex != -1)
    {
        [self openEditColumnSheet:self.tableColumns[columnIndex]];
    }
}

-(void)openEditColumnSheet:(PGRelationColumn*)column
{
    PGColumnEditorWindowController *columnEditorSheet = [[PGColumnEditorWindowController alloc] init];
    columnEditorSheet.columnEditorAction = PGEditorUpdate;
    [columnEditorSheet useColumn:column];
    [[NSApplication sharedApplication] beginSheet:[columnEditorSheet window]
                                   modalForWindow:[self window]
                                    modalDelegate:self
                                   didEndSelector:@selector(didEndEditColumnSheet:returnCode:contextInfo:)
                                      contextInfo:NULL];
    
    self.columnEditorSheet = columnEditorSheet;
}

-(void)didEndEditColumnSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == 1)
    {
        const NSInteger columnIndex = [self.columnsTableView selectedRow];
        if (columnIndex != -1)
        {
            self.tableColumns[columnIndex] = [self.columnEditorSheet getColumn];
            [self.columnsTableView reloadData];
        }
    }
    
    [sheet orderOut:self];
    self.columnEditorSheet = nil;
}

-(void)didClickColumnMoveUp:(id)sender
{
    const NSInteger selectedRow = [self.columnsTableView selectedRow];
    if (isNotFirstItem(selectedRow))
    {
        [self.tableColumns swapObjectAtIndex:selectedRow withObjectAtIndex:selectedRow - 1];
        [self.columnsTableView reloadData];
        [self.columnsTableView selectRowIndexes:[[NSIndexSet alloc] initWithIndex:selectedRow - 1] byExtendingSelection:NO];
    }
}

-(void)didClickColumnMoveDown:(id)sender
{
    const NSInteger selectedRow = [self.columnsTableView selectedRow];
    if (isNotLastItem(selectedRow, [self.tableColumns count]))
    {
        [self.tableColumns swapObjectAtIndex:selectedRow withObjectAtIndex:selectedRow + 1];
        [self.columnsTableView reloadData];
        [self.columnsTableView selectRowIndexes:[[NSIndexSet alloc] initWithIndex:selectedRow + 1] byExtendingSelection:NO];
    }
}

-(BOOL)hasPrimaryKey
{
    for (PGConstraint *constraint in self.tableConstraints)
    {
        if (constraint.type == PGConstraintTypePrimaryKey)
            return YES;
    }
    return NO;
}

-(void)validateConstraintActions
{
    [self.addPrimaryKeyMenuItem setEnabled:![self hasPrimaryKey]];
}

@end

static inline BOOL isNotFirstItem(const NSInteger selectedRow)
{
    return selectedRow > 0;
}

static inline BOOL isNotLastItem(const NSInteger selectedRow, const NSInteger rowCount)
{
    return (selectedRow >= 0) && ((selectedRow + 1) < rowCount);
}
