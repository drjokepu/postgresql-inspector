//
//  PGAuthWindowControllerDelegate.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 29/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PGAuthWindowController;

@protocol PGAuthWindowControllerDelegate <NSObject>

-(void)authWindowControllerCancel:(PGAuthWindowController*)theAuthWindowController;
-(void)authWindowControllerConnect:(PGAuthWindowController*)theAuthWindowController;

@end
