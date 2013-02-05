//
//  PGCreateTableWindowController.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 04/02/2013.
//
//

#import "PGCreateTableWindowController.h"
#import "PGColumnEditorWindowController.h"
#import "PGConnection.h"
#import "PGRelationColumn.h"

@interface PGCreateTableWindowController ()
@property (nonatomic, strong) PGConnection *connection;
@property (nonatomic, assign) BOOL connectionIsOpen;
@property (nonatomic, strong) NSMutableArray *tableColumns;
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
    
    if (self.initialSchemaName != nil)
    {
        if (self.initialSchemaNameList != nil)
            [self.schemaComboBox addItemsWithObjectValues:self.initialSchemaNameList];
        
        if (self.initialSchemaName != nil)
            [self.schemaComboBox setStringValue:self.initialSchemaName];
    }
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
    PGRelationColumn *column = self.tableColumns[columnIndex];
    NSTableCellView *cellView = [self.columnsTableView makeViewWithIdentifier:@"createTableColumnCellView" owner:self];
    
    [[cellView viewWithTag:7500] setStringValue:column.name];
    
    NSMutableArray *typeInfoList = [[NSMutableArray alloc] init];
    [typeInfoList addObject:column.typeName];
    if (column.notNull)
        [typeInfoList addObject:@"not null"];
    [[cellView viewWithTag:7501] setStringValue:[typeInfoList componentsJoinedByString:@", "]];
    if (column.defaultValue != [NSNull null])
        [typeInfoList addObject:[[NSString alloc] initWithFormat:@"default: %@", column.defaultValue]];
    
    return cellView;
}

-(void)didClickAddColumn:(id)sender
{
    [self openAddColumnSheet];
}

-(void)openAddColumnSheet
{
    PGColumnEditorWindowController *columnEditorSheet = [[PGColumnEditorWindowController alloc] init];
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

@end
