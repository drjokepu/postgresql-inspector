//
//  PGRelation.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 24/05/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import "PGSchemaObject.h"

@class PGConnection;

@interface PGRelation : PGSchemaObject

@property (nonatomic, assign) NSInteger namespace;
@property (nonatomic, assign) NSInteger tablespace;
@property (nonatomic, assign) NSInteger owner;
@property (nonatomic, assign) NSUInteger tuples;
@property (nonatomic, assign) char kind;
@property (nonatomic, strong) NSMutableArray *columns;

-(void)loadRelationFromCatalog:(PGConnection*)connection;

@end
