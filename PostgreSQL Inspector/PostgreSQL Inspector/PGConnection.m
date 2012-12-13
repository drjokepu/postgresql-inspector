//
//  PGConnection.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 29/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import "PGConnection.h"
#import "PGConnectionEntry.h"
#import "NSDictionary+PGDictionary.h"
#import <netdb.h>
#import <arpa/inet.h>
#import <sys/types.h>
#import <sys/socket.h>

static static bool syncWaitConnectionToOpen(PGconn *conn);

@interface PGConnection()
{
    PGconn *connection;
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
        PQfinish(connection);
        connection = NULL;
    }
}

-(void)open
{
    [connectionEntry lock];
    NSString *host = [[NSString alloc] initWithString:connectionEntry.host];
    [connectionEntry unlock];
    
    printf("lookup started\n");
    NSString *ip = [PGConnection resolveHost:host];
    if (ip == nil)
    {
        [self handleFailedConnection];
    }
    printf("lookup done\n");
    
    [connectionEntry lock];
    connectionEntry.hostaddr = ip;
    PGNullTerminatedKeysAndValues *keysValues = [[connectionEntry connectionParams] copyToNullTerminatedArrays];
    [connectionEntry unlock];
    
    printf("connecting\n");
    PGconn *conn = PQconnectStartParams((const char**)keysValues->keys,
                                        (const char**)keysValues->values,
                                        0);
    PGFreeNullTerminatedKeysAndValues(keysValues);
    self->connection = conn;
    if (conn != NULL && PQstatus(conn) != CONNECTION_BAD && syncWaitConnectionToOpen(conn))
    {
        [self handleSuccessfulConnection];
    }
    else
    {
        [self handleFailedConnection];
    }
}

+(NSString*)resolveHost:(NSString*)host
{
    const struct addrinfo hints =
    {
        .ai_family = PF_INET,
        .ai_socktype = 0,
        .ai_protocol = IPPROTO_TCP,
        .ai_flags = AI_ADDRCONFIG,
        .ai_addrlen = 0,
        .ai_addr = NULL,
        .ai_canonname = NULL,
        .ai_next = NULL
    };
    struct addrinfo *res = NULL;
    const int lookup_success = getaddrinfo([host UTF8String], "postgresql", &hints, &res);
    if (lookup_success == 0) // success
    {
        struct addrinfo *cursor = res;
        while (cursor != NULL)
        {
            void *addr = NULL;
            unsigned int address_max_length = 0;
            switch (cursor->ai_addr->sa_family)
            {
                case AF_INET:
                    addr = &(((struct sockaddr_in*)(cursor->ai_addr))->sin_addr);
                    address_max_length = INET_ADDRSTRLEN;
                    break;
                case AF_INET6:
                    addr = &(((struct sockaddr_in6*)(cursor->ai_addr))->sin6_addr);
                    address_max_length = INET6_ADDRSTRLEN;
                    break;
            }
            
            if (addr != NULL)
            {
                char *ip_char = calloc(address_max_length + 1, sizeof(char));
                inet_ntop(cursor->ai_addr->sa_family,
                          addr,
                          ip_char,
                          address_max_length);
                printf("ip: %s\n", ip_char);
                NSString *ip = [[NSString alloc] initWithUTF8String:ip_char];
                free(ip_char);
                freeaddrinfo(res);
                return ip;
            }
        }
        freeaddrinfo(res);
        return nil;
    }
    else
    {
        fprintf(stderr, "getaddrinfo failed: %i %s\n", lookup_success, gai_strerror(lookup_success));
        return nil;
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
    [self reportFailedConnectionBackground:[[NSString alloc] initWithUTF8String:PQerrorMessage(self->connection)]];
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

-(void)close
{
    if (connection != NULL)
    {
        PQfinish(connection);
        connection = NULL;
    }
}

-(void)storePasswordInKeychain
{
    
}

-(PGconn *)connection
{
    return self->connection;
}

-(PGConnection *)copy
{
    return [[PGConnection alloc] initWithConnectionEntry:connectionEntry];
}

static bool syncWaitConnectionToOpen(PGconn *conn)
{
    printf("syncWaitConnectionToOpen\n");
    const int fd = PQsocket(conn);
    fd_set fds;
    struct timeval timeout;
    
    PostgresPollingStatusType status = PGRES_POLLING_WRITING;
    bool shouldPoll = false;
    while (true)
    {
        if (PQstatus(conn) == CONNECTION_BAD)
            return false;
        
        timeout.tv_sec =  5;
        timeout.tv_usec = 0;
        FD_ZERO(&fds);
        FD_SET(fd, &fds);
        
        switch (status)
        {
            case PGRES_POLLING_READING:
                if (select(fd + 1, &fds, NULL, NULL, &timeout) == 1)
                    shouldPoll = true;
                break;
            case PGRES_POLLING_WRITING:
                if (select(fd + 1, NULL, &fds, NULL, &timeout) == 1)
                    shouldPoll = true;
                break;
            case PGRES_POLLING_OK:
                return true;
            case PGRES_POLLING_FAILED:
            default:
                return false;
        }
        
        if (shouldPoll)
        {
            shouldPoll = false;
            status = PQconnectPoll(conn);
        }
    }
}

@end

