//
//  PGDatabaseWindowController.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 30/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import "PGDatabaseWindowController.h"
#import "PGConnection.h"
#import "PGConnectionEntry.h"
#import "PGConstraint.h"
#import "PGConstraintColumn.h"
#import "PGCreateTableWindowController.h"
#import "PGDatabase.h"
#import "PGDatabaseManager.h"
#import "PGQueryWindowController.h"
#import "PGRelationColumn.h"
#import "PGSchemaObjectIdentifier.h"
#import "PGSchemaObjectGroup.h"
#import "PGSchemaIdentifier.h"
#import "PGTableIdentifier.h"
#import "PGTable.h"

@interface PGDatabaseWindowController ()
@property (nonatomic, assign) BOOL schemaHasBeenLoadedPreviously;
@end

@implementation PGDatabaseWindowController
@synthesize selectedSchemaObject;
@synthesize outlineView;
@synthesize schemaPopUpButton;
@synthesize schemaMenu;
@synthesize tableColumnsTableView;
@synthesize constraintsTableView;

@synthesize connection, database;

-(NSString *)windowNibName
{
    return @"PGDatabaseWindowController";
}

-(void)windowDidLoad
{
    [super windowDidLoad];
    [[self window] setTitle:[database.connectionEntry description]];
    [outlineView setFloatsGroupRows:NO];
    self.schemaHasBeenLoadedPreviously = NO;
    [database loadSchema:connection];
}

-(void)windowWillClose:(NSNotification *)notification
{
    if (connection != nil)
    {
        [connection close];
        self.connection = nil;
    }
    [[PGDatabaseManager sharedManager] removeDatabaseWindowController:self delayed:YES];
}

-(void)selectDefaultSchema
{
    [self selectSchemaWithOid:self.connection.connectionEntry.defaultNamespaceOid];
}

-(void)selectSchemaWithOid:(NSInteger)oid
{
    const NSUInteger schemaCount = [database.schemaNames count];
    for (NSUInteger i = 0; i < schemaCount; i++)
    {
        PGSchemaIdentifier *schemaIdentifier = database.schemaNames[i];
        if (schemaIdentifier.oid == oid)
        {
            [schemaPopUpButton selectItemAtIndex:i];
            return;
        }
    }
}

-(PGSchemaIdentifier *)selectedSchema
{
    return [database.schemaNameLookup objectForKey:[[schemaPopUpButton selectedItem] title]];
}

-(PGTable *)selectedTable
{
    if (selectedSchemaObject != nil && [selectedSchemaObject isKindOfClass:[PGTable class]])
    {
        return (PGTable*)selectedSchemaObject;
    }
    else
    {
        return nil;
    }
}

-(void)databaseDidUpdateSchema:(PGDatabase *)theDatabase
{
    [self updateSchemaMenu];
    [outlineView reloadData];
    
    for (PGSchemaObjectGroup *group in database.schemaObjectGroups)
    {
        [outlineView expandItem:group];
    }
}

-(void)didChangeSchemaPopUpButtonValue:(id)sender
{
    [self selectedSchemaChanged];
}

-(void)selectedSchemaChanged
{
    [outlineView reloadData];
    self.connection.connectionEntry.defaultNamespaceOid = self.selectedSchema.oid;
    [self.connection.connectionEntry update];
}

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    return [self validateItemTag:[menuItem tag]];
}

-(BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    return [self validateItemTag:[theItem tag]];
}

-(BOOL)validateItemTag:(NSInteger)tag
{
    switch (tag)
    {
        case 2000:
            return YES;
        case 2001:
            return [self selectedTable] != nil;
        default:
            return YES;
    }
}

-(NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (item == NULL)
    {
        return [database.schemaObjectGroups count];
    }
    else if ([item isKindOfClass:[PGSchemaObjectIdentifier class]])
    {
        switch ([item groupType])
        {
            case PGSchemaObjectGroupTypeTables:
                return [[self selectedSchema].tableNames count];
            case PGSchemaObjectGroupTypeViews:
                return [[self selectedSchema].viewNames count];
            default:
                return 0;
        }
    }
    else
    {
        return 0;
    }
}

