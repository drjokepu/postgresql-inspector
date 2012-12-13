//
//  PGConnectionEntry.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 23/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import <pthread.h>
#import <unistd.h>
#import <sys/stat.h>
#import <Security/Security.h>
#import "PGConnectionEntry.h"
#import "Sqlite/Sqlite.h"

static const char *keychainServiceName = "PostgreSQL Inspector";

@interface PGConnectionEntry()
{
    pthread_mutex_t mutex;
}

-(NSString*)accountName;

-(void)insert:(Sqlite*)connection;
-(void)update:(Sqlite*)connection;
-(void)delete:(Sqlite*)connection;

+(void)ensureTableExists:(Sqlite*)connection;
+(void)createTable:(Sqlite*)connection;
+(NSString *)connectionEntryListDatabaseFile;

@end

@implementation PGConnectionEntry

@synthesize objectId;
@synthesize host;
@synthesize port;
@synthesize database;
@synthesize username;
@synthesize password;
@synthesize passwordRetreivedFromKeychain;
@synthesize userAskedForStroingPasswordInKeychain;

-(id)init
{
    if ((self = [super init]))
    {
        pthread_mutex_init(&self->mutex, NULL);
    }
    return self;
}

-(void)dealloc
{
    pthread_mutex_destroy(&self->mutex);
}

-(void)lock
{
    pthread_mutex_lock(&self->mutex);
}

-(void)unlock
{
    pthread_mutex_unlock(&self->mutex);
}

+(NSString *)connectionEntryListDatabaseFile
{
    @autoreleasepool
    {
        NSString *appSupportPath = [(NSURL*)[(NSArray*)[[NSFileManager defaultManager]
                                                        URLsForDirectory:NSApplicationSupportDirectory
                                                        inDomains:NSUserDomainMask] objectAtIndex:0] path];
        
        NSString *bundleName = [[[NSBundle mainBundle] infoDictionary] objectForKey:(__bridge NSString*) kCFBundleNameKey];
        
        NSString *bundleAppSupportPath = [appSupportPath stringByAppendingPathComponent:bundleName];
        const char *bundleAppSupportPathCString = [bundleAppSupportPath fileSystemRepresentation];
        
        if (access(bundleAppSupportPathCString, F_OK) != 0)
        {
            mkdir(bundleAppSupportPathCString, S_IRWXU | S_IRGRP | S_IXGRP | S_IROTH | S_IXOTH);
        }
        
        NSString *databaseFilename = [bundleAppSupportPath stringByAppendingPathComponent:@"databases.sqlite"];
        
        return databaseFilename;
    }
}

-(NSDictionary *)connectionParams
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    [dict setObject:host forKey:@"host"];
    if (port > 0) [dict setObject:[[NSString alloc] initWithFormat:@"%li", port] forKey:@"port"];
    [dict setObject:database forKey:@"dbname"];
    if ([username length] > 0) [dict setObject:username forKey:@"user"];
    if ([password length] > 0) [dict setObject:password forKey:@"password"];
    [dict setObject:@"20" forKey:@"connect_timeout"];
    [dict setObject:@"PostgreSQL Inspector" forKey:@"application_name"];
    
    return dict;
}

-(NSString *)description
{
    if ([host length] == 0 || [database length] == 0)
        return @"New Connection";
    
    if ([username length] == 0)
    {
        if (port < 0)
        {
            return [[NSString alloc] initWithFormat:@"%@/%@",
                    host,
                    database];
        }
        else
        {
            return [[NSString alloc] initWithFormat:@"%@:%li/%@",
                    host,
                    port,
                    database];
        }
    }
    else
    {
        if (port < 0)
        {
            return [[NSString alloc] initWithFormat:@"%@@%@/%@",
                    username,
                    host,
                    database];
        }
        else
        {
            return [[NSString alloc] initWithFormat:@"%@@%@:%li/%@",
                    username,
                    host,
                    port,
                    database];
        }
    }
}

