//
//  PGDatabaseWindowController.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 30/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PGConstraintType.h"
#import "PGDatabaseDelegate.h"

@class PGConnection, PGConstraint, PGDatabase, PGTable, PGSchemaObject, PGQueryWindowController;

@interface PGDatabaseWindowController : NSWindowController <NSWindowDelegate, NSOutlineViewDataSource, NSOutlineViewDelegate, PGDatabaseDelegate, NSTableViewDataSource>

@property (nonatomic, strong) PGConnection *connection;
@property (nonatomic, strong) PGDatabase *database;
@property (nonatomic, strong) PGSchemaObject *selectedSchemaObject;
@property (nonatomic, readonly) PGTable *selectedTable;

@property (strong) IBOutlet NSOutlineView *outlineView;
@property (strong) IBOutlet NSPopUpButton *schemaPopUpButton;
@property (strong) IBOutlet NSMenu *schemaMenu;
@property (strong) IBOutlet NSTableView *tableColumnsTableView;
@property (strong) IBOutlet NSTableView *constraintsTableView;

-(IBAction)didChangeSchemaPopUpButtonValue:(id)sender;
-(IBAction)queryDatabase:(id)sender;
-(IBAction)querySelectedRelation:(id)sender;
-(IBAction)createSchema:(id)sender;
-(IBAction)createTable:(id)sender;

+(NSImage*)imageForConstraintType:(PGConstraintType)constraintType;

@end
