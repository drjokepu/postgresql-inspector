//
//  PGCommand.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 13/12/2012.
//
//

#import "PGCommand.h"
#import "PGCommandExecutor.h"
#import "PGConnection.h"
#import <libpq-fe.h>

@implementation PGCommand
@synthesize commandText;
@synthesize connection;

-(void)execAsyncWithCallback:(void (^)(PGResult *))resultCallback
{
    PGCommandExecutor *executor = [[PGCommandExecutor alloc] initWithCommand:self];
    executor.rowByRow = NO;
    executor.onTuplesOk = resultCallback;
    [executor execute];
}

-(void)execAsyncWithCallback:(void (^)(PGResult *))resultCallback noMoreResultsCallback:(void (^)(void))noMoreResultsCallback errorCallback:(void (^)(PGError *))errorCallback
{
    PGCommandExecutor *executor = [[PGCommandExecutor alloc] initWithCommand:self];
    executor.rowByRow = NO;
    executor.onTuplesOk = resultCallback;
    executor.onNoMoreResults = noMoreResultsCallback;
    [executor execute];
}

@end