-(BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return (item == nil ||
            [item isKindOfClass:[PGSchemaObjectGroup class]]);
}

-(id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (item == NULL)
    {
        return [database.schemaObjectGroups objectAtIndex:index];
    }
    else if ([item isKindOfClass:[PGSchemaObjectIdentifier class]])
    {
        switch ([item groupType])
        {
            case PGSchemaObjectGroupTypeTables:
                return [[self selectedSchema].tableNames objectAtIndex:index];
            case PGSchemaObjectGroupTypeViews:
                return [[self selectedSchema].viewNames objectAtIndex:index];
            default:
                return nil;
        }
    }
    else
    {
        return nil;
    }
}

-(id)outlineView:(NSOutlineView *)theOutlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if ([self outlineView:theOutlineView isGroupItem:item])
    {
        return [[item name] uppercaseString];
    }
    else
    {
        return [item name];
    }
}

-(BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
    return [item isKindOfClass:[PGSchemaObjectGroup class]];
}

-(NSString*)selectedSchemaName
{
    return self.schemaHasBeenLoadedPreviously ? [[schemaPopUpButton selectedItem] title] : nil;
}

-(void)updateSchemaMenu
{
    NSString *selectedSchemaName = [self selectedSchemaName];
    [schemaMenu removeAllItems];
    for (PGSchemaIdentifier *schema in database.schemaNames)
    {
        [schemaMenu addItemWithTitle:schema.name action:nil keyEquivalent:@""];
    }
    
    if (self.schemaHasBeenLoadedPreviously)
    {
        if (selectedSchemaName != nil)
        {
            [schemaPopUpButton selectItemWithTitle:selectedSchemaName];
        }
    }
    else
    {
        self.schemaHasBeenLoadedPreviously = YES;
        if ([database.schemaNames count] > 0 && database.publicSchemaIndex >= -1)
            [schemaPopUpButton selectItemAtIndex:database.publicSchemaIndex];
        [self selectDefaultSchema];
    }
}

-(void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    const NSInteger selectedRow = [outlineView selectedRow];
    if (selectedRow == -1)
    {
        self.selectedSchemaObject = nil;
        [self reloadTableData];
        [[self window] update];
    }
    else
    {
        id selectedItem = [outlineView itemAtRow:selectedRow];
        if ([selectedItem isKindOfClass:[PGTableIdentifier class]]) // table
        {
            PGTableIdentifier *selectedTableIdentifier = (PGTableIdentifier*)selectedItem;
            [PGTable load:selectedTableIdentifier.oid fromConnection:connection callback:^(PGTable *table) {
                self.selectedSchemaObject = table;
                [self reloadTableData];
            }];
        }
        [[self window] update];
    }
}

-(void)reloadTableData
{
    [tableColumnsTableView reloadData];
    [constraintsTableView reloadData];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == tableColumnsTableView)
        return self.selectedTable.columns.count;
    else if (tableView == constraintsTableView)
        return self.selectedTable.constraints.count;
    else
        return 0;
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (tableView == tableColumnsTableView)
        return [self columnsTableViewViewForRow:(NSUInteger)row];
    else if (tableView == constraintsTableView)
        return [self constraintsTableViewViewForRow:(NSUInteger)row];
    else
        return nil;
}

-(id)tableColumnsTableViewObjectValueForColumn:(NSString *)identifier row:(NSUInteger)row
{
    PGRelationColumn *column = self.selectedTable.columns[row];
    
    if ([identifier isEqualToString:@"name"])
        return column.name;
    else if ([identifier isEqualToString:@"type"])
        return column.typeName;
    else if ([identifier isEqualToString:@"default"])
        return column.defaultValue;
    else if ([identifier isEqualToString:@"notNull"])
        return [[NSNumber alloc] initWithBool:column.notNull];
    else if ([identifier isEqualToString:@"primaryKey"])
        return [[NSNumber alloc] initWithBool:[self.selectedTable isColumnInPrimaryKey:column.number]];
    else
        return @"";
}

