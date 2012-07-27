//
//  PGTable.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 02/05/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import "PGRelation.h"

@class PGConnection;

@interface PGTable : PGRelation

@property (nonatomic, strong) NSMutableArray *constraints;

-(BOOL)isColumnInPrimaryKey:(NSInteger)columnNumber;

+(void)load:(NSInteger)oid fromConnection:(PGConnection*)connection callback:(void(^)(PGTable* table))asyncCallback;

@end
