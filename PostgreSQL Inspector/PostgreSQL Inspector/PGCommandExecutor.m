//
//  PGCommandExecutor.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 13/12/2012.
//
//

#import "PGCommandExecutor.h"
#import "PGCommand.h"
#import "PGConnection.h"
#import "PGError.h"
#import "PGResult.h"
#import "PGType.h"
#import "PGUUID.h"
#import <libpq-fe.h>

@interface PGCommandExecutor ()
{
    BOOL failed;
}

@end

@implementation PGCommandExecutor
@synthesize command;
@synthesize rowByRow;

-(id)initWithCommand:(PGCommand *)theCommand
{
    if ((self = [super init]))
    {
        self.command = theCommand;
    }
    return self;
}

-(void)execute
{
    __block PGCommand *executedCommand = self.command;
    
    if (executedCommand == nil)
    {
        NSLog(@"[PGCommandExecutor execute]: command is nil.");
        return;
    }

    [executedCommand.connection.operationQueue addOperationWithBlock:^{
        [executedCommand.connection lock];
        PGconn *conn = executedCommand.connection.connection;
        if (conn == NULL)
        {
            fprintf(stderr, "execute: command.connection.connection is NULL\n");
            return;
        }
            
        const int sendQueryResult = PQsendQuery(conn, [executedCommand.commandText UTF8String]);
        if (sendQueryResult == 1) // success
        {
            if (rowByRow)
            {
                PQsetSingleRowMode(conn);
            }
            
            NSUInteger resultIndex = 0;
            PGresult *result = NULL;
            while ((result = PQgetResult(conn)))
            {
                const ExecStatusType resultStatus = PQresultStatus(result);
                switch (resultStatus)
                {
                    case PGRES_EMPTY_QUERY:
                        [self emptyQuery];
                        break;
                    case PGRES_COMMAND_OK:
                        [self commandOk:result index:resultIndex++];
                        break;
                    case PGRES_TUPLES_OK:
                        [self tuplesOk:result index:resultIndex++];
                        break;
                    case PGRES_FATAL_ERROR:
                        [self fatalError:result];
                        break;
                    default:
                        fprintf(stderr, "Unknown result status: %i %s\n", (int)resultStatus, PQresStatus(resultStatus));
                }
                PQclear(result);
            }
            [self noMoreResults];
        }
        else
        {
            fprintf(stderr, "PQsendQuery failed: %s\n", PQerrorMessage(conn));
        }
        [executedCommand.connection unlock];
    }];
}

-(void)emptyQuery
{
}

-(void)commandOk:(PGresult*)pgResult index:(NSUInteger)index
{
    @autoreleasepool
    {
        if (self.onTuplesOk != nil)
        {
            __block void (^onTuplesOk)(PGResult *result) = self.onTuplesOk;
            __block PGResult *result = [PGCommandExecutor getResult:pgResult withIndex:index];
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                onTuplesOk(result);
            }];
        }
    }
}

-(void)noMoreResults
{
    if (self.onNoMoreResults != nil && !self->failed)
    {
        [[NSOperationQueue mainQueue] addOperationWithBlock:self.onNoMoreResults];
    }
}

-(void)tuplesOk:(PGresult*)pgResult index:(NSUInteger)index
{
    @autoreleasepool
    {
        if (self.onTuplesOk != nil)
        {
            __block void (^onTuplesOk)(PGResult *result) = self.onTuplesOk;
            __block PGResult *result = [PGCommandExecutor getResult:pgResult withIndex:index];
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                onTuplesOk(result);
            }];
        }
    }
}

-(void)fatalError:(PGresult*)result
{
    @autoreleasepool
    {
        if (self.onError != nil)
        {
            PGError *error = [[PGError alloc] init];
            error.sqlErrorMessage = [[NSString alloc] initWithUTF8String:PQresultErrorField(result, PG_DIAG_MESSAGE_PRIMARY)];

            const char *const errorPositionString = PQresultErrorField(result, PG_DIAG_STATEMENT_POSITION);
            if (errorPositionString && *errorPositionString)
            {
                long errorPosition = strtol(errorPositionString, NULL, 10);
                if (errorPosition > 0) errorPosition--;
                error.errorPosition = errorPosition;
            }
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                self.onError(error);
            }];
        }
        self->failed = YES;
    }
}

