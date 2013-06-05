//
//  PGSchemaIdentifier.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 30/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PGSchemaIdentifier.h"

@interface PGSchemaIdentifier()

-(void)setupProperties;

@end

@implementation PGSchemaIdentifier
@synthesize tableNames, viewNames;

-(id)initWithName:(NSString *)theName
{
    if ((self = [super initWithName:theName]))
    {
        [self setupProperties];
    }
    return self;
}

-(id)initWithName:(NSString *)theName oid:(NSInteger)theOid
{
    if ((self = [super initWithName:theName oid:theOid]))
    {
        [self setupProperties];
    }
    return self;
}

-(void)setupProperties
{
    self.tableNames = [[NSMutableArray alloc] init];
    self.viewNames = [[NSMutableArray alloc] init];
}

-(BOOL)publicSchema
{
    return [PGSchemaIdentifier publicSchema:self.name];
}

+(BOOL)publicSchema:(NSString *)schemaName
{
    return [schemaName isEqualToString:@"public"];
}

-(BOOL)systemSchema
{
    return [self.name hasPrefix:@"pg_"] || [self.name isEqualToString:@"information_schema"];
}

@end
