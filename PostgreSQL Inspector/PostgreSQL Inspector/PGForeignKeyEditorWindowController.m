//
//  PGForeignKeyEditorWindowController.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 28/03/2013.
//
//

#import "PGForeignKeyEditorWindowController.h"
#import "PGActionBlockWrapper.h"
#import "PGConstraint.h"
#import "PGConstraintColumn.h"
#import "PGDatabase.h"
#import "PGRelationColumn.h"
#import "PGSchemaIdentifier.h"
#import "PGTable.h"
#import "PGTableIdentifier.h"

static PGForeignKeyAction actionForMatrixIndex(const NSInteger index) __attribute__ ((pure));
static NSInteger matrixIndexForAction(const PGForeignKeyAction action) __attribute__ ((pure));

@interface PGForeignKeyEditorWindowController ()
{
    NSMutableArray *actionBlockWrappers;
}

@property (nonatomic, strong) PGConstraint *initialConstraint;
@property (nonatomic, strong) PGConnection *connection;
@property (nonatomic, strong) PGDatabase *database;
@property (nonatomic, strong) NSArray *tableColumns;
@property (nonatomic, strong) NSArray *tableList;
@property (nonatomic, strong) NSMutableDictionary *tableCache;
@property (nonatomic, strong) PGTable *targetTable;
@property (nonatomic, strong) NSArray *keyColumns;

@property (strong) IBOutlet NSTextField *constraintNameTextField;
@property (strong) IBOutlet NSButton *actionButton;
@property (strong) IBOutlet NSTableView *tableColumnsTableView;
@property (strong) IBOutlet NSButton *tableColumnsSpaceButton;
@property (strong) IBOutlet NSPopUpButton *targetTableListPopUpButton;
@property (strong) IBOutlet NSTableView *targetTableColumnsTableView;
@property (strong) IBOutlet NSMatrix *onUpdateMatrix;
@property (strong) IBOutlet NSMatrix *onDeleteMatrix;

@end

@implementation PGForeignKeyEditorWindowController
@synthesize constraintEditorAction, connection, database, initialConstraint, keyColumns, tableCache, tableColumns, tableColumnsTableView, tableList, targetTable, targetTableListPopUpButton;

-(NSString *)windowNibName
{
    return @"PGForeignKeyEditorWindowController";
}

-(void)windowDidLoad
{
    [super windowDidLoad];
    switch (constraintEditorAction)
    {
        case PGEditorAdd:
            [self.actionButton setTitle:@"Add"];
            break;
        case PGEditorUpdate:
            [self.actionButton setTitle:@"Update"];
            break;
    }
    
    self.keyColumns = [[NSArray alloc] init];
    self->actionBlockWrappers = [[NSMutableArray alloc] init];
    [self populateTableList];
    [self loadInitialConstraintData];
    [self validateActionButton];
}

-(void)loadInitialConstraintData
{
    if (initialConstraint != nil)
    {
        [self.constraintNameTextField setStringValue:initialConstraint.name];
        [self setOnUpdateAction:initialConstraint.foreignKeyUpdateAction];
        [self setOnDeleteAction:initialConstraint.foreignKeyDeleteAction];
    }
}

-(void)validateActionButton
{
    [self.actionButton setEnabled:[keyColumns count] > 0];
}

-(void)didSelectTargetTable:(id)sender
{
    [self populateTargetTableColumnList];
}

-(void)didClickAction:(id)sender
{
    [[NSApplication sharedApplication] endSheet:[self window] returnCode:1];
}

-(void)didClickCancel:(id)sender
{
    [[NSApplication sharedApplication] endSheet:[self window] returnCode:0];
}

-(PGConstraint *)getConstraint
{
    PGConstraint *constraint = [[PGConstraint alloc] init];
    [self populateConstraintWithData:constraint];
    return constraint;
}

-(void)updateConstraint
{
    [self populateConstraintWithData:initialConstraint];
}

-(void)populateConstraintWithData:(PGConstraint*)constraint
{
    constraint.type = PGConstraintTypeForeignKey;
    constraint.name = [[NSString alloc] initWithString:[self.constraintNameTextField stringValue]];
    constraint.columns = [[NSMutableArray alloc] initWithArray:keyColumns];
    constraint.relationNamespaceName = targetTable.schemaName;
    constraint.relationName = targetTable.name;
    constraint.foreignKeyUpdateAction = [self onUpdateAction];
    constraint.foreignKeyDeleteAction = [self onDeleteAction];
}

