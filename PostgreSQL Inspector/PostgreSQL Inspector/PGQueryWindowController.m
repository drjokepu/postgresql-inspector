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

static const NSInteger executeQueryTag = 4001;

@interface PGQueryWindowController ()

@property (nonatomic, strong) PGConnection *connection;
@property (nonatomic, assign) BOOL connectionIsOpen;
@property (nonatomic, assign) BOOL queryInProgress;

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
    [self performSelectorInBackground:@selector(openConnection:) withObject:theConnection];
}

-(void)openConnection:(PGConnection *)theConnection
{
    [theConnection open];
    [self performSelectorOnMainThread:@selector(didOpenConnection) withObject:nil waitUntilDone:NO];
}

-(void)didOpenConnection
{
    self.connectionIsOpen = YES;
    [[self window] update];
}

-(void)executeQuery:(id)sender
{
    const NSString *commandText = self.queryTextView.string;
    if ([commandText length] == 0) return;
    
    PGCommand *command = [[PGCommand alloc] initWithConnection:connection commandText:commandText];
    self.queryInProgress = YES;
    
    [command executeAsyncWithResultCallback:^(PGResult *r) {
        [[self window] update];
    } noMoreResultsCallback:^{
        self.queryInProgress = false;
        [[self window] update];
    } errorCallback:^(PGError *error) {
        self.queryInProgress = false;
        [self.queryTextView setSpellingState:NSSpellingStateSpellingFlag range:[self findErrorRange:error.errorPosition]];
        [self showError:error];
        [[self window] update];
    }];
    
    [[self window] update];
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

@end
