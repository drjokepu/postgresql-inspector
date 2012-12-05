//
//  PGCommand.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 30/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import "PGCommand.h"
#import <libpq-fe.h>
#import "PGConnection.h"
#import "PGDataReader.h"
#import "PGError+Internal.h"
#import "PGResult.h"
#import "PGOid.h"

static NSOperationQueue *sharedCommandOperationQueue = nil;

@interface PGCommand()

-(void)executeBackground;
-(void)dispatchReceivedResultOnMainThread:(PGDataReader*)reader;
-(void)dispatchNoMoreResults;

-(void)bindParametersToQuery:(px_query*)query;

@property (nonatomic, strong) NSMutableArray *mutableParameters;

@end

@implementation PGCommand
@synthesize connection, commandText, delegate, tag, mutableParameters;

-(id)initWithConnection:(PGConnection *)theConnection commandText:(const NSString *)theCommandText
{
    if ((self = [super init]))
    {
        self.connection = theConnection;
        self.commandText = [theCommandText copy];
        self.mutableParameters = [[NSMutableArray alloc] init];
    }
    return self;
}

-(NSArray *)parameters
{
    return mutableParameters;
}

-(void)addParameter:(id)parameter
{
    [mutableParameters addObject:parameter];
}

-(void)bindParametersToQuery:(px_query *)query
{
    for (id parameter in mutableParameters)
    {
        if ([parameter isKindOfClass:[NSString class]])
        {
            px_parameter *px_param = px_parameter_new_string([((NSString*)parameter) UTF8String]);
            px_query_add_parameter(query, px_param);
            px_parameter_delete(px_param);
        }
        else if ([parameter isKindOfClass:[PGOid class]])
        {
            px_parameter *px_param = px_parameter_new_oid(((PGOid*)parameter).value);
            px_query_add_parameter(query, px_param);
            px_parameter_delete(px_param);
        }
        else
        {
            NSLog(@"unrecognized parameter type");
        }
    }
}

-(void)executeAsync
{
    [self performSelectorInBackground:@selector(executeBackground) withObject:nil];
}

-(void)executeBackground
{
    const char *commandTextC = [commandText cStringUsingEncoding:NSUTF8StringEncoding];
    
    px_query *query = px_query_new(commandTextC, connection.connection);
    [self bindParametersToQuery:query];
    
    px_result_list *resultList = px_query_execute(query);
    px_query_delete(query);
    
    if (resultList == NULL)
    {
        NSLog(@"px_query_execute failed:\n%s", px_error_get_message(px_connection_get_last_error(connection.connection)));
    }
    else
    {
        for (unsigned int i = 0; i < resultList->count; i++)
        {
            px_result *pxResult = resultList->results[i];
            @autoreleasepool
            {
                PGDataReader *reader = [[PGDataReader alloc] initWithPXResult:pxResult];
                reader.sequenceNumber = i;
                [self performSelectorOnMainThread:@selector(dispatchReceivedResultOnMainThread:)
                                       withObject:reader
                                    waitUntilDone:NO];
            }
        }
        [self performSelectorOnMainThread:@selector(dispatchNoMoreResults) withObject:nil waitUntilDone:NO];
    }
    
    px_result_list_delete(resultList, true);
}

-(void)executeAsyncWithFinishedCallback:(void (^)())finishedCallback
{
    [self executeAsyncWithResultCallback:nil noMoreResultsCallback:finishedCallback];
}

-(void)executeAsyncWithResultCallback:(void (^)(PGResult *))resultCallback
{
    [self executeAsyncWithResultCallback:resultCallback noMoreResultsCallback:nil];
}

-(void)executeAsyncWithResultCallback:(void (^)(PGResult *))resultCallback noMoreResultsCallback:(void (^)())noMoreResultsCallback
{
    [self executeAsyncWithResultCallback:resultCallback noMoreResultsCallback:noMoreResultsCallback errorCallback:nil];
}

-(void)executeAsyncWithResultCallback:(void (^)(PGResult *))resultCallback noMoreResultsCallback:(void (^)())noMoreResultsCallback errorCallback:(void (^)(PGError *))errorCallback
{
    [sharedCommandOperationQueue addOperationWithBlock:^{
        const char *commandTextC = [commandText cStringUsingEncoding:NSUTF8StringEncoding];
        
        px_query *query = px_query_new(commandTextC, connection.connection);
        [self bindParametersToQuery:query];
        
        px_result_list *resultList = px_query_execute(query);
        px_query_delete(query);
        
        if (resultList == NULL || resultList->count == 0)
        {
            if (errorCallback == nil)
            {
                NSLog(@"px_query_execute failed");
            }
            else
            {
                PGError *pgError = [[PGError alloc] initWithPxError:px_connection_get_last_error(connection.connection)];
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    errorCallback(pgError);
                }];
            }
        }
        else
        {
            for (unsigned int i = 0; i < resultList->count; i++)
            {
                px_result *pxResult = resultList->results[i];
                @autoreleasepool
                {
                    if (resultCallback != nil)
                    {
                        PGDataReader *reader = [[PGDataReader alloc] initWithPXResult:pxResult];
                        reader.sequenceNumber = i;
                        PGResult *result = [reader result];
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            resultCallback(result);
                        }];
                    }
                }
            }
            
            if (noMoreResultsCallback != nil)
            {
                [[NSOperationQueue mainQueue] addOperationWithBlock:noMoreResultsCallback];
            }
            
            px_result_list_delete(resultList, true);
        }
    }];
}

-(void)dispatchReceivedResultOnMainThread:(PGDataReader *)reader
{
    if (delegate != nil)
    {
        [delegate command:self receivedResult:reader];
    }
}

-(void)dispatchNoMoreResults
{
    if (delegate != nil && [delegate respondsToSelector:@selector(commandHasNoMoreResults:)])
    {
        [delegate commandHasNoMoreResults:self];
    }
}

-(NSArray *)execute
{
    const char *commandTextC = [commandText cStringUsingEncoding:NSUTF8StringEncoding];
    
    px_query *query = px_query_new(commandTextC, connection.connection);
    [self bindParametersToQuery:query];
    
    px_result_list *resultList = px_query_execute(query);
    px_query_delete(query);
    
    if (px_connection_get_last_error(connection.connection) != NULL)
    {
        NSLog(@"%s", px_error_get_message(px_connection_get_last_error(connection.connection)));
    }
    
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:resultList->count];
    for (NSUInteger i = 0; i < resultList->count; i++)
    {
        @autoreleasepool
        {
            PGDataReader *reader = [[PGDataReader alloc] initWithPXResult:resultList->results[i]];
            reader.sequenceNumber = i;
            PGResult *result = [reader result];
            [results addObject:result];
        }
    }
    px_result_list_delete(resultList, true);
    return results;
}

@end

void PGCommandInitOperationQueue(void)
{
    sharedCommandOperationQueue = [[NSOperationQueue alloc] init];
    [sharedCommandOperationQueue setName:@"Command Operation Queue"];
}

void PGCommandDestroyOperationQueue(void)
{
    sharedCommandOperationQueue = nil;
}
