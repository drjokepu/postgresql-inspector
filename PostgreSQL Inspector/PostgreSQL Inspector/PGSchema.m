//
//  PGSchema.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 06/06/2013.
//
//

#import "PGSchema.h"
#import "PGSchemaObject.h"

@implementation PGSchema
@synthesize owner, ownerName;

-(NSString *)createDdl
{
    return [NSString stringWithFormat:@"create schema %@ authorization %@;", [PGSchemaObject escapeIdentifier:self.name], [PGSchemaObject escapeIdentifier:ownerName]];
}

@end
