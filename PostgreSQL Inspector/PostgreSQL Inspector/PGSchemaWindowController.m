//
//  PGSchemaWindowController.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 06/06/2013.
//
//

#import "PGSchemaWindowController.h"
#import "PGAppDelegate.h"
#import "PGCommand.h"
#import "PGConnection.h"
#import "PGConnectionEntry.h"
#import "PGDatabase.h"
#import "PGQueryWindowController.h"
#import "PGProgressSheet.h"
#import "PGResult.h"
#import "PGRole.h"
#import "PGSchema.h"

@interface PGSchemaWindowController ()

@property (nonatomic, strong) PGConnection *connection;
@property (nonatomic, strong) PGDatabase *database;
@property (nonatomic, assign) BOOL connectionIsOpen;
@property (nonatomic, strong) PGProgressSheet *progressSheet;

@property (strong) IBOutlet NSButton *actionButton;
@property (strong) IBOutlet NSButton *viewSqlButton;
@property (strong) IBOutlet NSTextField *nameTextField;
@property (strong) IBOutlet NSPopUpButton *ownerPopUpButton;

-(IBAction)didClickAction:(id)sender;
-(IBAction)didClickCancel:(id)sender;
-(IBAction)didClickViewSql:(id)sender;
-(IBAction)didChangeName:(id)sender;

@end

@implementation PGSchemaWindowController
@synthesize actionButton, connection, connectionIsOpen, database, editorAction, progressSheet, viewSqlButton;

-(NSString *)windowNibName
{
    return @"PGSchemaWindowController";
}

-(void)windowDidLoad
{
    [super windowDidLoad];
    
    if (editorAction == PGEditorAdd)
    {
        [actionButton setTitle:@"Create"];
        [self.window setTitle:@"Create Schema"];
    }
    else
    {
        [actionButton setTitle:@"Alter"];
        [self.window setTitle:@"Alter Schema"];
    }
    [self populateOwnerList];
    [self validateActionButtons];
}

-(void)populateOwnerList
{
    NSInteger selectedRoleIndex = -1;
    NSMutableArray *ownerList = [[NSMutableArray alloc] initWithCapacity:[self.database.roles count]];
    for (PGRole *role in self.database.roles)
    {
        if ([role.name isEqualToString:self.database.connectionEntry.username])
        {
            selectedRoleIndex = (NSInteger)[ownerList count];
        }
        [ownerList addObject:role.name];
    }
    [self.ownerPopUpButton addItemsWithTitles:ownerList];
    if (selectedRoleIndex >= 0)
    {
        [self.ownerPopUpButton selectItemAtIndex:selectedRoleIndex];
    }
}

-(void)didClickAction:(id)sender
{
    if (editorAction == PGEditorAdd)
    {
        [self createSchema];
    }
    else
    {
        
    }
}

-(void)didClickCancel:(id)sender
{
    [self close];
}

-(void)didChangeName:(id)sender
{
    [self validateActionButtons];
}

-(void)validateActionButtons
{
    const BOOL isValid = [self isSchemaValid];
    [actionButton setEnabled:isValid];
    [viewSqlButton setEnabled:isValid];
}

-(BOOL)isSchemaValid
{
    return [[self.nameTextField stringValue] length] > 0;
}

-(void)useConnection:(PGConnection *)theConnection database:(PGDatabase *)theDatabase
{
    self.connection = theConnection;
    self.connection.delegate = self;
    self.database = theDatabase;
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

/*
 
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
 [self validateActionButtons];
 }
 
 [sheet orderOut:self];
 self.columnEditorSheet = nil;
 }
 
 */

-(void)openProgressSheet
{
    PGProgressSheet *newProgressSheet = [[PGProgressSheet alloc] init];
    [[NSApplication sharedApplication] beginSheet:[newProgressSheet window] modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(didEndProgressSheet:returnCode:contextInfo:) contextInfo:NULL];
    
    self.progressSheet = newProgressSheet;
}

-(void)didEndProgressSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
    self.progressSheet = nil;
}

-(void)closeProgressSheet
{
    if (progressSheet != nil)
    {
        [[NSApplication sharedApplication] endSheet:[progressSheet window]];
    }
}

-(void)didClickViewSql:(id)sender
{
    [self viewSql];
}

-(void)viewSql
{
    @autoreleasepool
    {
        PGSchema *schema = [self getSchema];
        NSString *ddl = nil;
        
        if (editorAction == PGEditorAdd)
        {
            ddl = [schema createDdl];
        }
        else
        {
            
        }
        
        PGQueryWindowController *queryWindowController = [[PGQueryWindowController alloc] init];
        queryWindowController.initialQueryString = ddl;
        queryWindowController.autoExecuteQuery = NO;
        
        [queryWindowController useConnection:[self.connection copy]];
        [[queryWindowController window] makeKeyAndOrderFront:self];
    }
}

-(void)createSchema
{    
    [self openProgressSheet];
    [[PGAppDelegate sharedBackgroundQueue] addOperationWithBlock:^{
        PGCommand *command = [[PGCommand alloc] init];
        command.connection = self.connection;
        command.commandText = [[self getSchema] createDdl];
        [command execNonQueryWithCallback:^{
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self closeProgressSheet];
                [self close];
            }];
        } errorCallback:^(PGError *error) {
            
        }];

    }];
}

-(PGSchema*)getSchema
{
    PGSchema *schema = [[PGSchema alloc] init];
    schema.name = [self.nameTextField stringValue];
    schema.ownerName = [[self.ownerPopUpButton selectedItem] title];
    return schema;
}

@end
