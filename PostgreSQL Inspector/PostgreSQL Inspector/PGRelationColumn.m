//
//  PGRelationColumn.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 06/11/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PGRelationColumn.h"
#import "PGOid.h"

@implementation PGRelationColumn
@synthesize relationId, name, typeId, typeName, typeModifier, length, number, dimensionCount, notNull, defaultValue;

@end
