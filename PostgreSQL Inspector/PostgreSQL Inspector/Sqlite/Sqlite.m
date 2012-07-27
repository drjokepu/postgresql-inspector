//
//  SqliteTools.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 13/04/2011.
//  Copyright 2011 Tamas Czinege. All rights reserved.
//

#import "Sqlite.h"
#import "SqliteError.h"
#import "Keywords.h"

@interface Sqlite()
{
    @private
    sqlite3* db;
    NSString *databaseFilename;
    BOOL transactionsDisabled;
}

@end

@implementation Sqlite

@synthesize databaseFilename;

- (id)initAndOpen:(NSString*)filename error:(NSError **)error
{
    if ((self = [super init]))
    {
        transactionsDisabled = NO;
        self.databaseFilename = filename; 
        if (![self open:filename error:error])
        {
            NSLog(@"Unable to open SQLite database: %@", filename);
            return nil;
        }
    }
    return self;
}

-(id)initAndOpenTrains2Database
{
    return [self initAndOpen:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"trains2.sqlite"] error:NULL];
}

-(void)dealloc
{
    if (db) [self close];
}

-(BOOL)isInTransaction
{
    // http://www.sqlite.org/c3ref/get_autocommit.html
    return sqlite3_get_autocommit(db) == 0;
}

- (BOOL)open:(NSString*)filename error:(NSError **)error

{
    db = [Sqlite openWithFilename:filename error:error];
    return db != NULL;
}

- (void)close
{
    if (db)
    {
        [Sqlite close:db];
        db = NULL;
    }
}

- (void)reset
{
    [self close];
    [self open:databaseFilename error:NULL];
}

- (BOOL)isOpen
{
    return db != NULL;
}

-(SqliteManagedReader *)prepare:(const NSString *)commandText parameters:(NSArray *)parameters error:(NSError **)error
{
    sqlite3_stmt *command = NULL;
    BOOL wasInTransactionBefore = [self isInTransaction];
    if (![self beginTransaction:error]) return nil;
    
    if (sqlite3_prepare_v2(db, [commandText UTF8String], -1, &command, NULL) != SQLITE_OK)
    {
        if (error == NULL)
        {
            [NSException raise:@"Invalid sql query" format:@"Can't execute query: %s", sqlite3_errmsg(db)];
        }
        else
        {
            *error = [[SqliteError alloc] initWithDatabase:db];
        }
        if (!wasInTransactionBefore) [self rollbackTransaction:NULL];
        return nil;
    }
    
    for (unsigned int i = 0; i < [parameters count]; i++)
    {
        [(SqliteParam*)[parameters objectAtIndex:i] bindTo:command];
    }
    
    SqliteManagedReader *reader = [[SqliteManagedReader alloc] initWithCommand:command database:db];
    return reader;
}

- (BOOL) readAll:(SqliteReader*)reader into:(NSMutableArray*)result with:(id(^)(SqliteReader*))read error:(NSError**) error
{
    @autoreleasepool
    {
        while ([reader readWithError:error])
        {
            if (error != NULL && *error != nil) break; 
            [result addObject: read(reader)];
        }
        
        if (error == NULL || *error == nil)
        {
            return YES;
        }
        else
        {
            return NO;
        }
    }
}

- (BOOL) read:(SqliteManagedReader*)reader rows:(NSInteger)rows into:(NSMutableArray*)result with:(id(^)(SqliteReader*))read error:(NSError**)error
{
    @autoreleasepool
    {
        NSInteger rowCounter = 0;
        BOOL hasMoreRows = YES;
        while ((rows == SqliteFetchAllRows || rowCounter < rows) && ((hasMoreRows = [reader readWithError:error])))
        {
            if (error != NULL && *error != nil) break;
            [result addObject: read(reader)];
            rowCounter++;
        }
        if (error == NULL || *error == nil)
        {
            if (!hasMoreRows)
            {
                [reader close];
                if ([self numberOfRowsChanged] == 0)
                {
                    [self commitTransaction:error];
                    if (error != NULL && *error != nil)
                    {
                        return NO;
                    }
                }
            }
            return YES;
        }
        else
        {
            [reader close];
            return NO;
        }
    }
}

