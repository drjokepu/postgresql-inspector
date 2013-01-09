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
#import "PGOid.h"
#import "PGResult.h"
#import "PGSQLParser.h"
#import "PGSQLParsingResult.h"
#import "PGSQLToken.h"
#import "PGType.h"
#import "PGUUIDFormatter.h"

static const NSInteger executeQueryTag = 4001;

@interface PGQueryWindowController ()

@property (nonatomic, strong) PGConnection *connection;
@property (nonatomic, assign) BOOL connectionIsOpen;
@property (nonatomic, assign) BOOL queryInProgress;
@property (nonatomic, strong) NSMutableArray *queryResults;
@property (nonatomic, strong) NSArray *completions;
@property (nonatomic, assign) BOOL completionInProgress;

@end

@implementation PGQueryWindowController
@synthesize connection, connectionIsOpen, initialQueryString, queryTextView, queryInProgress, completionInProgress;

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
        
        [[column headerCell] setStringValue:[[NSString alloc] initWithString:columnName]];
        
        // formatters
        if (((PGOid*)result.columnTypes[i]).type == PGTypeUuid)
        {
            [[column dataCell] setFormatter: [[PGUUIDFormatter alloc] init]];
        }
        
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
    @autoreleasepool
    {
        if (!completionInProgress)
        {
            PGSQLParsingResult *result = [PGSQLParser parse:self.queryTextView.string cursorPosition:[queryTextView selectedRange].location];
            self.completions = nil;
            [self expandPossibleTokens:result.possibleTokens];
            [self highlightSyntaxWithParsingResult:result];
        }
    }
}

-(void)expandPossibleTokens:(NSArray*)possibleTokens
{
    NSMutableArray *expandedTokens = [[NSMutableArray alloc] init];
    for (PGSQLToken *token in possibleTokens)
    {
        [expandedTokens addObjectsFromArray:[token expandToCompletions]];
    }
    
    expandedTokens = [[NSMutableArray alloc] initWithArray:[[[NSSet alloc] initWithArray:expandedTokens] allObjects]];
    [expandedTokens sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [((NSString*)obj1) compare:obj2];
    }];
    self.completions = expandedTokens;
    self.completionInProgress = YES;
    [self.queryTextView complete:self];
    self.completionInProgress = NO;
}

-(NSArray *)textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index
{
    NSString *prefix = [queryTextView.string substringWithRange:charRange];
    return [self.completions filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject hasPrefix:prefix];
    }]];
}

-(void)highlightSyntaxWithParsingResult:(PGSQLParsingResult*)result
{
    [queryTextView setTextColor:[NSColor textColor]];
    if (result == nil) return;
    for (PGSQLToken *token in result.tokens)
    {
        [queryTextView setTextColor:[PGQueryWindowController tokenColor:[token tokenType]] range:NSMakeRange(token.start, token.length)];
    }
}

+(NSColor*)tokenColor:(enum sql_token_type)tokenType
{
    switch (tokenType)
    {
        case sql_token_type_keyword:
            return [NSColor colorWithCalibratedRed:0.667 green:0.051 blue:0.569 alpha:1.000];
        case sql_token_type_identifier:
            return [NSColor colorWithCalibratedRed:0.247 green:0.431 blue:0.455 alpha:1.000];
        case sql_token_type_literal:
            return [NSColor colorWithCalibratedRed:0.769 green:0.102 blue:0.086 alpha:1.000];
        default:
            return [NSColor textColor];
    }
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
