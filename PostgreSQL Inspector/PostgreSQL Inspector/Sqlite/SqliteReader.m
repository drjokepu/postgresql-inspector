//
//  SqliteReader.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 15/04/2011.
//  Copyright 2011 Tamas Czinege. All rights reserved.
//

#import "SqliteReader.h"
#import "SqliteError.h"

@implementation SqliteReader

-(id)initWithCommand:(sqlite3_stmt *)theCommand database:(sqlite3 *)theDatabase
{
    if ((self = [super init]))
    {
        command = theCommand;
        db = theDatabase;
    }
    return self;
}

-(BOOL)readWithError:(NSError **)error
{
    if (error != NULL) *error = nil;
    int result = sqlite3_step(command);
    lastResult = result;
    if (result != SQLITE_ROW && result != SQLITE_DONE)
    {
        if (error == NULL)
        {
            [NSException raise:@"SqliteQueryError" format:@"Query execution failed: %s", sqlite3_errmsg(db)];
            return NO;
        }
        else
        {
            *error = [SqliteError errorWithErrorCode:result];
            return NO;
        }
    }
    return result == SQLITE_ROW;
}

-(int)lastResult
{
    return lastResult;
}

-(BOOL)getBool:(int)column
{
    return [self getInt32:column] != 0;
}

-(int)getInt32:(int)column
{
    return sqlite3_column_int(command, column);
}

- (NSString *)getString:(int)column
{
    if (sqlite3_column_type(command, column) == SQLITE_NULL)
        return nil;
    else
        return [NSString stringWithUTF8String:(const char*)sqlite3_column_text(command, column)];
}

-(NSString *)getName:(int)column
{
    return [NSString stringWithUTF8String:(const char*)sqlite3_column_name(command, column)];
}

-(id)getValue:(int)column
{
    int columnType = sqlite3_column_type(command, column);
    switch (columnType)
    {
        case SQLITE_INTEGER:
            return [NSNumber numberWithInt:sqlite3_column_int(command, column)];
        case SQLITE_FLOAT:
            return [NSNumber numberWithDouble:sqlite3_column_double(command, column)];
        case SQLITE_TEXT:
            return [NSString stringWithUTF8String:(const char*)sqlite3_column_text(command, column)];
        case SQLITE_BLOB:
            [NSData dataWithBytes:sqlite3_column_blob(command, column) length:sqlite3_column_bytes(command, column)];
        case SQLITE_NULL:
        default:
            return nil;
    }
}

-(NSString *)getSqlRepresentation:(int)column
{
    int columnType = sqlite3_column_type(command, column);
    switch (columnType)
    {
        case SQLITE_INTEGER:
            return [NSString stringWithFormat:@"%i", sqlite3_column_int(command, column)];
        case SQLITE_FLOAT:
            return [NSString stringWithFormat:@"%f", sqlite3_column_double(command, column)];
        case SQLITE_TEXT:
            return [NSString stringWithFormat:@"'%@'", [[NSString stringWithUTF8String:(const char*)sqlite3_column_text(command, column)] stringByReplacingOccurrencesOfString:@"'" withString:@"''"]];
        case SQLITE_BLOB:
        case SQLITE_NULL:
        default:
            return @"null";
    }
}

-(BOOL)isDBNull:(int)column
{
    return sqlite3_column_type(command, column) == SQLITE_NULL;
}

-(int)numberOfColumns
{
    return sqlite3_column_count(command);
}

@end