-(NSArray *)fetchFrom:(SqliteManagedReader *)reader rows:(NSInteger)rows withReader:(id (^)(SqliteReader *))read error:(NSError **)error
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    if ([self read:reader rows:rows into:result with:read error:error])
        return result;
    else
        return nil;
}

- (NSArray*) readAll:(const NSString*)commandText parameters:(NSArray*)parameters reader:(id(^)(SqliteReader*))read
{
    return [self readAll:commandText parameters:parameters error:NULL reader:read];
}

- (NSArray*) readAll:(const NSString*)commandText parameters:(NSArray*)parameters error:(NSError **)error reader:(id(^)(SqliteReader*))read
{
    return [self readAll:commandText parameters:parameters commitOnChange:YES error:error reader:read];
}

- (NSArray*) readAll:(const NSString*)commandText parameters:(NSArray*)parameters commitOnChange:(BOOL)commitOnChange error:(NSError **)error reader:(id(^)(SqliteReader*))read
{
    sqlite3_stmt *command = NULL;
    
    if (error != NULL) (*error) = nil;
    
    BOOL wasInTransactionBefore = [self isInTransaction];
    [self beginTransaction:error];
    if (error != NULL && *error != nil) return nil;
    
    if (sqlite3_prepare_v2(db, [commandText UTF8String], -1, &command, NULL) != SQLITE_OK)
    {
        if (error == NULL)
        {
            [NSException raise:@"Invalid sql query" format:@"Can't execute query: %s", sqlite3_errmsg(db)];
        }
        else
        {
            *error = [[SqliteError alloc] initWithDatabase:db];
        }
        if (commitOnChange || !wasInTransactionBefore) [self rollbackTransaction:NULL];
        return nil;
    }
    
    for (unsigned int i = 0; i < [parameters count]; i++)
    {
        [(SqliteParam*)[parameters objectAtIndex:i] bindTo:command];
    }
    
    NSMutableArray* result = [[NSMutableArray alloc] init];
    SqliteReader *reader = [[SqliteReader alloc] initWithCommand:command database:db];
    BOOL readSuccesful = [self readAll:reader into:result with:read error:error];
    
    sqlite3_finalize(command);
    
    if (readSuccesful)
    {
        NSInteger numberOfRowsChanged = [self numberOfRowsChanged];
        BOOL didChange = numberOfRowsChanged > 0;
        
        if ((!wasInTransactionBefore && !didChange) || (commitOnChange && didChange))
        {
            [self commitTransaction:error];
            if (error != NULL && *error != nil)
            {
                return nil;
            }
        }
        
        return result;
    }
    else
    {
        if (commitOnChange || !wasInTransactionBefore) [self rollbackTransaction:NULL];
        return nil;
    }
}

-(id)readSingle:(const NSString *)commandText parameters:(NSArray *)parameters reader:(id (^)(SqliteReader *))read
{
    return [self readSingle:commandText parameters:parameters error:NULL reader:read];
}

-(id)readSingle:(const NSString *)commandText parameters:(NSArray *)parameters error:(NSError **)error reader:(id (^)(SqliteReader *))read
{
    sqlite3_stmt *command = NULL;
    
    if (error != NULL) (*error) = nil;
    
    if (sqlite3_prepare_v2(db, [commandText UTF8String], -1, &command, NULL) != SQLITE_OK)
    {
        if (error == NULL)
        {
            [NSException raise:@"Invalid sql query" format:@"Can't execute query: %s", sqlite3_errmsg(db)];
            return nil;
        }
        else
        {
            *error = [[SqliteError alloc] initWithDatabase:db];
            return nil;
        }
    }
    
    for (unsigned int i = 0; i < [parameters count]; i++)
    {
        [(SqliteParam*)[parameters objectAtIndex:i] bindTo:command];
    }
    
    SqliteReader *reader = [[SqliteReader alloc] initWithCommand:command database:db];
    id result = nil;
    
    if ([reader readWithError:error])
    {
        result = read(reader);
    }
    
    sqlite3_finalize(command);
    
    return result;
}

