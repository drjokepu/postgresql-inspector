//
//  PGColumnEditorWindowController.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 05/02/2013.
//
//

#import <Cocoa/Cocoa.h>
#import "PGColumnEditorAction.h"

@class PGRelationColumn;

@interface PGColumnEditorWindowController : NSWindowController <NSTextFieldDelegate>

@property (nonatomic, assign) PGColumnEditorAction columnEditorAction;
@property (strong) IBOutlet NSTextField *columnNameTextField;
@property (strong) IBOutlet NSComboBox *columnTypeComboBox;
@property (strong) IBOutlet NSTextField *columnLengthTextField;
@property (strong) IBOutlet NSTextField *columnPrecisionTextField;
@property (strong) IBOutlet NSTextField *columnDefaultValueTextField;
@property (strong) IBOutlet NSButton *columnNotNullCheckBox;
@property (strong) IBOutlet NSButton *actionButton;

-(IBAction)didClickCancel:(id)sender;
-(IBAction)didClickAction:(id)sender;

-(void)useColumn:(PGRelationColumn*)column;
-(PGRelationColumn*)getColumn;

@end
