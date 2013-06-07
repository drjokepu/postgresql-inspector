//
//  PGSelfRetainingWindowController.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 04/02/2013.
//
//

#import <Cocoa/Cocoa.h>

@class PGProgressSheet;

@interface PGSelfRetainingWindowController : NSWindowController
@property (nonatomic, strong) PGProgressSheet *progressSheet;

-(void)showError:(NSString *)message informativeText:(NSString*)informativeText callback:(void (^)(void))endCallback;

@end