-(BOOL)execute:(const NSString *)commandText parameters:(NSArray *)parameters commitOnChange:(BOOL)commitOnChange error:(NSError **)error
{
    sqlite3_stmt *command = NULL;
    
    if (error != NULL) (*error) = nil;
    
    BOOL wasInTransactionBefore = [self isInTransaction];
    if (![self beginTransaction:error]) return NO;
    
    if (sqlite3_prepare_v2(db, [commandText UTF8String], -1, &command, NULL) != SQLITE_OK)
    {
        if (error == NULL)
        {
            [NSException raise:@"Invalid sql query" format:@"Can't execute query: %s", sqlite3_errmsg(db)];
        }
        else
        {
            *error = [[SqliteError alloc] initWithDatabase:db];
        }
        if (commitOnChange || !wasInTransactionBefore) [self rollbackTransaction:NULL];
        return NO;
    }
    
    for (unsigned int i = 0; i < [parameters count]; i++)
    {
        [(SqliteParam*)[parameters objectAtIndex:i] bindTo:command];
    }
    
    SqliteReader *reader = [[SqliteReader alloc] initWithCommand:command database:db];
    [reader readWithError:error];
    
    sqlite3_finalize(command);
    
    if (error == NULL || *error == nil)
    {
        NSInteger numberOfRowsChanged = [self numberOfRowsChanged];
        BOOL didChange = numberOfRowsChanged > 0;
        
        if ((!wasInTransactionBefore && !didChange) || (commitOnChange && didChange))
        {
            if (![self commitTransaction:error]) return NO;
        }
        
        return YES;
    }
    else
    {
        if (commitOnChange || !wasInTransactionBefore) [self rollbackTransaction:NULL];
        return NO;
    }
}

-(BOOL)execute:(const NSString *)commandText parameters:(NSArray *)parameters action:(void (^)(SqliteReader *))action error:(NSError **)error
{
    sqlite3_stmt *command = NULL;
    
    if (sqlite3_prepare_v2(db, [commandText UTF8String], -1, &command, NULL) != SQLITE_OK)
    {
        [NSException raise:@"Invalid sql query" format:@"Can't execute query: %s", sqlite3_errmsg(db)];
    }
    
    for (unsigned int i = 0; i < [parameters count]; i++)
    {
        [(SqliteParam*)[parameters objectAtIndex:i] bindTo:command];
    }
    
    SqliteReader *reader = [[SqliteReader alloc] initWithCommand:command database:db];
    while ([reader readWithError:error])
    {
        if (error != NULL && *error != nil)
            break;
        if (action != nil)
            action(reader);
    }
    
    sqlite3_finalize(command);
    return error == NULL || *error == nil;
}

-(BOOL)executeAll:(const NSString *)commandText error:(NSError **)error
{
    char *errorMessage = NULL;
    
    BOOL wasInTransactionBefore = [self isInTransaction];
    if (![self beginTransaction:error]) return NO;
    
    sqlite3_exec(db, [commandText UTF8String], NULL, NULL, &errorMessage);
    if (errorMessage == NULL)
    {
        if (error != NULL) (*error) = nil;
        if (!wasInTransactionBefore) [self commitTransaction:error];
        return error == NULL || *error == nil;
    }
    else
    {
        if (error != NULL)
        {
            *error = [[SqliteError alloc] initWithCStringDescription:errorMessage];
            sqlite3_free(errorMessage);
            [self rollbackTransaction:NULL];
        }
        return NO;
    }
}

-(id)executeScalar:(const NSString *)commandText
{
    return [self executeScalar:commandText parameters:nil];
}

-(id)executeScalar:(const NSString *)commandText parameters:(NSArray *)parameters
{
    return [self readSingle:commandText parameters:parameters reader:^id(SqliteReader *r)
    {
        return [r getValue:0];
    }];
}

