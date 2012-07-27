//
//  PGConnectionManager.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 29/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

void PGConnectionManagerInitMutexes(void);
void PGConnectionManagerDestroyMutexes(void);

@class PGConnectionController;

@interface PGConnectionManager : NSObject

-(void)addConnectionController:(PGConnectionController*)theController;
-(void)removeConnectionController:(PGConnectionController*)theController;
-(void)removeConnectionController:(PGConnectionController*)theController delayed:(BOOL)delayed;

+(PGConnectionManager*)sharedManager;

@end