+(NSArray *)getConnectionEntries
{
    @autoreleasepool 
    {
        NSError *error = nil;
        Sqlite *connection = [[Sqlite alloc] initAndOpen:[PGConnectionEntry connectionEntryListDatabaseFile]
                                                   error:&error];
        [connection beginTransaction:NULL];
        [PGConnectionEntry ensureTableExists:connection];
        
        static const NSString *commandText =
            @"select id, host, port, database, username \n"
             "  from pgconnection \n"
             " order by host, database, username";
        
        NSArray *entries = [connection readAll:commandText parameters:nil reader:^id(SqliteReader *r)
        {
            PGConnectionEntry *entry = [[PGConnectionEntry alloc] init];
            
            entry.objectId = [r getInt32:0];
            entry.host = [r getString:1];
            entry.port = [r isDBNull:2] ? -1 : [r getInt32:2];
            entry.database = [r getString:3];
            entry.username = [r isDBNull:4] ? nil : [r getString:4];
            
            return entry;
        }];
        
        [connection commitTransaction:NULL];
        [connection close];
        return entries;
    }
}

+(void)ensureTableExists:(Sqlite *)connection
{
    if (![connection schemaObjectExists:@"pgconnection"])
    {
        [self createTable:connection];
    }
}

+(void)createTable:(Sqlite *)connection
{
    static const NSString *commandText =
        @"create table pgconnection \n"
         "( \n"
         "  id       INTEGER not null primary key autoincrement, \n"
         "  host     \"VARCHAR(1024)\" not null, \n"
         "  port     INTEGER, \n"
         "  \"database\" \"VARCHAR(63)\" not null, \n"
         "  username \"VARCHAR(128)\", \n"
         "  constraint UK_PGCONNECTION unique (username, host, database, port) \n"
         ");";
    
    [connection execute:commandText parameters:nil action:nil error:NULL];
}

+(NSUInteger)defaultConnectionPort
{
    return 5232;
}

-(void)insert
{
    @autoreleasepool 
    {
        NSError *error = nil;
        Sqlite *connection = [[Sqlite alloc] initAndOpen:[PGConnectionEntry connectionEntryListDatabaseFile]
                                                   error:&error];
        [connection beginTransaction:NULL];
        [self insert:connection];
        [connection commitTransaction:NULL];
        [connection close];
    }
}

-(void)insert:(Sqlite *)connection
{
    [PGConnectionEntry ensureTableExists:connection];
    
    static const NSString *commandText =
        @"insert into pgconnection (host, port, database, username) "
         "values (@host, @port, @database, @username)";
    
    NSMutableArray *parameters = [[NSMutableArray alloc] initWithCapacity:4];
    [parameters addObject:[[SqliteParamString alloc] initWithName:@"host" stringValue:self.host]];
    [parameters addObject:[[SqliteParamInt32 alloc] initWithName:@"port" int32Value:(int)self.port]];
    [parameters addObject:[[SqliteParamString alloc] initWithName:@"database" stringValue:self.database]];
    [parameters addObject:[[SqliteParamString alloc] initWithName:@"username" stringValue:self.username]];
    
    [connection execute:commandText parameters:parameters action:nil error:NULL];
    self.objectId = [connection lastInsertedRowId];
}

-(void)update
{
    @autoreleasepool 
    {
        NSError *error = nil;
        Sqlite *connection = [[Sqlite alloc] initAndOpen:[PGConnectionEntry connectionEntryListDatabaseFile]
                                                   error:&error];
        [connection beginTransaction:NULL];
        [self update:connection];
        [connection commitTransaction:NULL];
        [connection close];
    }
}

