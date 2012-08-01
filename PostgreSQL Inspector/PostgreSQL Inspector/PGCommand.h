//
//  PGCommand.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 30/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PGCommandDelegate.h"

void PGCommandInitOperationQueue(void);
void PGCommandDestroyOperationQueue(void);

@class PGConnection, PGDataReader, PGError, PGResult;

@interface PGCommand : NSObject

@property (nonatomic, strong) PGConnection *connection;
@property (nonatomic, copy) NSString *commandText;
@property (nonatomic, weak) id<PGCommandDelegate> delegate;
@property (nonatomic, strong) id tag;
@property (nonatomic, readonly) NSArray *parameters;

-(id)initWithConnection:(PGConnection*)theConnection commandText:(const NSString*)theCommandText;

-(void)addParameter:(id)parameter;

-(void)executeAsync;
-(void)executeAsyncWithFinishedCallback:(void(^)())finishedCallback;
-(void)executeAsyncWithResultCallback:(void(^)(PGResult* r))resultCallback;
-(void)executeAsyncWithResultCallback:(void(^)(PGResult* r))resultCallback noMoreResultsCallback:(void(^)())noMoreResultsCallback;
-(void)executeAsyncWithResultCallback:(void(^)(PGResult* r))resultCallback noMoreResultsCallback:(void(^)())noMoreResultsCallback errorCallback:(void(^)(PGError *error))errorCallback;

-(NSArray*)execute;

@end
