//
//  SqliteError.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 13/05/2011.
//  Copyright 2011 Tamas Czinege. All rights reserved.
//

#import "SqliteError.h"


@implementation SqliteError

@synthesize errorDescription;

-(id)initWithDatabase:(sqlite3 *)db
{
    if ((self = [super initWithDomain:@"SqliteError" code:sqlite3_errcode(db) userInfo:nil]))
    {
        NSString *sqlErrorText = [[NSString alloc] initWithCString:sqlite3_errmsg(db)
                                                          encoding:NSUTF8StringEncoding];
        if ([sqlErrorText length] < 2)
        {
            self.errorDescription = sqlErrorText;
        }
        else
        {
            NSString *capitalisedSentence =
                [sqlErrorText stringByReplacingCharactersInRange:NSMakeRange(0,1)
                                                      withString:[[sqlErrorText substringToIndex:1] capitalizedString]];
            self.errorDescription = [[NSString alloc] initWithFormat:@"%@.", capitalisedSentence];
        }
    }
    return self;
}

-(id)initWithCStringDescription:(char *)theErrorDescription
{
    if ((self = [super initWithDomain:@"SqliteError" code:0 userInfo:nil]))
    {
        NSString *sqlErrorText = [[NSString alloc] initWithCString:theErrorDescription
                                                          encoding:NSUTF8StringEncoding];
        if ([sqlErrorText length] < 2)
        {
            self.errorDescription = sqlErrorText;
        }
        else
        {
            NSString *capitalisedSentence =
            [sqlErrorText stringByReplacingCharactersInRange:NSMakeRange(0,1)
                                                  withString:[[sqlErrorText substringToIndex:1] capitalizedString]];
            self.errorDescription = [[NSString alloc] initWithFormat:@"%@.", capitalisedSentence];
        }
    }
    return self;
}

-(id)initWithErrorCode:(int)errorCode
{
    if ((self = [super initWithDomain:@"SqliteError" code:errorCode userInfo:nil]))
    {
        self.errorDescription = [[NSString alloc] initWithString:[SqliteError descriptionForErrorCode:errorCode]];
    }
    return self;
}

-(NSString *)description
{
    return errorDescription;
}

-(NSString *)localizedDescription
{
    return errorDescription;
}

+(SqliteError *)errorWithErrorCode:(int)errorCode
{
    return [[SqliteError alloc] initWithErrorCode:errorCode];
}

+(NSString *)descriptionForErrorCode:(int)errorCode
{
    switch (errorCode)
    {
        case SQLITE_OK:
            return @"Successful result.";
        case SQLITE_ERROR:
            return @"SQL error or missing database.";
        case SQLITE_INTERNAL:
            return @"Internal logic error in SQLite.";
        case SQLITE_PERM:
            return @"Access permission denied.";
        case SQLITE_ABORT:
            return @"Callback routine requested an abort.";
        case SQLITE_BUSY:
            return @"The database file is locked.";
        case SQLITE_LOCKED:
            return @"A table in the database is locked.";
        case SQLITE_NOMEM:
            return @"Out of memory.";
        case SQLITE_READONLY:
            return @"Attempted to write a readonly database.";
        case SQLITE_INTERRUPT:
            return @"Operation terminated.";
        case SQLITE_IOERR:
            return @"Cannot read or write database.";
        case SQLITE_CORRUPT:
            return @"The database disk image is malformed.";
        case SQLITE_NOTFOUND:
            return @"Low-level database file control error.";
        case SQLITE_FULL:
            return @"Database if full.";
        case SQLITE_CANTOPEN:
            return @"Unable to open database file.";
        case SQLITE_PROTOCOL:
            return @"Database lock protocol error.";
        case SQLITE_EMPTY:
            return @"Database is empty.";
        case SQLITE_SCHEMA:
            return @"The database schema changed.";
        case SQLITE_TOOBIG:
            return @"String or BLOB exceeds size limit.";
        case SQLITE_CONSTRAINT:
            return @"Abort due to constraint violation.";
        case SQLITE_MISMATCH:
            return @"Data type mismatch.";
        case SQLITE_MISUSE:
            return @"SQLite used incorrectly by PostgreSQL Inspector.";
        case SQLITE_NOLFS:
            return @"OS feature not supported on host.";
        case SQLITE_AUTH:
            return @"Authorization denied.";
        case SQLITE_FORMAT:
            return @"Auxiliary database format error.";
        case SQLITE_RANGE:
            return @"Parameter index is out of range.";
        case SQLITE_NOTADB:
            return @"File opened that is not a database file.";
        case SQLITE_ROW:
            return @"Another row is available.";
        case SQLITE_DONE:
            return @"Execution finished.";
        default:
            return [NSString stringWithFormat:@"Error %i", errorCode];
    }
}

@end
