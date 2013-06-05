//
//  PGForeignKeyEditorWindowController.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 28/03/2013.
//
//

#import <Cocoa/Cocoa.h>
#import "PGEditorAction.h"

@class PGConnection, PGConstraint, PGDatabase;
@interface PGForeignKeyEditorWindowController : NSWindowController <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic, assign) PGEditorAction columnEditorAction;
@property (nonatomic, strong) NSArray *availableColumns;

-(IBAction)didClickCancel:(id)sender;
-(IBAction)didClickAction:(id)sender;
-(IBAction)didSelectTargetTable:(id)sender;

-(PGConstraint*)getConstraint;
-(void)useConstraint:(PGConstraint*)constraint database:(PGDatabase*)theDatabase connection:(PGConnection *)theConnection tableColumns:(NSArray*)theTableColumns;

@end
