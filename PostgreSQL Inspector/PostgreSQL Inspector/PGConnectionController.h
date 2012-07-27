//
//  PGConnectionController.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 25/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PGConnectionDelegate.h"
#import "PGAuthWindowControllerDelegate.h"

@class PGConnectionEntry, PGConnection;

@interface PGConnectionController : NSObject <PGConnectionDelegate, PGAuthWindowControllerDelegate>

@property (nonatomic, strong) PGConnectionEntry *connectionEntry;
@property (nonatomic, strong) PGConnection *connection;

-(id)initWithConnectionEntry:(PGConnectionEntry*)theConnectionEntry;

-(void)connectAsync;

@end
