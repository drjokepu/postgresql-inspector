//
//  PGCreateTableWindowController.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 04/02/2013.
//
//

#import <Cocoa/Cocoa.h>
#import "PGConnectionDelegate.h"
#import "PGSelfRetainingWindowController.h"

@class PGConnection;

@interface PGCreateTableWindowController : PGSelfRetainingWindowController <PGConnectionDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, strong) NSString *initialSchemaName;
@property (nonatomic, strong) NSArray *initialSchemaNameList;
@property (strong) IBOutlet NSTextField *tableNameTextField;
@property (strong) IBOutlet NSComboBox *schemaComboBox;
@property (strong) IBOutlet NSView *columnsView;
@property (strong) IBOutlet NSTableView *columnsTableView;
@property (strong) IBOutlet NSView *constraintsView;
@property (strong) IBOutlet NSTableView *constraintsTableView;

-(void)useConnection:(PGConnection *)theConnection;

-(IBAction)didClickCancel:(id)sender;

@end
