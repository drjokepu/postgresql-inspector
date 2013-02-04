//
//  PGRelation.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 24/05/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import "PGRelation.h"
#import "PGCommand.h"
#import "PGConnection.h"
#import "PGConstraint.h"
#import "PGConstraintColumn.h"
#import "PGIndex.h"
#import "PGRelationColumn.h"
#import "PGResult.h"

static BOOL isNull(const id obj);
static unsigned int getConstraintTypePriority(const PGConstraintType constraintType);
static NSComparisonResult compareConstraintTypes(const PGConstraintType c1, const PGConstraintType c2);

@implementation PGRelation

-(void)loadRelationFromCatalog:(PGConnection *)connection asyncCallback:(void (^)(void))asyncCallback
{
    @autoreleasepool
    {
        static const NSString *commandText =
        @"select c.relname, "
        "       c.relnamespace, "
        "       c.relowner, "
        "       c.reltuples, "
        "       c.relkind, "
        "       n.nspname "
        "  from pg_catalog.pg_class c "
        "       inner join pg_catalog.pg_namespace n "
        "               on n.oid = c.relnamespace "
        " where c.oid = %li;"
        "select a.attrelid, "
        "       a.attname, "
        "       a.atttypid, "
        "       pg_catalog.format_type(a.atttypid, a.atttypmod), "
        "       a.attlen, "
        "       a.atttypmod, "
        "       a.attnum, "
        "       a.attndims, "
        "       a.attnotnull, "
        "       d.adsrc "
        "  from pg_catalog.pg_attribute a "
        "       left outer join pg_catalog.pg_attrdef d "
        "                    on ( d.adrelid = a.attrelid "
        "                         and d.adnum = a.attnum ) "
        " where a.attrelid = %li "
        "       and a.attnum > 0 "
        "       and a.attisdropped = false "
        " order by a.attnum;"
        "select c2.relname, "
        "       i.indisprimary, "
        "       i.indisunique, "
        "       i.indisclustered, "
        "       i.indisvalid, "
        "       pg_catalog.pg_get_indexdef(i.indexrelid, 0, true), "
        "       pg_catalog.pg_get_constraintdef(con.oid, true), "
        "       contype, "
        "       condeferrable, "
        "       condeferred, "
        "       c2.reltablespace "
        "  from pg_catalog.pg_class c, "
        "       pg_catalog.pg_class c2, "
        "       pg_catalog.pg_index i "
        "       left join pg_catalog.pg_constraint con "
        "              on ( conrelid = i.indrelid "
        "                   and conindid = i.indexrelid "
        "                   and contype in ( 'p', 'u', 'x' ) ) "
        " where c.oid = %li "
        "       and c.oid = i.indrelid "
        "       and i.indexrelid = c2.oid "
        " order by i.indisprimary desc, "
        "          i.indisunique desc, "
        "          c2.relname;"
        " select r.oid, "
        "        r.conname, "
        "        pg_catalog.pg_get_constraintdef(r.oid, true), "
        "        r.contype, "
        "        r.condeferrable, "
        "        r.condeferred, "
        "        r.convalidated, "
        "        r.confrelid, "
        "        cref.relname, "
        "        cref.relnamespace, "
        "        sref.nspname, "
        "        r.confupdtype, "
        "        r.confdeltype, "
        "        r.confmatchtype, "
        "        r.conislocal, "
        "        r.coninhcount, "
        "        r.connoinherit, "
        "        r.conkey, "
        "        r.confkey, "
        "        r.conpfeqop, "
        "        r.conppeqop, "
        "        r.conffeqop, "
        "        r.conexclop, "
        "        r.consrc "
        "   from pg_catalog.pg_constraint r "
        "        left outer join pg_catalog.pg_class cref "
        "                     on cref.oid = r.confrelid "
        "        left outer join pg_catalog.pg_namespace sref "
        "                     on sref.oid = cref.relnamespace "
        "  where r.conrelid = %li;";

        const NSInteger relationId = self.oid;
        NSString *queryText = [[NSString alloc] initWithFormat:(NSString*)commandText,
                               relationId,
                               relationId,
                               relationId,
                               relationId];
    
        PGCommand *command = [[PGCommand alloc] init];
        command.connection = connection;
        command.commandText = queryText;
        
        [command execAsyncWithCallback:^(PGResult *result) {
            switch (result.index)
            {
                case 0:
                    [self loadDetailsFromResult:result];
                    break;
                case 1:
                    [self loadColumnsFromResult:result];
                    break;
                case 2:
                    [self loadIndexesFromResult:result];
                    break;
                case 3:
                    [self loadConstraintsFromResult:result];
                    break;
            }
        } noMoreResultsCallback:^{
            if (asyncCallback != nil) asyncCallback();
        } errorCallback:^(PGError *error) {
            
        }];
    }
}

