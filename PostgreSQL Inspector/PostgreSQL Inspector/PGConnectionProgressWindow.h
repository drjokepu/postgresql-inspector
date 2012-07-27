//
//  ConnectionProgressWindow.h
//  Database Inspector
//
//  Created by Tamas Czinege on 25/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PGConnectionEntry;

@interface PGConnectionProgressWindow : NSWindowController

@property (strong) IBOutlet NSTextField *connectingTextField;
@property (strong) IBOutlet NSProgressIndicator *progressIndicator;
@property (strong) PGConnectionEntry *connectionEntry;

@end
