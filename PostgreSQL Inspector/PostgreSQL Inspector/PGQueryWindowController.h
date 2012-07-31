//
//  PGQueryWindowController.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 07/30/2012.
//
//

#import <Cocoa/Cocoa.h>

@class PGConnection, PGDatabaseWindowController;

@interface PGQueryWindowController : NSWindowController

@property (nonatomic, strong) NSString *initialQueryString;
@property (nonatomic, weak) PGDatabaseWindowController *parentWindowController;
@property (strong) IBOutlet NSTextView *queryTextView;

-(void)useConnection:(PGConnection *)theConnection;

-(IBAction)executeQuery:(id)sender;

@end
