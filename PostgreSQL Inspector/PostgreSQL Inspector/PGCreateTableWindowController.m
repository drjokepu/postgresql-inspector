//
//  PGCreateTableWindowController.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 04/02/2013.
//
//

#import "PGCreateTableWindowController.h"
#import "NSImage+PGImage.h"
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

@property (nonatomic, strong) NSButton *addColumnButton;
@property (nonatomic, strong) NSButton *removeColumnButton;
@property (nonatomic, strong) NSPopUpButton *columnActionsButton;
@property (nonatomic, strong) NSButton *columnSpaceButton;
@property (nonatomic, strong) NSMenuItem *columnEditColumnMenuItem;
@property (nonatomic, strong) NSMenuItem *columnMoveUpMenuItem;
@property (nonatomic, strong) NSMenuItem *columnMoveDownMenuItem;

@property (nonatomic, strong) NSPopUpButton *addConstraintButton;
@property (nonatomic, strong) NSMenuItem *addPrimaryKeyMenuItem;

@end

@implementation PGCreateTableWindowController
@synthesize columnsView;
@synthesize addColumnButton;
@synthesize removeColumnButton;
@synthesize columnActionsButton;
@synthesize columnSpaceButton;
@synthesize columnMoveUpMenuItem;
@synthesize columnMoveDownMenuItem;
@synthesize constraintsView;
@synthesize addConstraintButton;
@synthesize addPrimaryKeyMenuItem;

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
    
    [self createButtons];

    
    [self validateColumnActions];
    [self validateConstraintActions];
}

-(void)createButtons
{
    const CGFloat buttonHeight = 23;
    const CGFloat normalButtonWidth = 26;
    const CGFloat wideButtonWidth = 32;
    const CGFloat baseX = 17;
    const CGFloat baseY = 8;
    
    // Column Buttons
    // Add Column
    self.addColumnButton = [[NSButton alloc] initWithFrame:NSMakeRect(baseX, baseY, normalButtonWidth, buttonHeight)];
    [addColumnButton setAction:@selector(didClickAddColumn:)];
    [addColumnButton setTitle:@""];
    [addColumnButton setBezelStyle:NSSmallSquareBezelStyle];
    [addColumnButton setImage:[NSImage imageNamed:NSImageNameAddTemplate]];
    [columnsView addSubview:addColumnButton positioned:NSWindowAbove relativeTo:columnsView];
    
    // Remove Column
    self.removeColumnButton = [[NSButton alloc] initWithFrame:NSMakeRect(baseX + normalButtonWidth - 1, baseY, normalButtonWidth, buttonHeight)];
    [removeColumnButton setAction:@selector(didClickRemoveColumn:)];
    [removeColumnButton setTitle:@""];
    [removeColumnButton setBezelStyle:NSSmallSquareBezelStyle];
    [removeColumnButton setImage:[NSImage imageNamed:NSImageNameRemoveTemplate]];
    [columnsView addSubview:removeColumnButton positioned:NSWindowAbove relativeTo:columnsView];
    
    // Column Actions
    self.columnActionsButton = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(baseX + ((normalButtonWidth - 1) * 2), baseY, wideButtonWidth, buttonHeight) pullsDown:YES];
    [columnActionsButton setBezelStyle:NSSmallSquareBezelStyle];
    [columnActionsButton setImagePosition:NSImageOnly];
    [[columnActionsButton cell] setArrowPosition:NSPopUpArrowAtBottom];
    [columnActionsButton addItemWithTitle:@""];
    [[columnActionsButton itemAtIndex:0] setImage:[[NSImage imageNamed:NSImageNameActionTemplate] imageScaledToSize:NSMakeSize(10, 10) proportionally:YES]];
    [[columnActionsButton itemAtIndex:0] setOnStateImage:nil];
    [[columnActionsButton itemAtIndex:0] setMixedStateImage:nil];
    // Edit Column
    self.columnEditColumnMenuItem = [[NSMenuItem alloc] initWithTitle:@"Edit Column…" action:@selector(didClickEditColumn:) keyEquivalent:@""];
    [[columnActionsButton menu] addItem:self.columnEditColumnMenuItem];
    [[columnActionsButton menu] addItem:[NSMenuItem separatorItem]];
    // Move Up (column)
    self.columnMoveUpMenuItem = [[NSMenuItem alloc] initWithTitle:@"Move Up" action:@selector(didClickColumnMoveUp:) keyEquivalent:@""];
    [[columnActionsButton menu] addItem:columnMoveUpMenuItem];
    // Move Down (column)
    self.columnMoveDownMenuItem = [[NSMenuItem alloc] initWithTitle:@"Move Down" action:@selector(didClickColumnMoveDown:) keyEquivalent:@""];
    [[columnActionsButton menu] addItem:columnMoveDownMenuItem];
    [columnsView addSubview:columnActionsButton positioned:NSWindowAbove relativeTo:columnsView];

    // Space Button (column)
    const CGFloat columnSpaceButtonX = baseX + ((normalButtonWidth - 1) * 2) + wideButtonWidth - 1;
    self.columnSpaceButton = [[NSButton alloc] initWithFrame:NSMakeRect(columnSpaceButtonX, baseY, [self.columnsTableView frame].size.width + baseX - columnSpaceButtonX + 2, buttonHeight)];
    [[columnSpaceButton cell] setHighlightsBy:NSNoCellMask];
    [[columnSpaceButton cell] setShowsStateBy:NSNoCellMask];
    [columnSpaceButton setTitle:@""];
    [columnSpaceButton setBezelStyle:NSSmallSquareBezelStyle];
    [columnSpaceButton setAutoresizingMask:NSViewWidthSizable];
    [columnsView addSubview:columnSpaceButton positioned:NSWindowAbove relativeTo:columnsView];
    
    // Constraint Buttons
    // Add Constraint
    self.addConstraintButton = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(baseX, baseY, wideButtonWidth, buttonHeight) pullsDown:YES];
    [addConstraintButton setBezelStyle:NSSmallSquareBezelStyle];
    [addConstraintButton setImagePosition:NSImageOnly];
    [[addConstraintButton cell] setArrowPosition:NSPopUpArrowAtBottom];
    [addConstraintButton addItemWithTitle:@""];
    [[addConstraintButton itemAtIndex:0] setImage:[NSImage imageNamed:NSImageNameAddTemplate]];
    [[addConstraintButton itemAtIndex:0] setOnStateImage:nil];
    [[addConstraintButton itemAtIndex:0] setMixedStateImage:nil];
    // Add Primary Key (constraint)
    self.addPrimaryKeyMenuItem = [[NSMenuItem alloc] initWithTitle:@"Add Primary Key…" action:nil keyEquivalent:@""];
    [[addConstraintButton menu] addItem:addPrimaryKeyMenuItem];
    
    [constraintsView addSubview:addConstraintButton positioned:NSWindowAbove relativeTo:constraintsView];
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
    [self.columnActionsButton setEnabled:enabled];
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
