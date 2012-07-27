//
//  PGSchemaIdentifier.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 30/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PGSchemaObjectIdentifier.h"

@interface PGSchemaIdentifier : PGSchemaObjectIdentifier

@property (nonatomic, strong) NSMutableArray *tableNames;
@property (nonatomic, strong) NSMutableArray *viewNames;

@end
