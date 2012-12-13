//
//  PGConnection.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 29/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PGConnectionDelegate.h"
#import <libpq-fe.h>

@class PGConnectionEntry;

@interface PGConnection : NSObject

@property (nonatomic, strong) PGConnectionEntry *connectionEntry;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, weak) id<PGConnectionDelegate> delegate;

@property (nonatomic, readonly) PGconn *connection;
@property (nonatomic, readonly) BOOL locked;

-(id)initWithConnectionEntry:(PGConnectionEntry*)theConnectionEntry;
-(void)openAsync;
-(void)open;
-(void)close;
-(PGConnection*)copy;
-(void)lock;
-(void)unlock;

@end
