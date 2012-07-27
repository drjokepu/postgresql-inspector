//
//  PGSchemaObjectGroup.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 30/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import "PGSchemaObjectIdentifier.h"
#import "PGSchemaObjectGroupType.h"

@interface PGSchemaObjectGroup : PGSchemaObjectIdentifier

@property (nonatomic, assign) PGSchemaObjectGroupType groupType;

-(id)initWithName:(NSString*)theName groupType:(PGSchemaObjectGroupType)theGroupType;

@end
