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
@synthesize nodeType;

-(enum sql_token_type)tokenType
{
    return get_sql_token_type(nodeType);
}

-(NSArray *)expandToCompletions
{
    if (get_sql_token_type(nodeType) == sql_token_type_keyword)
    {
        id keyword = [PGSQLToken keywordOfSymbolType:nodeType];
        if (keyword == nil)
        {
            return [NSArray array];
        }
        else
        {
            return [NSArray arrayWithObject:keyword];
        }
    }
    else
    {
        return [NSArray array];
    }
}

+(NSString*)keywordOfSymbolType:(enum sql_symbol_type)symbolType
{
    switch (symbolType)
    {
        case sql_symbol_all_fields:
            return @"*";
        case sql_symbol_name_separator:
            return @".";
        case sql_symbol_expression_separator:
            return @",";
        case sql_symbol_token_abort:
            return @"abort";
        case sql_symbol_token_load:
            return @"load";
        case sql_symbol_token_from:
            return @"from";
        case sql_symbol_token_rollback:
            return @"rollback";
        case sql_symbol_token_select:
            return @"select";
        case sql_symbol_token_transaction:
            return @"transaction";
        case sql_symbol_token_work:
            return @"work";
        default:
            return nil;
    }
}

@end
