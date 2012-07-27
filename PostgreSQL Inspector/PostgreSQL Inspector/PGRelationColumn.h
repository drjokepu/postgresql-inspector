//
//  PGRelationColumn.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 06/11/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PGConnection;

@interface PGRelationColumn : NSObject

@property (nonatomic, assign) NSUInteger relationId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSUInteger typeId;
@property (nonatomic, strong) NSString *typeName;
@property (nonatomic, assign) NSInteger length;
@property (nonatomic, assign) NSInteger typeModifier;
@property (nonatomic, assign) NSInteger number;
@property (nonatomic, assign) NSInteger dimensionCount;
@property (nonatomic, assign) BOOL notNull;
@property (nonatomic, strong) id defaultValue;

+(NSArray*)loadColumnsInRelation:(NSUInteger)relationId fromCatalog:(PGConnection*)connection;

@end