-(NSView*)columnsTableViewViewForRow:(NSUInteger)row
{
    @autoreleasepool
    {
        PGRelationColumn *column = self.selectedTable.columns[row];
        NSTableCellView *cellView = [self.tableColumnsTableView makeViewWithIdentifier:@"columnCellView" owner:self];
        
        [[cellView viewWithTag:7500] setStringValue:column.name];
        
        NSMutableArray *typeInfoList = [[NSMutableArray alloc] init];
        [typeInfoList addObject:[column fullType]];
        if ([self.selectedTable isColumnInPrimaryKey:column.number])
            [typeInfoList addObject:@"primary key"];
        if (column.notNull)
            [typeInfoList addObject:@"not null"];
        [[cellView viewWithTag:7501] setStringValue:[typeInfoList componentsJoinedByString:@", "]];
        if (column.defaultValue != [NSNull null])
            [typeInfoList addObject:[[NSString alloc] initWithFormat:@"default: %@", column.defaultValue]];
        
        return cellView;
    }
}

-(NSView*)constraintsTableViewViewForRow:(NSUInteger)row
{
    PGConstraint *constraint = self.selectedTable.constraints[row];
    NSTableCellView *cellView = [self.constraintsTableView makeViewWithIdentifier:@"constraintCellView" owner:self];
    
    [[cellView viewWithTag:7000] setImage:[PGDatabaseWindowController imageForConstraintType:constraint.type]];
    [[cellView viewWithTag:7001] setStringValue:constraint.name];
    [[cellView viewWithTag:7002] setStringValue:[constraint constraintTypeDescription]];
    [[cellView viewWithTag:7003] setStringValue:[self constraintUIDefinition:constraint]];
    
    return cellView;
}

+(NSImage*)imageForConstraintType:(PGConstraintType)constraintType
{
    NSString *imageName = [PGDatabaseWindowController imageNameForConstraintType:constraintType];
    if (imageName == nil)
    {
        imageName = NSImageNameAdvanced;
    }
    return [NSImage imageNamed:imageName];
}

+(NSString*)imageNameForConstraintType:(PGConstraintType)constraintType
{
    switch (constraintType)
    {
        case PGConstraintTypePrimaryKey:
            return @"primary_key";
        case PGConstraintTypeUniqueKey:
            return @"unique_key";
        case PGConstraintTypeForeignKey:
            return @"foreign_key";
        case PGConstraintTypeCheck:
            return @"check";
        default:
            return nil;
    }
}

-(NSString*)constraintUIDefinition:(PGConstraint *)constraint
{
    return [PGConstraint constraintUIDefinition:constraint inColumns:self.selectedTable.columns];
}

-(void)queryDatabase:(id)sender
{
    PGQueryWindowController *queryWindowController = [[PGQueryWindowController alloc] init];
    [queryWindowController useConnection:[self.connection copy]];
    [[queryWindowController window] makeKeyAndOrderFront:self];
}

-(void)querySelectedRelation:(id)sender
{
    if (self.selectedTable != nil)
    {
        [self queryRelation:self.selectedTable];
    }
}

-(void)queryRelation:(PGRelation*)relation
{
    if (relation == nil) return;
    
    PGQueryWindowController *queryWindowController = [[PGQueryWindowController alloc] init];
    
    queryWindowController.initialQueryString = [[NSString alloc] initWithFormat:@"select t.* from %@ t;", [relation schemaQualifiedName]];
    
    [queryWindowController useConnection:[self.connection copy]];
    [[queryWindowController window] makeKeyAndOrderFront:self];
}

-(void)createTable:(id)sender
{
    PGCreateTableWindowController *createTableWindowController = [[PGCreateTableWindowController alloc] init];
    
    NSMutableArray *schemaNames = [[NSMutableArray alloc] initWithCapacity:[database.schemaNames count]];
    for (PGSchemaIdentifier *schema in database.schemaNames)
        [schemaNames addObject:schema.name];
    
    createTableWindowController.initialSchemaName = [self selectedSchemaName];
    createTableWindowController.initialSchemaNameList = schemaNames;
    
    [createTableWindowController useConnection:[self.connection copy] database:database];
    [[createTableWindowController window] makeKeyAndOrderFront:self];
}

@end