-(void)update:(Sqlite *)connection
{
    [PGConnectionEntry ensureTableExists:connection];
    
    static const NSString *commandText =
        @"update pgconnection set host = @host, port = @port, database = @database, username = @username "
         "where id = @id";
    
    NSMutableArray *parameters = [[NSMutableArray alloc] initWithCapacity:5];
    [parameters addObject:[[SqliteParamString alloc] initWithName:@"host" stringValue:self.host]];
    [parameters addObject:[[SqliteParamInt32 alloc] initWithName:@"port" int32Value:(int)self.port]];
    [parameters addObject:[[SqliteParamString alloc] initWithName:@"database" stringValue:self.database]];
    [parameters addObject:[[SqliteParamString alloc] initWithName:@"username" stringValue:self.username]];
    [parameters addObject:[[SqliteParamInt32 alloc] initWithName:@"id" int32Value:(int)self.objectId]];
    
    [connection execute:commandText parameters:parameters action:nil error:NULL];
}

-(void)delete
{
    @autoreleasepool 
    {
        NSError *error = nil;
        Sqlite *connection = [[Sqlite alloc] initAndOpen:[PGConnectionEntry connectionEntryListDatabaseFile]
                                                   error:&error];
        [connection beginTransaction:NULL];
        [self delete:connection];
        [connection commitTransaction:NULL];
        [connection close];
    }
}

-(void)delete:(Sqlite *)connection
{
    static const NSString *commandText =
        @"delete from pgconnection where id = @id";
    
    NSArray *parameters = [[NSArray alloc] initWithObjects:
                           [[SqliteParamInt32 alloc] initWithName:@"id" int32Value:(int)self.objectId],
                           nil];
    
    [connection execute:commandText parameters:parameters action:nil error:NULL];
}

-(NSString *)accountName
{
    if ([host length] == 0 || [database length] == 0)
        return nil;
    else
        return [self description];
}

-(void)storePasswordInKeyChain:(NSString *)thePassword
{
    NSString *accountName = [self accountName];
    UInt32 passwordLength;
    void *passwordData;
    SecKeychainItemRef keychainItem;
    
    const char *accountNameCString = [accountName cStringUsingEncoding:NSUTF8StringEncoding];
    
    if ([accountName length] == 0) return;
    
    OSStatus status = SecKeychainFindGenericPassword(NULL,
                                                     (UInt32)strlen(keychainServiceName),
                                                     keychainServiceName,
                                                     (UInt32)strlen(accountNameCString),
                                                     accountNameCString,
                                                     &passwordLength,
                                                     &passwordData,
                                                     &keychainItem);
    
//    CFStringRef message = SecCopyErrorMessageString(status, NULL);
//    NSLog(@"status: %@", (__bridge NSString*)message);
    
    if (status == errSecSuccess)
    {
        NSString *oldPassword = [[NSString alloc] initWithBytes:passwordData length:passwordLength encoding:NSUTF8StringEncoding];
        
        if (![thePassword isEqualToString:oldPassword])
        {
            // modify
        }
    }
    else if (status == errSecItemNotFound)
    {
        const char *newPasswordCString = [thePassword cStringUsingEncoding:NSUTF8StringEncoding];
        const size_t newPasswordLength = strlen(newPasswordCString);
        
        status = SecKeychainAddGenericPassword(NULL,
                                               (UInt32)strlen(keychainServiceName),
                                               keychainServiceName,
                                               (UInt32)strlen(accountNameCString),
                                               accountNameCString,
                                               (UInt32)newPasswordLength,
                                               newPasswordCString, NULL);
        
        if (status != errSecSuccess)
        {
            CFStringRef message = SecCopyErrorMessageString(status, NULL);
            NSLog(@"SecKeychainAddGenericPassword: %@", (__bridge NSString*)message);
            CFRelease(message);
        }
    }
    else
    {
        CFStringRef message = SecCopyErrorMessageString(status, NULL);
        NSLog(@"SecKeychainFindGenericPassword: %@", (__bridge NSString*)message);
        CFRelease(message);
    }
    
    if (passwordData != NULL)
        SecKeychainItemFreeContent(NULL, passwordData);
}

@end
