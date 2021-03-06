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
@property (nonatomic, assign) NSUInteger previousTextLength;
@property (nonatomic, strong) NSFont *textEditorFont;
@property (nonatomic, strong) NSFont *cellFont;
@property (strong) IBOutlet NSTextField *commandStatusLabel;

@end

@implementation PGQueryWindowController
@synthesize autoExecuteQuery, connection, connectionIsOpen, initialQueryString, queryTextView, queryInProgress, completionInProgress, previousTextLength;

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
    self.textEditorFont = [NSFont fontWithName:@"Menlo" size:12];
    self.cellFont = [NSFont fontWithName:@"Menlo" size:11];
    [queryTextView setFont:self.textEditorFont];
    
    if ([self.initialQueryString length] > 0)
    {
        [self highlightSyntax];
        
        if (autoExecuteQuery)
        {
            [self executeQuery:self];
        }
    }
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
    
    [self.queryTextView setEditable:NO];
    [self.resultsTableView setEnabled:NO];
    [self.resultSelectorPopUpButton setEnabled:NO];

    PGCommand *command = [[PGCommand alloc] init];
    command.connection = connection;
    command.commandText = [[NSString alloc] initWithString:commandText];
    self.queryInProgress = YES;
    
    [command execAsyncWithCallback:^(PGResult *result){
        [self addResult:result];
        [self.resultsTableView setEnabled:YES];
        [self.resultSelectorPopUpButton setEnabled:YES];
    } noMoreResultsCallback:^
    {
        [self.queryTextView setEditable:YES];
        [self.resultsTableView setEnabled:YES];
        [self.resultSelectorPopUpButton setEnabled:YES];
        self.queryInProgress = NO;
        [[self window] update];
    } errorCallback:^(PGError *error) {
        [self.queryTextView setEditable:YES];
        [self.resultsTableView setEnabled:YES];
        [self.resultSelectorPopUpButton setEnabled:YES];
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
        NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:[[NSString alloc] initWithFormat:@"%lu", i]];
        
        [[column headerCell] setStringValue:[[NSString alloc] initWithString:columnName]];
        
        // formatters
        if ((PGType)[result.columnTypes[i] integerValue] == PGTypeUuid)
        {
            [[column dataCell] setFormatter: [[PGUUIDFormatter alloc] init]];
        }
        [[column dataCell] setFont:self.cellFont];
        
        [self.resultsTableView addTableColumn:column];
    }
    
    [self.commandStatusLabel setStringValue:result.commandStatus];
    [self.resultsTableView reloadData];
    [self resizeColumns];
}

-(void)resizeColumns
{
    const NSTableView *tableView = self.resultsTableView;
    
    const NSInteger columnCount = [tableView numberOfColumns];
    const NSInteger rowCount = [tableView numberOfRows];
    
    for (NSInteger column = 0; column < columnCount; column++)
    {
        CGFloat maxWidth = 0.0;
        
        for (NSInteger row = 0; row < rowCount; row++)
        {
            const NSCell *cell = [tableView preparedCellAtColumn:column row:row];
            const CGFloat cellWidth = [cell cellSize].width + 20.0;
            maxWidth = MAX(maxWidth, cellWidth);
        }
        
        const CGFloat headerCellWidth = [[[[tableView tableColumns] objectAtIndex:column] headerCell] cellSize].width;
        
        maxWidth = MAX(maxWidth, headerCellWidth);
        maxWidth = MIN(maxWidth, 350.0); // max width is 350 pixels
        
        [[[tableView tableColumns] objectAtIndex:column] setWidth:maxWidth];
    }
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
        PGSQLParsingResult *result = [PGSQLParser parse:self.queryTextView.string cursorPosition:[queryTextView selectedRange].location];
        if (!self.completionInProgress)
        {
            self.completions = nil;
            // only autocomplete when text was added
            if (self.previousTextLength < [[queryTextView string] length] - [queryTextView selectedRange].length)
            {
                [self expandPossibleTokens:result.possibleTokens];
            }     
        }
        [self highlightSyntaxWithParsingResult:result];
        self.previousTextLength = [[queryTextView string] length] - [queryTextView selectedRange].length;
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

-(void)highlightSyntax
{
    [self highlightSyntaxWithParsingResult:[PGSQLParser parse:self.queryTextView.string cursorPosition:[queryTextView selectedRange].location]];
}

-(void)highlightSyntaxWithParsingResult:(PGSQLParsingResult*)result
{
    if (result == nil) return;
    [queryTextView setTextColor:[NSColor textColor]];
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
        case sql_token_type_operator:
            return [NSColor blueColor];
        case sql_token_type_comment:
            return [NSColor lightGrayColor];
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
    @autoreleasepool
    {
        const PGResult *result = [self selectedResult];
        const id value = [result rows][row][column];
        return [self formatCellObject:value];
    }
}

-(id)formatCellObject:(id)cellValue
{
    if ([cellValue isKindOfClass:[NSArray class]])
    {
        return [NSString stringWithFormat:@"{%@}", [((NSArray*)cellValue) componentsJoinedByString:@", "]];
    }
    else
    {
        return cellValue;
    }
}

-(PGResult*)selectedResult
{
    if ([self.queryResults count] == 0)
        return nil;
    else
        return self.queryResults[[self.resultSelectorPopUpButton indexOfSelectedItem]];
}

@end
