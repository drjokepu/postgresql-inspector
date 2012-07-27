//
//  PGAppDelegate.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 23/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import <Cocoa/Cocoa.h>

void PGAppDelegateInitSharedBackgroundQueue(void);
void PGAppDelegateDestroySharedBackgroundQueue(void);

@interface PGAppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;

-(IBAction)connectToDatabase:(id)sender;
+(void)connectionWindowWillClose;
+(NSOperationQueue*)sharedBackgroundQueue;

@end
