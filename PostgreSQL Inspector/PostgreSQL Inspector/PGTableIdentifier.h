//
//  PGTableIdentifier.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 30/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import "PGSchemaObjectIdentifier.h"

#define TABLE_IDENTIFIER_TYPE_TABLE 'r'
#define TABLE_IDENTIFIER_TYPE_VIEW 'v'

@interface PGTableIdentifier : PGSchemaObjectIdentifier

@property (nonatomic, assign) char type;
@property (nonatomic, assign) NSInteger schemaOid;
@property (nonatomic, strong) NSString *schemaName;

-(NSString*)fullName;
-(NSString*)shortName;

@end
