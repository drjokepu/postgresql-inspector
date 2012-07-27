//
//  PGResult.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 30/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import "PGResult.h"

@interface PGResult()
{
    NSUInteger *columnTypes;
}

-(void)setColumnTypes:(NSUInteger*)columnTypes;

@end

@implementation PGResult
@synthesize columnCount;
@synthesize rowCount;
@synthesize columnNames;
@synthesize rows;
@synthesize sequenceNumber;

-(void)dealloc
{
    if (columnTypes != NULL)
    {
        free(columnTypes);
        columnTypes = NULL;
    }
}

-(void)setColumnTypes:(NSUInteger *)theColumnTypes
{
    if (columnTypes != NULL)
    {
        free(columnTypes);
    }
    columnTypes = theColumnTypes;
}

@end
