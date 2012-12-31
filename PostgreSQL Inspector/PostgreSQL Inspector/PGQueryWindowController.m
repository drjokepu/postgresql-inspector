//
//  PGQueryWindowController.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 07/30/2012.
//
//

#import "PGQueryWindowController.h"
#import "PGCommand.h"
#import "PGConnection.h"
#import "PGError.h"
#import "PGResult.h"
#import "PGSQLParser.h"

static const NSInteger executeQueryTag = 4001;

@interface PGQueryWindowController ()

@property (nonatomic, strong) PGConnection *connection;
@property (nonatomic, assign) BOOL connectionIsOpen;
@property (nonatomic, assign) BOOL queryInProgress;
@property (nonatomic, strong) NSMutableArray *queryResults;

@end

@implementation PGQueryWindowController
@synthesize connection, connectionIsOpen, initialQueryString, queryTextView, queryInProgress;

-(NSString *)windowNibName
{
    return @"PGQueryWindowController";
}

-(void)windowDidLoad
{
    [super windowDidLoad];
    if (self.initialQueryString == nil) self.initialQueryString = @"";
    self.queryResults = [[NSMutableArray alloc] init];
    [queryTextView setString:initialQueryString];
    [queryTextView setFont:[NSFont fontWithName:@"Menlo" size:12]];
}

-(void)dealloc
{
    if (connection != nil) [connection close];
}

-(BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    return [self validateItem:menuItem.tag];
}

-(BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    return [self validateItem:theItem.tag];
}

-(BOOL)validateItem:(NSInteger)tag
{
    switch (tag)
    {
        case executeQueryTag:
            return connectionIsOpen && !queryInProgress;
        default:
            return YES;
    }
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

-(void)executeQuery:(id)sender
{
    if (connection == nil)
    {
        fprintf(stderr, "executeQuery failed: connection pointer is nil\n");
        return;
    }
    
    [self removeAllResults];
    NSString *commandText = self.queryTextView.string;
    if ([commandText length] == 0) return;

    PGCommand *command = [[PGCommand alloc] init];
    command.connection = connection;
    command.commandText = [[NSString alloc] initWithString:commandText];
    self.queryInProgress = YES;
    
    [command execAsyncWithCallback:^(PGResult *result){
        [self addResult:result];
    } noMoreResultsCallback:^
    {
        self.queryInProgress = NO;
        [[self window] update];
    } errorCallback:^(PGError *error) {
        self.queryInProgress = NO;
        [self.queryTextView setSpellingState:NSSpellingStateSpellingFlag
                                       range:[self findErrorRange:error.errorPosition]];
        [self showError:error];
        [[self window] update];
    }];
    
    [[self window] update];
}

-(void)removeAllResults
{
    [self.queryResults removeAllObjects];
    [self clearResultSelectorMenu];
    [self removeAllColumnsFromResultsTable];
}

-(void)removeAllColumnsFromResultsTable
{
    while([[self.resultsTableView tableColumns] count] > 0)
    {
        [self.resultsTableView removeTableColumn:[[self.resultsTableView tableColumns] lastObject]];
    }
}

-(void)clearResultSelectorMenu
{
    [self.resultSelectorPopUpButton.menu removeAllItems];
}

-(void)addResult:(PGResult*)result
{
    BOOL isFirst = [self.queryResults count] == 0;
    
    [self.queryResults addObject:result];
    
    // updating existing menu items
    const NSUInteger index = result.index;
    for (NSUInteger i = 0; i < index; i++)
    {
        NSMenuItem *menuItem = [self.resultSelectorPopUpButton itemAtIndex:i];
        [menuItem setTitle:[PGQueryWindowController menuItemTitleForResultAt:i of:(index + 1)]];
    }
    [self.resultSelectorPopUpButton addItemWithTitle:[PGQueryWindowController menuItemTitleForResultAt:index
                                                                                                    of:(index + 1)]];
    
    [[self window] update];
    if (isFirst)
    {
        [self.resultSelectorPopUpButton selectItemAtIndex:0];
        [self presentResult];
    }
}

+(NSString*)menuItemTitleForResultAt:(NSUInteger)index of:(NSUInteger)max
{
    return [NSString stringWithFormat:@"Result %lu of %lu", (index + 1), max];
}

-(void)presentResult
{
    [self removeAllColumnsFromResultsTable];
    PGResult *result = [self selectedResult];
    for (NSUInteger i = 0; i < [result.columnNames count]; i++)
    {
        NSString *columnName = result.columnNames[i];
        NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:[NSString stringWithFormat:@"%lu", i]];
        
//        NSCell *dataCell = [[NSCell alloc] init];
//        [dataCell setEditable:YES];
//        [column setDataCell:dataCell];
        [[column headerCell] setStringValue:[[NSString alloc] initWithString:columnName]];
        [self.resultsTableView addTableColumn:column];
    }
    
    [self.resultsTableView reloadData];
}

-(void)showError:(PGError *)error
{
    NSString *capitalizedErrorMessage = [error.sqlErrorMessage length] > 0 ? [[NSString alloc] initWithFormat:@"%@.", [error.sqlErrorMessage stringByReplacingCharactersInRange:NSMakeRange(0,1)withString:[[error.sqlErrorMessage substringToIndex:1] capitalizedString]]] : @"";
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:@"Error in query"];
    [alert setInformativeText:capitalizedErrorMessage];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(errorSheetClosed:returnCode:contextInfo:) contextInfo:nil];
}
     
-(void)errorSheetClosed:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    
}

-(NSRange)findErrorRange:(NSUInteger)errorPosition
{
    const NSString *commandText = self.queryTextView.string;
    const NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    
    NSUInteger length = 0;
    for (NSUInteger cursor = errorPosition; cursor < [commandText length]; cursor++, length++)
    {
        if ([set characterIsMember:[commandText characterAtIndex:cursor]])
            break;
    }
    
    return NSMakeRange(errorPosition, MAX(length, 1));
}

-(void)textDidChange:(NSNotification *)notification
{
    if ([notification object] == self.queryTextView)
    {
        [self queryTextChanged];
    }
}

-(void)queryTextChanged
{
    [PGSQLParser parse:self.queryTextView.string];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == self.resultsTableView)
        return [self numberOfRowsInResult];
    else
        return 0;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return [self resultValueForTableColumn:[tableColumn.identifier integerValue] row:row];
}

-(NSInteger)numberOfRowsInResult
{
    return [[self selectedResult] rowCount];
}

-(id)resultValueForTableColumn:(NSInteger)column row:(NSInteger)row
{
    const PGResult *result = [self selectedResult];
    const id value = [result rows][row][column];
    return value;
}

-(PGResult*)selectedResult
{
    if ([self.queryResults count] == 0)
        return nil;
    else
        return self.queryResults[[self.resultSelectorPopUpButton indexOfSelectedItem]];
}

@end
