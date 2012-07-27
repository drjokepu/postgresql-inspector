//
//  PGDataReader.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 30/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import "PGDataReader.h"
#import "px.h"
#import "PGNull.h"
#import "PGResult.h"

@interface PGDataReader()
{
    px_result *pxResult;
    NSUInteger missingTypeCounter;
}

-(id)getValueInColumn:(NSUInteger)column row:(NSUInteger)row columnTypes:(NSUInteger*)columnTypes;
-(id)getValueOfTextData:(const char*)cval columnType:(PGType)columnType;

+(NSArray*)parseArrayOfIntegers:(NSString*)text;

@end

@implementation PGDataReader
@synthesize sequenceNumber;

-(id)initWithPXResult:(px_result *)thePXResult
{
    if ((self = [super init]))
    {
        pxResult = thePXResult;
    }
    return self;
}

-(void)dealloc
{
    if (pxResult != NULL)
    {
        px_result_delete(pxResult);
        pxResult = NULL;
    }
}

-(void)close
{
    if (pxResult != NULL)
    {
        px_result_delete(pxResult);
        pxResult = NULL;
    }
}

-(PGResult *)result
{
    @autoreleasepool
    {
        missingTypeCounter = 0;
        NSUInteger columnCount = px_result_get_column_count(pxResult);
        NSUInteger rowCount = px_result_get_row_count(pxResult);
        
        NSMutableArray *columnNames = [[NSMutableArray alloc] initWithCapacity:columnCount];
        NSUInteger *columnTypes = malloc(columnCount * sizeof(NSUInteger));
        
        for (NSUInteger i = 0; i < columnCount; i++)
        {
            NSString *columnName = [[NSString alloc] initWithCString:px_result_get_column_name(pxResult, i)
                                                            encoding:NSUTF8StringEncoding];
            [columnNames addObject:columnName];
            columnTypes[i] = px_result_get_column_datatype(pxResult, i);
        }
        
        NSMutableArray *rows = [[NSMutableArray alloc] initWithCapacity:rowCount];
        for (NSUInteger j = 0; j < rowCount; j++)
        {
            NSMutableArray *row = [[NSMutableArray alloc] initWithCapacity:columnCount];
            for (NSUInteger i = 0; i < columnCount; i++)
            {
                id data = [self getValueInColumn:i row:j columnTypes:columnTypes];
                [row addObject:data];
            }
            [rows addObject:row];
        }
        
        PGResult *result = [[PGResult alloc] init];
        result.sequenceNumber = sequenceNumber;
        result.columnCount = columnCount;
        result.rowCount = rowCount;
        result.columnNames = columnNames;
        result.rows = rows;
        [result setColumnTypes:columnTypes];
        
//        NSLog(@"missing types: %lu", missingTypeCounter);
        
        return result;
    }
}

-(id)getValueInColumn:(NSUInteger)column row:(NSUInteger)row columnTypes:(NSUInteger *)columnTypes
{
    if (px_result_is_db_null(pxResult, column, row))
        return [PGNull sharedValue];
    
    char *cval = px_result_copy_cell_value_as_string(pxResult, column, row);
    PGType columnType = columnTypes[column];
    id result = [self getValueOfTextData:cval columnType:columnType];
    free(cval);
    return result;
}

-(id)getValueOfTextData:(const char *)cval columnType:(PGType)columnType
{
    switch (columnType)
    {
        case PGTypeBool:
            return [[NSNumber alloc] initWithBool:cval[0] == 't'];
        case PGTypeInt16:
        case PGTypeInt32:
        case PGTypeOid:
        case PGTypeXid:
            return [[NSNumber alloc] initWithInt:atoi(cval)];
        case PGTypeSingle:
            return [[NSNumber alloc] initWithDouble:atof(cval)];
        case PGTypeChar:
            return [[NSString alloc] initWithBytes:cval length:1 encoding:NSUTF8StringEncoding];
        case PGTypeName:
        case PGTypeVarCharN:
        case PGTypeVarCharU:
        case PGTypeAcl:
        case PGTypeAclA:
            return [[NSString alloc] initWithCString:cval encoding:NSUTF8StringEncoding];
        case PGTypeOidA:
        case PGTypeOidAU:
        case PGTypeInt16A:
        case PGTypeInt16AU:
        case PGTypeInt32A:
            return [PGDataReader parseArrayOfIntegers:[[NSString alloc] initWithCString:cval encoding:NSUTF8StringEncoding]];
        default:
            missingTypeCounter++;
            NSLog(@"unhandled type: %lu\nvalue = %@", (NSUInteger)columnType, [[NSString alloc] initWithCString:cval encoding:NSUTF8StringEncoding]);
            return [PGNull sharedValue];
    }
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
            const NSInteger value = [numericString integerValue];
            NSNumber *numberValue = [[NSNumber alloc] initWithInteger:value];
            [results addObject:numberValue];
        }
    } while ([scanner scanString:@"," intoString:NULL]);
    
    return results;
}

@end
