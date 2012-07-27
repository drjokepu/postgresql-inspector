//
//  PGDatabaseWindowController.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 30/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PGDatabaseDelegate.h"

@class PGConnection, PGDatabase, PGTable, PGSchemaObject;

@interface PGDatabaseWindowController : NSWindowController <NSWindowDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate, PGDatabaseDelegate, NSTableViewDataSource>

@property (nonatomic, strong) PGConnection *connection;
@property (nonatomic, strong) PGDatabase *database;
@property (nonatomic, strong) PGSchemaObject *selectedSchemaObject;
@property (nonatomic, readonly) PGTable *selectedTable;

@property (strong) IBOutlet NSOutlineView *outlineView;
@property (strong) IBOutlet NSPopUpButton *schemaPopUpButton;
@property (strong) IBOutlet NSMenu *schemaMenu;
@property (strong) IBOutlet NSTableView *tableColumnsTableView;



-(IBAction)didchangeSchemaPopUpButtonValue:(id)sender;

@end
