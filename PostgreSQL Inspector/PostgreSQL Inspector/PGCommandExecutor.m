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
#import "PGOid.h"
#import "PGResult.h"
#import "PGType.h"
#import <libpq-fe.h>

@interface PGCommandExecutor ()

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
                        [self commandOk];
                        break;
                    case PGRES_TUPLES_OK:
                        [self tuplesOk:result index:resultIndex++];
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
    NSLog(@"empty query");
}

-(void)commandOk
{
    NSLog(@"command ok");
}

-(void)noMoreResults
{
    if (self.onNoMoreResults != nil)
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
            [columnTypes addObject:[[PGOid alloc] initWithType:(PGType)PQftype(pgResult, i)]];
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
            return [[NSNumber alloc] initWithBool:value[0] == 't'];
        case PGTypeChar:
            return [[NSNumber alloc] initWithChar:value[0]];
        case PGTypeName:
        case PGTypeVarCharN:
        case PGTypeVarCharU:
            return [[NSString alloc] initWithUTF8String:value];
        case PGTypeOid:
            return [[PGOid alloc]initWithType:(PGType)strtoul(value, NULL, 10)];
        case PGTypeInt16:
            return [[NSNumber alloc] initWithShort:(short)strtol(value, NULL, 10)];
        case PGTypeInt32:
            return [[NSNumber alloc] initWithLong:strtol(value, NULL, 10)];
        case PGTypeInt64:
            return [[NSNumber alloc] initWithLongLong:strtoll(value, NULL, 10)];
        case PGTypeSingle:
            return [[NSNumber alloc] initWithFloat:strtof(value, NULL)];
        case PGTypeDouble:
            return [[NSNumber alloc] initWithDouble:strtod(value, NULL)];
        case PGTypeTimestampZ:
            return [PGCommandExecutor parseTimestampWithTimezone:value];
        case PGTypeUuid:
            return [[NSUUID alloc] initWithUUIDString:[[NSString alloc] initWithUTF8String:value]];
        default:
            //if (rowIndex == 0)
                fprintf(stderr, "Unknown OID: %i, value = %s\n", oid, value);
            return nil;
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

@end
