//
//  PGUniqueKeyEditorWindowController.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 10/02/2013.
//
//

#import <Cocoa/Cocoa.h>
#import "PGEditorAction.h"

@class PGConstraint;
@interface PGUniqueKeyEditorWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, assign) PGEditorAction constraintEditorAction;
@property (nonatomic, assign) BOOL isPrimaryKey;
@property (nonatomic, strong) NSArray *availableColumns;

-(IBAction)didClickCancel:(id)sender;
-(IBAction)didClickAction:(id)sender;

-(PGConstraint*)getConstraint;
-(void)updateConstraint;
-(void)useConstraint:(PGConstraint*)constraint;

@end