-(BOOL)beginTransaction:(NSError **)error
{
    if (transactionsDisabled || self.isInTransaction) return YES;
    
    const static NSString* commandText = @"BEGIN TRANSACTION";
    [self execute:commandText parameters:nil action:nil error:error];
    return (error == NULL || *error == nil);
}

-(BOOL)rollbackTransaction:(NSError **)error
{
    if (transactionsDisabled || !self.isInTransaction) return YES;
    
    const static NSString* commandText = @"ROLLBACK TRANSACTION";
    [self execute:commandText parameters:nil action:nil error:error];
    return (error == NULL || *error == nil);
}

-(BOOL)commitTransaction:(NSError **)error
{
    if (transactionsDisabled || !self.isInTransaction) return YES;
    
    const static NSString* commandText = @"COMMIT TRANSACTION";
    [self execute:commandText parameters:nil action:nil error:error];
    if (error != NULL && *error != nil && [*error code] == SQLITE_BUSY)
    {
        [self rollbackTransaction:NULL];
        [self beginTransaction:NULL];
    }
    return (error == NULL || *error == nil);
}

-(int)numberOfRowsChanged
{
    return sqlite3_changes(db);
}

-(NSInteger)totalNumberOfRowsChanged
{
    return sqlite3_total_changes(db);
}

-(NSInteger)lastInsertedRowId
{
    return (NSInteger)sqlite3_last_insert_rowid(db);
}

- (BOOL) updateCellTo:(id)value inTable:(NSString*)tableName column:(NSString*)column rowId:(NSString*)rowId row:(int)row error:(NSError **)error
{    
    NSString *commandText = [[NSString alloc] initWithFormat:@"update %@ set %@ = @val where %@ = @id", [Sqlite identifier:tableName], [Sqlite identifier:column], [Sqlite identifier:rowId]];
    
    SqliteParamInt32 *rowParam = [[SqliteParamInt32 alloc] initWithName:@"id" int32Value:row];
    SqliteParam *valueParam = [SqliteParam sqliteParamWithName:@"val" value:value];
    
    NSArray *parameters = [[NSArray alloc] initWithObjects:rowParam, valueParam, nil];
    
    BOOL result = [self execute:commandText parameters:parameters commitOnChange:NO error:error];
    
    return result;
}

-(BOOL)deleteRow:(int)row from:(NSString *)tableName rowId:(NSString *)rowId error:(NSError **)error
{
    NSString *commandText = [[NSString alloc] initWithFormat:@"delete from %@ where %@ = @id", [Sqlite identifier:tableName], [Sqlite identifier:rowId]];
    
    SqliteParamInt32 *rowParam = [[SqliteParamInt32 alloc] initWithName:@"id" int32Value:row];
    NSArray *parameters = [[NSArray alloc] initWithObjects:rowParam, nil];
    
    BOOL result = [self execute:commandText parameters:parameters commitOnChange:NO error:error];
    
    return result;
}

+ (sqlite3 *)openWithFilename:(NSString *)filename error:(NSError **)error
{
    sqlite3 *db = NULL;
    int result = sqlite3_open([filename fileSystemRepresentation], &db);
    if (result != SQLITE_OK)
    {
        sqlite3_close(db);
        if (error != NULL)
        {
            *error = [SqliteError errorWithErrorCode:result];
            NSLog(@"Can't open database %@: %@", filename, [*error description]);
        }
        return NULL;
    }
    return db;
}

+ (void)close:(sqlite3 *)db
{
    sqlite3_close(db);
}

+(NSSet *)keyWords
{
    static NSSet *keyWords = nil;
    if (keyWords == nil)
    {
        keyWords = [[NSSet alloc] initWithObjects:__parser_sqlite_keywords count:KEYWORD_COUNT];
    }
    return keyWords;
}

+(BOOL)isLegalIdentifierWord:(NSString *)identifier
{
    if ([identifier length] == 0) return NO;
    
    static NSString* charString = @"abcdefghijklmnopqrstuvwxyz_";
    @autoreleasepool
    {
        NSScanner *scanner = [[NSScanner alloc] initWithString:[identifier lowercaseString]];
        NSCharacterSet *characters = [NSCharacterSet characterSetWithCharactersInString:charString];
        return ([scanner scanCharactersFromSet:characters intoString:NULL] && [scanner isAtEnd]);
    }
}

