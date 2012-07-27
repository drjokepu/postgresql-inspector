//
//  PGConnection.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 29/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import "PGConnection.h"
#import "PGConnectionEntry.h"

static px_connection_params* buildConnectionParams(PGConnectionEntry *connectionEntry);
static void freeConnectionParams(px_connection_params *connectionParams);

@interface PGConnection()
{
    px_connection *connection; 
}
 
-(void)handleSuccessfulConnection;
-(void)handleFailedConnection;

-(void)reportSuccesfulConnectionBackground;
-(void)reportSuccesfulConnectionMainThread;

-(void)reportPasswordNeededBackground;
-(void)reportPasswordNeededMainThread;

-(void)reportFailedConnectionBackground:(NSString*)message;
-(void)reportFailedConnectionMainThread:(NSString*)message;

-(void)storePasswordInKeychain;

@end

@implementation PGConnection
@synthesize connectionEntry;
@synthesize delegate;

-(id)initWithConnectionEntry:(PGConnectionEntry *)theConnectionEntry
{
    if ((self = [super init]))
    {
        self.connectionEntry = theConnectionEntry;
    }
    return self;
}

-(void)dealloc
{
    if (connection != NULL)
    {
        // close connection
        px_connection_delete(connection);
        connection = NULL;
    }
}

-(void)connect
{
    px_connection_params* connectionParams = buildConnectionParams(connectionEntry);
    self->connection = px_connection_new(connectionParams);
    freeConnectionParams(connectionParams);
    if (px_connection_open(connection) == px_connection_attempt_result_success)
    {
        [self handleSuccessfulConnection];
    }
    else
    {
        [self handleFailedConnection];
    }
}


-(void)handleSuccessfulConnection
{
    [self reportSuccesfulConnectionBackground];
}

-(void)reportSuccesfulConnectionBackground
{
    if (delegate == nil) return;
    
    [self performSelectorOnMainThread:@selector(reportSuccesfulConnectionMainThread)
                           withObject:nil
                        waitUntilDone:NO];
}

-(void)reportSuccesfulConnectionMainThread
{
    if (delegate == nil) return;
    if ([delegate respondsToSelector:@selector(connectionSuccessful:)])
    {
        [delegate connectionSuccessful:self];
    }
}

-(void)handleFailedConnection
{
//    if (PQconnectionNeedsPassword(connection))
//    {
//        [self reportPasswordNeededBackground];
//    }
//    else
    {
//        const char *sqlCodeC = PGIlastSqlState(connection);
//        NSString * sqlCode = [[NSString alloc] initWithBytes:sqlCodeC length:5 encoding:NSUTF8StringEncoding];
//        
//        if ([sqlCode isEqualToString:@"28P01"])
//        {
//            [self reportPasswordNeededBackground];
//        }
//        else
//        {
//            NSLog(@"Connection failed\n%s\nSQLCODE = %@", PQerrorMessage(connection), sqlCode);
            
        
        
        
            [self reportFailedConnectionBackground:[[NSString alloc] initWithCString:px_error_get_message(px_connection_get_last_error(connection)) encoding:NSUTF8StringEncoding]];
//        }
    }
}

-(void)reportPasswordNeededBackground
{
    [self performSelectorOnMainThread:@selector(reportPasswordNeededMainThread)
                           withObject:nil
                        waitUntilDone:NO];
}

-(void)reportPasswordNeededMainThread
{
    if (delegate == nil) return;
    if ([delegate respondsToSelector:@selector(connectionNeedsPassword:)])
    {
        [delegate connectionNeedsPassword:self];
    }
}

-(void)reportFailedConnectionBackground:(NSString *)message
{
    [self performSelectorOnMainThread:@selector(reportFailedConnectionMainThread:)
                           withObject:message
                        waitUntilDone:NO];
}

-(void)reportFailedConnectionMainThread:(NSString *)message
{
    if (delegate == nil) return;
    if ([delegate respondsToSelector:@selector(connectionFailed:message:)])
    {
        [delegate connectionFailed:self message:message];
    }
}

-(void)finish
{
    if (connection != NULL)
    {
        px_connection_close(connection);
        connection = NULL;
    }
}

-(void)storePasswordInKeychain
{
    
}

-(px_connection *)connection
{
    return self->connection;
}

@end

static struct px_connection_params* buildConnectionParams(PGConnectionEntry *connectionEntry)
{
    px_connection_params *connectionParams = px_connection_params_new();
    
    if ([connectionEntry.username length] != 0)
        px_connection_params_set_username(connectionParams, [connectionEntry.username cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if ([connectionEntry.host length] != 0)
        px_connection_params_set_hostname(connectionParams, [connectionEntry.host cStringUsingEncoding:NSUTF8StringEncoding]);
    
    if (connectionEntry.port > 0)
        px_connection_params_set_port(connectionParams, (unsigned int)connectionEntry.port);
    else
        px_connection_params_set_port(connectionParams, 5432);
    
    if ([connectionEntry.database length] != 0)
        px_connection_params_set_database(connectionParams, [connectionEntry.database cStringUsingEncoding:NSUTF8StringEncoding]);
    
    return connectionParams;
}

static void freeConnectionParams(px_connection_params *connectionParams)
{
    px_connection_params_delete(connectionParams);
}
