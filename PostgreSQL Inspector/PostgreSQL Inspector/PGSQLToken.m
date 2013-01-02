//
//  PGSQLToken.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 02/01/2013.
//
//

#import "PGSQLToken.h"
#import "parsing/parsing_result.h"

@implementation PGSQLToken

-(enum sql_token_type)tokenType
{
    return get_sql_token_type(self.nodeType);
}

@end