-(void)loadDetailsFromResult:(PGResult*)result
{
    self.name = (NSString*)result.rows[0][0];
    self.namespace = [(NSNumber*)result.rows[0][1] integerValue];
    self.owner = [(NSNumber*)result.rows[0][2] unsignedIntegerValue];
    self.kind = [(NSNumber*)result.rows[0][4] charValue];
    self.schemaName = (NSString*)result.rows[0][5];
}

-(void)loadColumnsFromResult:(PGResult*)result
{
    self.columns = [[NSMutableArray alloc] initWithCapacity:result.rowCount];
    for (NSUInteger i = 0; i < result.rowCount; i++)
    {
        NSArray *row = result.rows[i];
        PGRelationColumn *column = [[PGRelationColumn alloc] init];
        column.relationId = [(NSNumber*)row[0] unsignedIntegerValue];
        column.name = row[1];
        column.typeId = [(NSNumber*)row[2] unsignedIntegerValue];
        column.typeName = row[3];
        column.length = [(NSNumber*)row[4] integerValue];
        column.typeModifier = [(NSNumber*)row[5] integerValue];
        column.number = [(NSNumber*)row[6] integerValue];
        column.dimensionCount = [(NSNumber*)row[7] integerValue];
        column.notNull = [(NSNumber*)row[8] boolValue];
        column.defaultValue = row[9];
        
        [self.columns addObject:column];
    }
}

-(void)loadIndexesFromResult:(PGResult*)result
{
    self.indexes = [[NSMutableArray alloc] initWithCapacity:result.rowCount];
    for (NSUInteger i = 0; i < result.rowCount; i++)
    {
        NSArray *row = result.rows[i];
        PGIndex *index = [[PGIndex alloc] init];
        index.name = row[0];
        index.primary = [row[1] boolValue];
        index.unique = [row[2] boolValue];
        index.clustered = [row[3] boolValue];
        index.valid = [row[4] boolValue];
        index.indexDefinition = row[5];
        index.constraintDefinition = row[6];
        index.constraintType = isNull(row[7]) ? PGConstraintTypeNone : (PGConstraintType)[row[8] charValue];
        index.deferrable = !isNull(row[8]) && [row[8] boolValue];
        index.deferred = !isNull(row[9]) && [row[9] boolValue];
        index.tablespace = [row[10] unsignedIntegerValue];
        [self.indexes addObject:index];
    };
}

