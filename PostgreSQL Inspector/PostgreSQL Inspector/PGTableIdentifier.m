//
//  PGTableIdentifier.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 30/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import "PGTableIdentifier.h"
#import "PGSchemaIdentifier.h"

@implementation PGTableIdentifier

-(NSString *)fullName
{
    return [NSString stringWithFormat:@"%@.%@", self.schemaName, self.name];
}

-(NSString *)shortName
{
    if ([PGSchemaIdentifier publicSchema:self.schemaName])
    {
        return self.name;
    }
    else
    {
        return [self fullName];
    }
}

@end
