//
//  PGConstraint.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 06/13/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PGSchemaObject.h"
#import "PGConstraintType.h"
#import "PGForeignKeyAction.h"
#import "PGForeignKeyMatchType.h"

@interface PGConstraint : PGSchemaObject

@property (nonatomic, assign) NSUInteger namespaceId;
@property (nonatomic, assign) PGConstraintType type;
@property (nonatomic, assign) BOOL deferrable;
@property (nonatomic, assign) BOOL deferred;
@property (nonatomic, assign) NSUInteger relationId;
@property (nonatomic, assign) NSUInteger domainId;
@property (nonatomic, assign) NSUInteger indexId;
@property (nonatomic, assign) NSUInteger foreignKeyReferencedTableId;
@property (nonatomic, assign) PGForeignKeyAction foreignKeyUpdateAction;
@property (nonatomic, assign) PGForeignKeyAction foreignKeyDeleteAction;
@property (nonatomic, assign) PGForeignKeyMatchType foreignKeyMatchType;
@property (nonatomic, assign) BOOL local;
@property (nonatomic, assign) NSUInteger inheritanceAncestorCount;
@property (nonatomic, strong) NSMutableArray *columns;
@property (nonatomic, strong) NSString *src;

+(NSArray*)loadConstraintsInRelation:(NSUInteger)relationId fromCatalog:(PGConnection*)connection;

@end