+(NSString *)identifier:(NSString *)identifier
{
    if ([identifier hasPrefix:@"\""] && [identifier hasSuffix:@"\""])
        return identifier;
    else if ([[Sqlite keyWords] containsObject:[identifier lowercaseString]] ||
        ![Sqlite isLegalIdentifierWord:identifier])
        return [NSString stringWithFormat:@"\"%@\"", identifier];
    else
        return identifier;
}

-(NSString *)description
{
    return databaseFilename;
}

-(NSArray *)tableNames
{
    static NSString* commandText = @"SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name";
    NSArray* objects = [self readAll:commandText parameters:nil reader:^id(SqliteReader* r)
                        {
                            return [r getString:0];
                        }];
    return objects;
}

-(NSArray *)viewNames
{
    static NSString* commandText = @"SELECT name FROM sqlite_master WHERE type = 'view' ORDER BY name";
    NSArray* objects = [self readAll:commandText parameters:nil reader:^id(SqliteReader* r)
                        {
                            return [r getString:0];
                        }];
    return objects;
}

-(BOOL)schemaObjectExists:(NSString *)name
{
    static NSString *commandText = @"select count(*) from sqlite_master where lower(name) = lower(@tblname)";
    
    @autoreleasepool
    {
        SqliteParamString *param = [[SqliteParamString alloc] initWithName:@"tblname" stringValue:name];
        NSArray *params = [[NSArray alloc] initWithObjects:param, nil];
        
        return [[self executeScalar:commandText parameters:params] integerValue] > 0;
    }
}

-(sqlite3 *)db
{
    return db;
}

-(BOOL)backupTo:(NSString *)filename progressCallback:(void (^)(NSInteger, NSInteger))progressCallback withError:(NSError**)error;
{
    NSURL *url = [[NSURL alloc] initFileURLWithPath:filename];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filename])
        [[NSFileManager defaultManager] removeItemAtURL:url error:error];
    
    if (error != NULL && *error != nil) return NO;
    
    sqlite3 *destination = [Sqlite openWithFilename:filename error:error];
    if (error != NULL && *error != nil) return NO;
    
    sqlite3_backup *backup = sqlite3_backup_init(destination, "main", db, "main");
    int status = -1;
    while (((status = sqlite3_backup_step(backup, 1))) != SQLITE_DONE)
    {
        if (status != SQLITE_OK)
        {
            if (error != NULL)
            {
                *error = [SqliteError errorWithErrorCode:status];
            }
            
            sqlite3_backup_finish(backup);
            [Sqlite close:destination];
            return NO;
        }
        int remaining = sqlite3_backup_remaining(backup);
        int pageCount = sqlite3_backup_pagecount(backup);
        progressCallback(remaining, pageCount);
    }
    sqlite3_backup_finish(backup);
    [Sqlite close:destination];
    return YES;
}

-(void)attachDatabase:(NSString *)databaseName path:(NSString *)attachedDatabasePath
{
    transactionsDisabled = YES;
    
    NSString *commandText = [[NSString alloc] initWithFormat:@"attach database @adbpath as %@", [Sqlite identifier:databaseName]];
    
    SqliteParamString *param = [[SqliteParamString alloc] initWithName:@"adbpath" stringValue:attachedDatabasePath];
    NSArray *params = [[NSArray alloc] initWithObjects:param, nil];
    [self execute:commandText parameters:params commitOnChange:NO error:NULL];
    
    transactionsDisabled = NO;
}

-(void)detachDatabase:(NSString *)databaseName
{
    transactionsDisabled = YES;
    
    NSString *commandText = [[NSString alloc]
                             initWithFormat:@"detach database %@", [Sqlite identifier:databaseName]];
    
    [self execute:commandText parameters:nil commitOnChange:NO error:NULL];
    
    transactionsDisabled = NO;
}

@end
