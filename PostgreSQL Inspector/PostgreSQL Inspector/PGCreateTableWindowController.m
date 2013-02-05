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

@interface PGCreateTableWindowController ()
@property (nonatomic, strong) PGConnection *connection;
@property (nonatomic, assign) BOOL connectionIsOpen;
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
        return 0;
    }
    else
    {
        return 0;
    }
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return nil;
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
    [sheet orderOut:self];
    self.columnEditorSheet = nil;
}

@end
