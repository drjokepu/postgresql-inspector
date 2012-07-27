//
//  PGDatabaseManager.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 30/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import <Foundation/Foundation.h>

void PGDatabaseManagerInitMutexes(void);
void PGDatabaseManagerDestroyMutexes(void);

@class PGDatabaseWindowController;

@interface PGDatabaseManager : NSObject

-(void)addDatabaseWindowController:(PGDatabaseWindowController*)controller;
-(void)removeDatabaseWindowController:(PGDatabaseWindowController*)controller;
-(void)removeDatabaseWindowController:(PGDatabaseWindowController*)theController delayed:(BOOL)delayed;

+(PGDatabaseManager*)sharedManager;

@end
