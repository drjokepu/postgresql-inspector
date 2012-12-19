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
#import "PGDatabase.h"
#import "PGDatabaseManager.h"
#import "PGRelationColumn.h"
#import "PGSchemaObjectIdentifier.h"
#import "PGSchemaObjectGroup.h"
#import "PGSchemaIdentifier.h"
#import "PGTableIdentifier.h"
#import "PGTable.h"
#import "PGQueryWindowController.h"

@interface PGDatabaseWindowController ()

@property (nonatomic, strong) NSMutableArray *queryWindowControllerList;

-(void)updateSchemaMenu;
-(PGSchemaIdentifier*)selectedSchema;
-(id)tableColumnsTableViewObjectValueForColumn:(NSString*)identifier row:(NSUInteger)row;

@end

@implementation PGDatabaseWindowController
@synthesize selectedSchemaObject;
@synthesize outlineView;
@synthesize schemaPopUpButton;
@synthesize schemaMenu;
@synthesize tableColumnsTableView;

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
    [database loadSchema:connection];
    self.queryWindowControllerList = [[NSMutableArray alloc] init];
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
    [outlineView reloadData];
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

-(void)updateSchemaMenu
{
    [schemaMenu removeAllItems];
    for (PGSchemaIdentifier *schema in database.schemaNames)
    {
        [schemaMenu addItemWithTitle:schema.name action:nil keyEquivalent:@""];
    }
    
    if ([database.schemaNames count] > 0)
        [schemaPopUpButton selectItemAtIndex:database.publicSchemaIndex];
}

-(void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    const NSInteger selectedRow = [outlineView selectedRow];
    if (selectedRow == -1)
    {
        
    }
    else
    {
        id selectedItem = [outlineView itemAtRow:selectedRow];
        if ([selectedItem isKindOfClass:[PGTableIdentifier class]]) // table
        {
            PGTableIdentifier *selectedTableIdentifier = (PGTableIdentifier*)selectedItem;
            [PGTable load:selectedTableIdentifier.oid fromConnection:connection callback:^(PGTable *table) {
                self.selectedSchemaObject = table;
                [tableColumnsTableView reloadData];
            }];
        }
    }
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == tableColumnsTableView)
        return self.selectedTable.columns.count;
    else
        return 0;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (tableView == tableColumnsTableView)
        return [self tableColumnsTableViewObjectValueForColumn:tableColumn.identifier row:row];
    else
        return nil;
}

-(id)tableColumnsTableViewObjectValueForColumn:(NSString *)identifier row:(NSUInteger)row
{
    PGRelationColumn *column = [self.selectedTable.columns objectAtIndex:row];
    
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

-(void)queryDatabase:(id)sender
{
    PGQueryWindowController *queryWindowController = [[PGQueryWindowController alloc] init];
    queryWindowController.parentWindowController = self;
    [queryWindowController useConnection:[self.connection copy]];
    [[queryWindowController window] makeKeyAndOrderFront:self];
    [self.queryWindowControllerList addObject:queryWindowController];
}

-(void)willCloseQueryWindow:(PGQueryWindowController *)queryWindowController
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.queryWindowControllerList removeObject:queryWindowController];
    }];
}

@end
