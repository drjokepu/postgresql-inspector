//
//  PGRelationColumn.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 06/11/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PGRelationColumn.h"
#import "PGCommand.h"
#import "PGResult.h"
#import "PGOid.h"

@implementation PGRelationColumn
@synthesize relationId, name, typeId, typeName, typeModifier, length, number, dimensionCount, notNull, defaultValue;

+(NSArray*)loadColumnsInRelation:(NSUInteger)relationId fromCatalog:(PGConnection*)connection
{
    @autoreleasepool
    {
        static const NSString *commandText =
        @"select a.attrelid, a.attname, a.atttypid, pg_catalog.format_type(a.atttypid, a.atttypmod), "
         "       a.attlen, a.atttypmod, a.attnum, a.attndims, a.attnotnull, d.adsrc "
         "  from pg_catalog.pg_attribute a "
         "  left outer join pg_catalog.pg_attrdef d on (d.adrelid = a.attrelid and d.adnum = a.attnum) "
         " where a.attrelid = $1 "
         "   and a.attnum > 0 "
         "   and a.attisdropped = false "
         " order by a.attnum";
        
        PGCommand *command = [[PGCommand alloc] initWithConnection:connection commandText:commandText];
        [command addParameter:[[PGOid alloc] initWithValue:(unsigned int)relationId]];
        
        PGResult *result = [[command execute] objectAtIndex:0];
        NSMutableArray *columns = [[NSMutableArray alloc] initWithCapacity:result.rows.count];
        
        for (NSUInteger i = 0; i < result.rows.count; i++)
        {
            PGRelationColumn *column = [[PGRelationColumn alloc] init];
            NSArray *row = [result.rows objectAtIndex:i];
            column.relationId = [(NSNumber*)[row objectAtIndex:0] unsignedIntegerValue];
            column.name = [row objectAtIndex:1];
            column.typeId = [(NSNumber*)[row objectAtIndex:2] unsignedIntegerValue];
            column.typeName = [row objectAtIndex:3];
            column.length = [(NSNumber*)[row objectAtIndex:4] integerValue];
            column.typeModifier = [(NSNumber*)[row objectAtIndex:5] integerValue];
            column.number = [(NSNumber*)[row objectAtIndex:6] integerValue];
            column.dimensionCount = [(NSNumber*)[row objectAtIndex:7] integerValue];
            column.notNull = [(NSNumber*)[row objectAtIndex:8] boolValue];
            column.defaultValue = [row objectAtIndex:9];
            
            [columns addObject:column];
        }
        
        return columns;
    }
}

@end
