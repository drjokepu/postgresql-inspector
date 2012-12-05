//
//  PGConnection.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 29/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libpq-fe.h>
#import "PGConnectionDelegate.h"

@class PGConnectionEntry;

@interface PGConnection : NSObject

@property (nonatomic, strong) PGConnectionEntry *connectionEntry;
@property (nonatomic, weak) id<PGConnectionDelegate> delegate;

@property (nonatomic, readonly) PGconn *connection;

-(id)initWithConnectionEntry:(PGConnectionEntry*)theConnectionEntry;
-(void)open;
-(void)close;
-(PGConnection*)copy;

@end