-(void)useConstraint:(PGConstraint *)constraint database:(PGDatabase *)theDatabase connection:(PGConnection *)theConnection tableColumns:(NSArray *)theTableColumns
{
    self.connection = theConnection;
    self.database = theDatabase;
    self.tableColumns = theTableColumns;
    self.initialConstraint = constraint;
}

-(void)populateTableList
{
    // first we need to push the public schema to the end of the list
    NSMutableArray *sortedSchemaNames = [[NSMutableArray alloc] initWithCapacity:[database.schemaNames count]];
    const NSInteger publicSchemaIndex = database.publicSchemaIndex;
    
    for (NSInteger i = 0; i < [database.schemaNames count]; i++)
    {
        if (i != publicSchemaIndex)
        {
            [sortedSchemaNames addObject:database.schemaNames[i]];
        }
    }
    
    if (publicSchemaIndex > 0)
    {
        [sortedSchemaNames addObject:database.schemaNames[publicSchemaIndex]];
    }
    
    NSMutableArray *mutableTableList = [[NSMutableArray alloc] init];
    NSMutableArray *mutableTableNameList = [[NSMutableArray alloc] init];
    
    // and now we can populate the NSPopUpButton
    NSInteger selectedTableIndex = -1;
    for (NSInteger i = 0; i < [sortedSchemaNames count]; i++)
    {
        PGSchemaIdentifier *schemaName = sortedSchemaNames[i];
        if ([schemaName systemSchema]) continue;
        for (PGTableIdentifier *table in [database.schemaNameLookup[schemaName.name] tableNames])
        {
            [mutableTableList addObject:table];
            const NSUInteger tableNameIndex = [mutableTableNameList count];
            [mutableTableNameList addObject:[table shortName]];
            if (selectedTableIndex < 0 &&
                initialConstraint != nil &&
                [initialConstraint.relationNamespaceName isEqualToString:table.schemaName] &&
                [initialConstraint.relationName isEqualToString:table.name])
            {
                selectedTableIndex = (NSInteger)tableNameIndex;
            }
        }
    }
    
    [targetTableListPopUpButton removeAllItems];
    [targetTableListPopUpButton addItemsWithTitles:mutableTableNameList];
    self.tableList = mutableTableList;
    
    if (selectedTableIndex >= 0)
    {
        [targetTableListPopUpButton selectItemAtIndex:selectedTableIndex];
    }
    
    [self populateTargetTableColumnList];
}

-(void)populateTargetTableColumnList
{
    PGTableIdentifier *tableIdentifier = tableList[[targetTableListPopUpButton indexOfSelectedItem]];
    const NSInteger tableOid = tableIdentifier.oid;
    
    if (tableCache == nil) self.tableCache = [[NSMutableDictionary alloc] init];
    PGTable *table = tableCache[@(tableOid)];
    if (table == nil)
    {
        [PGTable load:tableOid fromConnection:connection callback:^(PGTable *tableFromDatabase) {
            [self populateTargetTableColumnListWithTable:tableFromDatabase];
            tableCache[@(tableOid)] = tableFromDatabase;
        }];
    }
    else
    {
        [self populateTargetTableColumnListWithTable:table];
    }
}

-(void)populateTargetTableColumnListWithTable:(PGTable*)table
{
    self.targetTable = table;
    [self populateKeyColumns];
    [self validateActionButton];
    [tableColumnsTableView reloadData];
}

-(void)populateKeyColumns
{
    if (constraintEditorAction == PGEditorAdd ||
        ![initialConstraint.relationNamespaceName isEqualToString:targetTable.schemaName] ||
        ![initialConstraint.relationName isEqualToString:targetTable.name] ||
        initialConstraint.columns == nil)
    {
        self.keyColumns = [[NSArray alloc] init];
    }
    else
    {
        self.keyColumns = initialConstraint.columns;
    }
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == tableColumnsTableView)
    {
        return [tableColumns count];
    }
    else
    {
        return 0;
    }
}

-(NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (tableView == tableColumnsTableView)
    {
        return [self tableColumnsViewForColumn:[tableColumn identifier] row:row];
    }
    else
    {
        return nil;
    }
}

