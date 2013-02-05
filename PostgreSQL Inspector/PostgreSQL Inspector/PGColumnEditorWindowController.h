//
//  PGColumnEditorWindowController.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 05/02/2013.
//
//

#import <Cocoa/Cocoa.h>
#import "PGColumnEditorAction.h"

@interface PGColumnEditorWindowController : NSWindowController <NSTextFieldDelegate>

@property (nonatomic, assign) PGColumnEditorAction columnEditorAction;
@property (strong) IBOutlet NSTextField *columnNameTextField;
@property (strong) IBOutlet NSComboBox *columnTypeComboBox;
@property (strong) IBOutlet NSTextField *columnLengthTextField;
@property (strong) IBOutlet NSTextField *columnPrecisionTextField;
@property (strong) IBOutlet NSButton *actionButton;

-(IBAction)didClickCancel:(id)sender;
-(IBAction)didClickAction:(id)sender;

@end
