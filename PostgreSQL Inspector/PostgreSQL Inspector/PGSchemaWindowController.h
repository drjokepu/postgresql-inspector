//
//  PGSchemaWindowController.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 06/06/2013.
//
//

#import "PGSelfRetainingWindowController.h"
#import "PGConnectionDelegate.h"
#import "PGEditorAction.h"

@class PGConnection, PGDatabase;
@interface PGSchemaWindowController : PGSelfRetainingWindowController <PGConnectionDelegate>

@property (nonatomic, assign) PGEditorAction editorAction;

-(void)useConnection:(PGConnection *)theConnection database:(PGDatabase *)theDatabase;

@end
