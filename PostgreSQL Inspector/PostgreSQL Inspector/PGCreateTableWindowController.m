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
#import "PGConstraintColumn.h"
#import "PGDatabaseWindowController.h"
#import "PGRelationColumn.h"
#import "PGUniqueKeyEditorWindowController.h"
#import "Utils.h"

@interface PGCreateTableWindowController ()
@property (nonatomic, strong) PGConnection *connection;
@property (nonatomic, assign) BOOL connectionIsOpen;
@property (nonatomic, strong) NSMutableArray *tableColumns;
@property (nonatomic, strong) NSMutableArray *tableConstraints;
@property (nonatomic, strong) PGColumnEditorWindowController *columnEditorSheet;
@property (nonatomic, strong) PGUniqueKeyEditorWindowController *uniqueKeyEditorSheet;

@property (strong) IBOutlet NSTextField *tableNameTextField;
@property (strong) IBOutlet NSComboBox *schemaComboBox;
@property (strong) IBOutlet NSView *columnsView;
@property (strong) IBOutlet NSTableView *columnsTableView;
@property (strong) IBOutlet NSView *constraintsView;
@property (strong) IBOutlet NSTableView *constraintsTableView;

@property (nonatomic, strong) IBOutlet NSButton *addColumnButton;
@property (nonatomic, strong) IBOutlet NSButton *removeColumnButton;
@property (nonatomic, strong) IBOutlet NSPopUpButton *columnActionsButton;
@property (nonatomic, strong) NSMenuItem *columnEditColumnMenuItem;
@property (nonatomic, strong) NSMenuItem *columnMoveUpMenuItem;
@property (nonatomic, strong) NSMenuItem *columnMoveDownMenuItem;

@property (nonatomic, strong) IBOutlet NSPopUpButton *addConstraintButton;
@property (nonatomic, strong) NSMenuItem *addPrimaryKeyMenuItem;

-(IBAction)didClickCancel:(id)sender;
-(IBAction)didClickAddColumn:(id)sender;
-(IBAction)didClickRemoveColumn:(id)sender;

@end

@implementation PGCreateTableWindowController
@synthesize columnsView;
@synthesize addColumnButton;
@synthesize removeColumnButton;
@synthesize columnActionsButton;
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
    
    [self configurePullDownMenus];
    //[self createButtons];

    [self validateColumnActions];
    [self validateConstraintActions];
}

