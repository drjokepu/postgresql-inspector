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
#import "PGResult.h"
#import <libpq-fe.h>

@implementation PGCommandExecutor
@synthesize command;
@synthesize rowByRow;

-(void)execute
{
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
                        [self tuplesOk:result];
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
    }];
}

-(void)emptyQuery
{
}

-(void)commandOk
{
    
}

-(void)tuplesOk:(PGresult*)pgResult
{
    
}

+(PGResult*)getResult:(PGresult*)pgResult
{
    PGResult *result = [[PGResult alloc] init];
    
    const int numberOfColumns = PQnfields(pgResult);
    NSMutableArray *columnNames = [[NSMutableArray alloc] initWithCapacity:numberOfColumns];
    for (int i = 0; i < numberOfColumns; i++)
    {
        [columnNames addObject:[[NSString alloc] initWithUTF8String:PQfname(pgResult, i)]];
    }
    result.columnNames = columnNames;
    
    const int numberOfRows = PQntuples(pgResult);
    NSMutableArray *rows = [[NSMutableArray alloc] initWithCapacity:numberOfRows];
    for (int rowIndex = 0; rowIndex < numberOfRows; rowIndex++)
    {
        NSMutableArray *row = [[NSMutableArray alloc] initWithCapacity:numberOfColumns];
        for (int columnIndex = 0; columnIndex < numberOfColumns; columnIndex++)
        {
            [row addObject:[PGCommandExecutor getValue:pgResult columnIndex:columnIndex rowIndex:rowIndex]];
        }
        [rows addObject:row];
    }
    
    return result;
}

+(id)getValue:(PGresult*)pgResult columnIndex:(int)columnIndex rowIndex:(int)rowIndex
{
    return nil;
}

@end
