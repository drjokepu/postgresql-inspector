//
//  PGResult.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 30/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PGType.h"

@interface PGResult : NSObject

@property (nonatomic, assign) NSUInteger columnCount;
@property (nonatomic, assign) NSUInteger rowCount;
@property (nonatomic, strong) NSArray *columnNames;
@property (nonatomic, strong) NSArray *rows;
@property (nonatomic, assign) NSUInteger sequenceNumber;

-(void)setColumnTypes:(NSUInteger *)theColumnTypes;

@end
