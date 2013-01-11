//
//  PGSchemaObject.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 02/05/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import "PGSchemaObject.h"
#import "PGConnection.h"

static inline bool identifier_needs_escaping(const char *const restrict identifier);

@implementation PGSchemaObject
@synthesize oid, name;

-(id)initWithOid:(NSInteger)theOid
{
    if ((self = [super init]))
    {
        self.oid = theOid;
    }
    return self;
}

+(NSString *)escapeIdentifier:(NSString *)identifier
{
    if (identifier_needs_escaping([identifier UTF8String]))
    {
        return [[NSString alloc] initWithFormat:@"\"%@\"", [identifier stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""]];
    }
    else
    {
        return identifier;
    }
}

@end

static inline bool identifier_needs_escaping(const char *const restrict identifier)
{
    if (identifier == NULL || *identifier == 0) return true;
    
    for (const char *cursor = identifier; *cursor != 0; cursor++)
    {
        const char input_char = *cursor;
        if ((input_char < 'a' || input_char > 'z') &&
            (input_char < 'A' || input_char > 'Z') &&
            input_char != '_')
        {
            return true;
        }
    }
    
    return false;
}