+(PGResult*)getResult:(PGresult*)pgResult withIndex:(NSUInteger)resultIndex
{
    @autoreleasepool
    {
        PGResult *result = [[PGResult alloc] init];
        result.index = resultIndex;
        
        const int numberOfColumns = PQnfields(pgResult);
        NSMutableArray *columnNames = [[NSMutableArray alloc] initWithCapacity:numberOfColumns];
        NSMutableArray *columnTypes = [[NSMutableArray alloc] initWithCapacity:numberOfColumns];
        for (int i = 0; i < numberOfColumns; i++)
        {
            [columnNames addObject:[[NSString alloc] initWithUTF8String:PQfname(pgResult, i)]];
            [columnTypes addObject:@(PQftype(pgResult, i))];
        }
        result.columnNames = columnNames;
        result.columnTypes = columnTypes;
        
        const int numberOfRows = PQntuples(pgResult);
        result.rowCount = (NSUInteger)numberOfRows;
        NSMutableArray *rows = [[NSMutableArray alloc] initWithCapacity:numberOfRows];
        for (int rowIndex = 0; rowIndex < numberOfRows; rowIndex++)
        {
            @autoreleasepool
            {
                NSMutableArray *row = [[NSMutableArray alloc] initWithCapacity:numberOfColumns];
                for (int columnIndex = 0; columnIndex < numberOfColumns; columnIndex++)
                {
                    id value = [PGCommandExecutor getValue:pgResult columnIndex:columnIndex rowIndex:rowIndex];
                    if (value == nil) value = [NSNull null];
                    [row addObject:value];
                }
                [rows addObject:row];
            }
        }
        result.rows = rows;
        result.commandStatus = [[NSString alloc] initWithUTF8String:PQcmdStatus(pgResult)];
        return result;
    }
}

+(id)getValue:(PGresult*)pgResult columnIndex:(int)columnIndex rowIndex:(int)rowIndex
{
    if (PQgetisnull(pgResult, rowIndex, columnIndex))
        return nil;
    
    const Oid oid = PQftype(pgResult, columnIndex);
    const char* value = PQgetvalue(pgResult, rowIndex, columnIndex);
    switch ((PGType)oid)
    {
        case PGTypeBool:
            return @(value[0] == 't');
        case PGTypeChar:
            return @(value[0]);
        case PGTypeName:
        case PGTypeVarCharN:
        case PGTypeVarCharU:
        case PGTypeNodeTree:
        case PGTypeJson:
        case PGTypeVarCharNA:
            return [[NSString alloc] initWithUTF8String:value];
        case PGTypeOid:
            return @(strtoul(value, NULL, 10));
        case PGTypeInt16:
            return @(strtol(value, NULL, 10));
        case PGTypeInt32:
            return @(strtol(value, NULL, 10));
        case PGTypeInt64:
            return @(strtoll(value, NULL, 10));
        case PGTypeSingle:
            return @(strtof(value, NULL));
        case PGTypeDouble:
            return @(strtod(value, NULL));
        case PGTypeTimestampZ:
            return [PGCommandExecutor parseTimestampWithTimezone:value];
        case PGTypeUuid:
            if (system_has_NSUUID())
                return [[NSUUID alloc] initWithUUIDString:[[NSString alloc] initWithUTF8String:value]];
            else
                return [[PGUUID alloc] initWithUUIDString:[[NSString alloc] initWithUTF8String:value]];
        case PGTypeInt16A:
        case PGTypeInt16AU:
        case PGTypeInt32A:
        case PGTypeOidA:
        case PGTypeOidAU:
            return [PGCommandExecutor parseArrayOfIntegers:[[NSString alloc] initWithUTF8String:value]];
        default:
//            fprintf(stderr, "Unknown OID: %i, value = %s\n", oid, value);
            return [[NSString alloc] initWithUTF8String:value];;
    }
}

+(NSDate*)parseTimestampWithTimezone:(const char*)string
{
    // 2012-10-19 16:19:05.536+01
    const unsigned long year = strtol(string, NULL, 10);
    const unsigned long month = strtol(string + 5, NULL, 10);
    const unsigned long day = strtol(string + 8, NULL, 10);
    const unsigned long hour = strtol(string + 11, NULL, 10);
    const unsigned long minute = strtol(string + 14, NULL, 10);
    const unsigned long second = strtol(string + 17, NULL, 10);
//    const unsigned long fragment = strtol(string + 20, NULL, 10);
    
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setYear:year];
    [components setMonth:month];
    [components setDay:day];
    [components setHour:hour];
    [components setMinute:minute];
    [components setSecond:second];
    return [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] dateFromComponents:components];
}

+(NSArray *)parseArrayOfIntegers:(NSString *)text
{
    if ([text length] == 0) return [[NSArray alloc] init];
    
    NSMutableArray *results = [[NSMutableArray alloc] init];
    NSScanner *scanner = [[NSScanner alloc] initWithString:text];
    [scanner scanString:@"{" intoString:NULL];
    
    do
    {
        @autoreleasepool
        {
            NSString *numericString = nil;
            [scanner scanCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&numericString];
            [results addObject:@([numericString integerValue])];
        }
    } while ([scanner scanString:@"," intoString:NULL]);
    
    return results;
}

@end
