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
@property (strong) IBOutlet NSTableView *columnsTableView;
@property (strong) IBOutlet NSButton *removeColumnButton;
@property (strong) IBOutlet NSPopUpButton *columnActionsPopUpButton;
@property (strong) IBOutlet NSButton *columnSpaceButton;
@property (strong) IBOutlet NSMenuItem *columnMoveUpMenuItem;
@property (strong) IBOutlet NSMenuItem *columnMoveDownMenuItem;

-(void)useConnection:(PGConnection *)theConnection;

-(IBAction)didClickCancel:(id)sender;
-(IBAction)didClickAddColumn:(id)sender;
-(IBAction)didClickRemoveColumn:(id)sender;
-(IBAction)didClickEditColumn:(id)sender;
-(IBAction)didClickColumnMoveUp:(id)sender;
-(IBAction)didClickColumnMoveDown:(id)sender;

@end