-(NSView*)tableColumnsViewForColumn:(NSString*)columnIdentifier row:(NSInteger)row
{
    PGRelationColumn *column = tableColumns[row];
    if ([columnIdentifier isEqualToString:@"localColumnName"])
    {
        NSTableCellView *cellView = [tableColumnsTableView makeViewWithIdentifier:@"localColumnName" owner:self];
        [cellView.textField setStringValue:column.name];
        return cellView;
    }
    else if ([columnIdentifier isEqualToString:@"referencedColumnName"])
    {
        NSTableCellView *cellView = [tableColumnsTableView makeViewWithIdentifier:@"referencedColumnName" owner:self];
        NSPopUpButton *popUpButton = [cellView viewWithTag:6901];
        [popUpButton removeAllItems];
        
        NSMenuItem *blankMenuItem = [[NSMenuItem alloc] initWithTitle:@"" action:NULL keyEquivalent:@""];
        [[popUpButton menu] addItem:blankMenuItem];
        
        NSString *columnNameLowerCase = [column.typeName lowercaseString];
        for (PGRelationColumn *targetColumn in targetTable.columns)
        {
            @autoreleasepool
            {   
                if ([columnNameLowerCase isEqualToString:[targetColumn.typeName lowercaseString]])
                {
                    [popUpButton addItemWithTitle:targetColumn.name];
                }
            }
        }
        
        if ([keyColumns count] == 0)
        {
            [popUpButton selectItem:blankMenuItem];
        }
        else
        {
            for (PGConstraintColumn *constraintColumn in keyColumns)
            {
                if ([constraintColumn.columnName isEqualToString:column.name])
                {
                    [popUpButton selectItemWithTitle:constraintColumn.foreignKeyReferencedColumnName];
                }
            }
        }
        [popUpButton setAction:@selector(action)];
        
        __weak PGForeignKeyEditorWindowController *weakSelf = self;
        PGActionBlockWrapper *actionBlockWrapper = [[PGActionBlockWrapper alloc] initWithBlock:^{
            [weakSelf updateKeyColumnsWithColumn:column.name targetColumn:[[popUpButton selectedItem] title]];
        }];
        
        [popUpButton setTarget:actionBlockWrapper];
        [actionBlockWrappers addObject:actionBlockWrapper];
        
        return cellView;
    }
    else
    {
        return nil;
    }
}

-(void)updateKeyColumnsWithColumn:(NSString*)sourceColumnName targetColumn:(NSString*)targetColumnName
{
    NSMutableArray *constraintColumns = [[NSMutableArray alloc] init];
    
    for (PGRelationColumn *relationColumn in tableColumns)
    {
        if ([relationColumn.name isEqualToString:sourceColumnName])
        {
            if ([targetColumnName length] != 0)
            {
                PGConstraintColumn *constraintColumn = [[PGConstraintColumn alloc] init];
                constraintColumn.columnName = sourceColumnName;
                constraintColumn.foreignKeyReferencedColumnName = targetColumnName;
                [constraintColumns addObject:constraintColumn];
            }
        }
        else
        {
            for (PGConstraintColumn *keyColumn in keyColumns)
            {
                if ([keyColumn.columnName isEqualToString:sourceColumnName])
                {
                    [constraintColumns addObject:keyColumn];
                    break;
                }
            }
        }
    }
    
    self.keyColumns = constraintColumns;
    [self validateActionButton];
}

-(PGForeignKeyAction)onUpdateAction
{
    return [PGForeignKeyEditorWindowController getActionFromMatrix:self.onUpdateMatrix];
}

-(PGForeignKeyAction)onDeleteAction
{
    return [PGForeignKeyEditorWindowController getActionFromMatrix:self.onDeleteMatrix];
}

-(void)setOnUpdateAction:(PGForeignKeyAction)action
{
    [PGForeignKeyEditorWindowController setAction:action inMatrix:self.onUpdateMatrix];
}

-(void)setOnDeleteAction:(PGForeignKeyAction)action
{
    [PGForeignKeyEditorWindowController setAction:action inMatrix:self.onDeleteMatrix];
}

+(PGForeignKeyAction)getActionFromMatrix:(NSMatrix *)matrix
{
    return actionForMatrixIndex([matrix selectedRow]);
}

+(void)setAction:(PGForeignKeyAction)action inMatrix:(NSMatrix*)matrix
{
    [matrix selectCellAtRow:matrixIndexForAction(action) column:0];
}

static PGForeignKeyAction actionForMatrixIndex(const NSInteger index)
{
    switch (index)
    {
        case 1:
            return PGForeignKeyActionRestrict;
        case 2:
            return PGForeignKeyActionCascade;
        case 3:
            return PGForeignKeyActionSetNull;
        case 4:
            return PGForeignKeyActionSetDefault;
        case 0:
        default:
            return PGForeignKeyActionNone;
    }
}

static NSInteger matrixIndexForAction(const PGForeignKeyAction action)
{
    switch (action)
    {
        case PGForeignKeyActionRestrict:
            return 1;
        case PGForeignKeyActionCascade:
            return 2;
        case PGForeignKeyActionSetNull:
            return 3;
        case PGForeignKeyActionSetDefault:
            return 4;
        case PGForeignKeyActionNone:
        default:
            return 0;
    }
}

@end
