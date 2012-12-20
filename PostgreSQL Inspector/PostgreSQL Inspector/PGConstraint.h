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

@property (nonatomic, strong) NSString* definition;
@property (nonatomic, assign) PGConstraintType type;
@property (nonatomic, assign) BOOL deferrable;
@property (nonatomic, assign) BOOL deferred;
@property (nonatomic, assign) BOOL validated;
@property (nonatomic, assign) NSUInteger relationId;
@property (nonatomic, strong) NSString *relationName;
@property (nonatomic, assign) NSUInteger relationNamespaceId;
@property (nonatomic, strong) NSString *relationNamespaceName;
@property (nonatomic, assign) PGForeignKeyAction foreignKeyUpdateAction;
@property (nonatomic, assign) PGForeignKeyAction foreignKeyDeleteAction;
@property (nonatomic, assign) PGForeignKeyMatchType foreignKeyMatchType;
@property (nonatomic, assign) BOOL local;
@property (nonatomic, assign) NSUInteger inheritanceAncestorCount;
@property (nonatomic, assign) BOOL noInherit;
@property (nonatomic, strong) NSMutableArray *columns;
@property (nonatomic, strong) NSString *src;

-(NSString*) constraintTypeDescription;
-(NSString*) referencedTableDescription;
+(NSString*) describeContraintType:(PGConstraintType)constraintType;

@end
