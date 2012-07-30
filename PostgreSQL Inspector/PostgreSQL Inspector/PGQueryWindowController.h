//
//  PGQueryWindowController.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 07/30/2012.
//
//

#import <Cocoa/Cocoa.h>

@class PGConnection;

@interface PGQueryWindowController : NSWindowController

@property (nonatomic, strong) PGConnection *connection;

@end
