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
    if (command == nil)
    {
        NSLog(@"[PGCommandExecutor execute]: command is nil.");
        return;
    }
    
    [command.connection.operationQueue addOperationWithBlock:^{
        [command.connection lock];
        PGconn *conn = command.connection.connection;
        const int sendQueryResult = PQsendQuery(conn, [command.commandText UTF8String]);
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
        }
        else
        {
            fprintf(stderr, "PQsendQuery failed: %s\n", PQerrorMessage(conn));
            [command.connection unlock];
        }
        [command.connection unlock];
    }];
}

-(void)emptyQuery
{
    NSLog(@"empty query");
}

-(void)commandOk
{
    
}

-(void)tuplesOk:(PGresult*)pgResult index:(NSUInteger)index
{
    @autoreleasepool
    {
        if (self.onTuplesOk != nil)
        {
            self.onTuplesOk([PGCommandExecutor getResult:pgResult withIndex:index]);
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
                    [row addObject:[PGCommandExecutor getValue:pgResult columnIndex:columnIndex rowIndex:rowIndex]];
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
        return [NSNull null];
    
    const Oid oid = PQftype(pgResult, columnIndex);
    const char* value = PQgetvalue(pgResult, rowIndex, columnIndex);
    switch ((PGType)oid)
    {
        case PGTypeChar:
            return [[NSNumber alloc] initWithChar:value[0]];
        case PGTypeName:
            return [[NSString alloc] initWithUTF8String:value];
        case PGTypeOid:
            return [[PGOid alloc]initWithType:(PGType)strtoul(value, NULL, 10)];
        case PGTypeInt64:
            return [[NSNumber alloc] initWithLongLong:strtoll(value, NULL, 10)];
        default:
            //if (rowIndex == 0)
                fprintf(stderr, "Unknown OID: %i\n", oid);
            return [NSNull null];
    }
}

@end