-(void)loadConstraintsFromResult:(PGResult*)result
{
    self.constraints = [[NSMutableArray alloc] initWithCapacity:result.rowCount];
    for (NSUInteger i = 0; i < result.rowCount; i++)
    {
        @autoreleasepool
        {
            NSArray *row = result.rows[i];
            PGConstraint *constraint = [[PGConstraint alloc] initWithOid:[row[0] integerValue]];
            constraint.name = row[1];
            constraint.definition = row[2];
            constraint.type = (PGConstraintType)[row[3] charValue];
            constraint.deferrable = [row[4] boolValue];
            constraint.deferred = [row[5] boolValue];
            constraint.validated = [row[6] boolValue];
            constraint.relationId = [row[7] unsignedIntegerValue];
            constraint.relationName = isNull(row[8]) ? nil : row[8];
            constraint.relationNamespaceId = isNull(row[9]) ? 0 : [row[9] unsignedIntegerValue];
            constraint.relationNamespaceName = isNull(row[10]) ? nil : row[10];
            constraint.foreignKeyUpdateAction = isNull(row[11]) ? PGForeignKeyActionNone : (PGForeignKeyAction)[row[11] charValue];
            constraint.foreignKeyDeleteAction = isNull(row[12]) ? PGForeignKeyActionNone : (PGForeignKeyAction)[row[12] charValue];
            constraint.foreignKeyMatchType = isNull(row[13]) ? PGForeignKeyMatchTypeNone : (PGForeignKeyMatchType)[row[13] charValue];
            constraint.local = [row[14] boolValue];
            constraint.inheritanceAncestorCount = [row[15] unsignedIntegerValue];
            constraint.noInherit = [row[16] boolValue];
            
            NSArray *constraintColumnNumbers = row[17];
            NSArray *pkFkOperators = row[18];
            NSArray *pkPkOperators = row[19];
            NSArray *fkFkOperators = row[20];
            NSArray *exclusionOperators = row[21];
            
            if (isNull(constraintColumnNumbers)) constraintColumnNumbers = [[NSArray alloc] init];
            if (isNull(pkFkOperators)) pkFkOperators = [[NSArray alloc] init];
            if (isNull(pkPkOperators)) pkPkOperators = [[NSArray alloc] init];
            if (isNull(fkFkOperators)) fkFkOperators = [[NSArray alloc] init];
            if (isNull(exclusionOperators)) exclusionOperators = [[NSArray alloc] init];
            
            NSUInteger columnCount = [constraintColumnNumbers count];
            if ([pkFkOperators count] > columnCount) columnCount = [pkFkOperators count];
            if ([pkPkOperators count] > columnCount) columnCount = [pkPkOperators count];
            if ([fkFkOperators count] > columnCount) columnCount = [fkFkOperators count];
            if ([exclusionOperators count] > columnCount) columnCount = [exclusionOperators count];
            
            NSMutableArray *columns = [[NSMutableArray alloc] initWithCapacity:columnCount];
            
            for (NSUInteger i = 0; i < columnCount; i++)
            {
                PGConstraintColumn *column = [[PGConstraintColumn alloc] init];
                if ([constraintColumnNumbers count] > i) column.columnNumber = [constraintColumnNumbers[i] integerValue];
                if ([pkFkOperators count] > i) column.foreignKeyPKFKEqualityOperator = [pkFkOperators[i] integerValue];
                if ([pkPkOperators count] > i) column.foreignKeyPKFKEqualityOperator = [pkPkOperators[i] integerValue];
                if ([fkFkOperators count] > i) column.foreignKeyFKFKEqualityOperator = [fkFkOperators[i] integerValue];
                if ([exclusionOperators count] > i) column.exclusionOperator = [exclusionOperators[i] integerValue];
                [columns addObject:column];
            }
            
            constraint.columns = columns;
            
            constraint.src = isNull(row[23]) ? @"" : row[23];
            [self.constraints addObject:constraint];
        }
    }
    [self sortConstraints];
}

-(void)sortConstraints
{
    [self.constraints sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        const NSComparisonResult typeComparisonResult = compareConstraintTypes(((PGConstraint*)obj1).type, ((PGConstraint*)obj2).type);
        if (typeComparisonResult == NSOrderedSame)
        {
            return [((PGConstraint*)obj1).name compare:((PGConstraint*)obj2).name];
        }
        else
        {
            return typeComparisonResult;
        }
    }];
}

-(NSString *)description
{
    return [self schemaQualifiedName];
}

-(NSString *)schemaQualifiedName
{
    if ([self.schemaName isEqualToString:@"public"])
        return [PGSchemaObject escapeIdentifier:self.name];
    else
        return [[NSString alloc] initWithFormat:@"%@.%@", [PGSchemaObject escapeIdentifier:self.schemaName], [PGSchemaObject escapeIdentifier:self.name]];
}

@end

static BOOL isNull(const id obj)
{
    return obj == nil || obj == [NSNull null];
}

static NSComparisonResult compareConstraintTypes(const PGConstraintType c1, const PGConstraintType c2)
{
    const unsigned int p1 = getConstraintTypePriority(c1);
    const unsigned int p2 = getConstraintTypePriority(c2);
    
    if (p1 == p2)
    {
        return NSOrderedSame;
    }
    else if (p1 < p2)
    {
        return NSOrderedAscending;
    }
    else
    {
        return NSOrderedDescending;
    }
}

static unsigned int getConstraintTypePriority(const PGConstraintType constraintType)
{
    switch (constraintType)
    {
        case PGConstraintTypePrimaryKey:
            return 0;
        case PGConstraintTypeUniqueKey:
            return 1;
        case PGConstraintTypeForeignKey:
            return 2;
        case PGConstraintTypeCheck:
            return 3;
        case PGConstraintTypeExclusion:
            return 4;
        case PGConstraintTypeTrigger:
            return 5;
        case PGConstraintTypeNone:
            return 10;
        default:
            return 100;
    }
}
