//
//  PGQueryWindowController.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 07/30/2012.
//
//

#import "PGQueryWindowController.h"
#import "PGConnection.h"

@interface PGQueryWindowController ()
@property (nonatomic, strong) PGConnection *connection;

@end

@implementation PGQueryWindowController
@synthesize connection, initialQueryString, queryTextView;

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
    
}

@end
