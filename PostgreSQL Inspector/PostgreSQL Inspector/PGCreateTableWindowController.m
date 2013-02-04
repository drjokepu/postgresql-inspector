//
//  PGCreateTableWindowController.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 04/02/2013.
//
//

#import "PGCreateTableWindowController.h"
#import "PGConnection.h"

@interface PGCreateTableWindowController ()
@property (nonatomic, strong) PGConnection *connection;
@property (nonatomic, assign) BOOL connectionIsOpen;
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

@end