-(void)configurePullDownMenus
{
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
    
    [[addConstraintButton cell] setArrowPosition:NSPopUpArrowAtBottom];
    [addConstraintButton addItemWithTitle:@""];
    [[addConstraintButton itemAtIndex:0] setImage:[NSImage imageNamed:NSImageNameAddTemplate]];
    [[addConstraintButton itemAtIndex:0] setOnStateImage:nil];
    [[addConstraintButton itemAtIndex:0] setMixedStateImage:nil];
    // Add Primary Key (constraint)
    self.addPrimaryKeyMenuItem = [[NSMenuItem alloc] initWithTitle:@"Add Primary Key…" action:@selector(didClickAddPrimaryKey:) keyEquivalent:@""];
    [[addConstraintButton menu] addItem:addPrimaryKeyMenuItem];
    [[addConstraintButton menu] addItem:[[NSMenuItem alloc] initWithTitle:@"Add Unique Key…" action:@selector(didClickAddUniqueKey:) keyEquivalent:@""]];
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
    

    // Space Button (column)
//    const CGFloat columnSpaceButtonX = baseX + ((normalButtonWidth - 1) * 2) + wideButtonWidth - 1;
//    self.columnSpaceButton = [[NSButton alloc] initWithFrame:NSMakeRect(columnSpaceButtonX, baseY, [self.columnsTableView frame].size.width + baseX - columnSpaceButtonX + 2, buttonHeight)];
//    [[columnSpaceButton cell] setHighlightsBy:NSNoCellMask];
//    [[columnSpaceButton cell] setShowsStateBy:NSNoCellMask];
//    [columnSpaceButton setTitle:@""];
//    [columnSpaceButton setBezelStyle:NSSmallSquareBezelStyle];
//    [columnSpaceButton setAutoresizingMask:NSViewWidthSizable];
//    [columnsView addSubview:columnSpaceButton positioned:NSWindowAbove relativeTo:columnsView];
    
    // Constraint Buttons
    // Add Constraint
//    self.addConstraintButton = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(baseX, baseY, wideButtonWidth, buttonHeight) pullsDown:YES];
//    [addConstraintButton setBezelStyle:NSSmallSquareBezelStyle];
//    [addConstraintButton setImagePosition:NSImageOnly];
    
    
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
    else if (tableView == self.constraintsTableView)
    {
        return [self.tableConstraints count];
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
    else if (tableView == self.constraintsTableView)
    {
        return [self viewForConstraintAtIndex:row];
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

-(NSView*)viewForConstraintAtIndex:(NSUInteger)row
{
    @autoreleasepool
    {
        PGConstraint *constraint = self.tableConstraints[row];
        NSTableCellView *cellView = [self.constraintsTableView makeViewWithIdentifier:@"createTableConstraintCellView" owner:self];
        
        [[cellView viewWithTag:7000] setImage:[PGDatabaseWindowController imageForConstraintType:constraint.type]];
        [[cellView viewWithTag:7001] setStringValue:constraint.name];
        [[cellView viewWithTag:7002] setStringValue:[constraint constraintTypeDescription]];
        [[cellView viewWithTag:7003] setStringValue:[PGConstraint constraintUIDefinition:constraint inColumns:self.tableColumns]];
        
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
        [self removeColumnFromDependants:[self.tableColumns[columnIndex] name]];
        [self.tableColumns removeObjectAtIndex:columnIndex];
        [self.columnsTableView reloadData];
        [self.constraintsTableView reloadData];
    }
}


-(void)removeColumnFromDependants:(NSString*)columnName
{
    [self removeColumnFromConstraints:columnName];
}

-(void)removeColumnFromConstraints:(NSString*)columnName
{
    NSMutableIndexSet *indexesOfConstraintsToBeRemoved = [[NSMutableIndexSet alloc] init];
    
    for (NSUInteger constraintIndex = 0; constraintIndex < [self.tableConstraints count]; constraintIndex++)
    {
        const PGConstraint *constraint = self.tableConstraints[constraintIndex];
        NSMutableIndexSet *indexesOfColumnsToBeRemoved = [[NSMutableIndexSet alloc] init];
        for (NSUInteger columnIndex = 0; columnIndex < [constraint.columns count]; columnIndex++)
        {
            const PGConstraintColumn *constraintColumn = constraint.columns[columnIndex];
            if (constraintColumn.columnNumber == -1 && [constraintColumn.columnName isEqualToString:columnName])
            {
                [indexesOfColumnsToBeRemoved addIndex:columnIndex];
            }
        }
        
        if ([indexesOfColumnsToBeRemoved count] > 0)
        {
            [constraint.columns removeObjectsAtIndexes:indexesOfColumnsToBeRemoved];
        }
        
        if (constraint.needsColumns && [constraint.columns count] == 0)
        {
            [indexesOfConstraintsToBeRemoved addIndex:constraintIndex];
        }
    }
    
    if ([indexesOfConstraintsToBeRemoved count] > 0)
    {
        [self.tableConstraints removeObjectsAtIndexes:indexesOfConstraintsToBeRemoved];
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
            PGRelationColumn *oldColumn = self.tableColumns[columnIndex];
            PGRelationColumn *newColumn = [self.columnEditorSheet getColumn];
            self.tableColumns[columnIndex] = newColumn;
            [self renameColumnInDependants:oldColumn.name to:newColumn.name];
            [self.columnsTableView reloadData];
            [self.constraintsTableView reloadData];
        }
    }
    
    [sheet orderOut:self];
    self.columnEditorSheet = nil;
}

-(void)renameColumnInDependants:(NSString*)oldName to:(NSString*)newName
{
    if ([oldName isEqualToString:newName]) return;
    [self renameColumnInConstraints:oldName to:newName];
}

-(void)renameColumnInConstraints:(NSString*)oldName to:(NSString*)newName
{
    for (PGConstraint *constraint in self.tableConstraints)
    {
        for (PGConstraintColumn *constraintColumn in constraint.columns)
        {
            if (constraintColumn.columnNumber == -1 && [constraintColumn.columnName isEqualToString:oldName])
            {
                constraintColumn.columnName = newName;
            }
        }
    }
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

-(void)didClickAddPrimaryKey:(id)sender
{
    [self openUniqueKeyEditorSheet:YES];
}

-(void)didClickAddUniqueKey:(id)sender
{
    [self openUniqueKeyEditorSheet:NO];
}

-(void)openUniqueKeyEditorSheet:(BOOL)isPrimaryKey
{
    PGUniqueKeyEditorWindowController *uniqueKeyEditorSheet = [[PGUniqueKeyEditorWindowController alloc] init];
    uniqueKeyEditorSheet.isPrimaryKey = isPrimaryKey;
    uniqueKeyEditorSheet.availableColumns = self.tableColumns;
    [[NSApplication sharedApplication] beginSheet:[uniqueKeyEditorSheet window]
                                   modalForWindow:[self window]
                                    modalDelegate:self
                                   didEndSelector:@selector(didEndUniqueKeyEditorSheet:returnCode:contextInfo:)
                                      contextInfo:NULL];
    
    self.uniqueKeyEditorSheet = uniqueKeyEditorSheet;
}

-(void)didEndUniqueKeyEditorSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == 1)
    {
        [self.tableConstraints addObject:[self.uniqueKeyEditorSheet getConstraint]];
        [self.constraintsTableView reloadData];
    }
    
    [sheet orderOut:self];
    self.uniqueKeyEditorSheet = nil;
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
