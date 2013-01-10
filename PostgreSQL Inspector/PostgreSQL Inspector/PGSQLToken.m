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
    const enum sql_token_type token_type = get_sql_token_type(nodeType);
    if (token_type == sql_token_type_keyword || token_type == sql_token_type_operator)
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
        case sql_symbol_operator_and:
            return @"and";
        case sql_symbol_operator_or:
            return @"or";
        case sql_symbol_operator_not:
            return @"not";
        case sql_symbol_token_abort:
            return @"abort";
        case sql_symbol_token_all:
            return @"all";
        case sql_symbol_token_begin:
            return @"begin";
        case sql_symbol_token_commit:
            return @"commit";
        case sql_symbol_token_committed:
            return @"committed";
        case sql_symbol_token_deferrable:
            return @"deferrable";
        case sql_symbol_token_end:
            return @"end";
        case sql_symbol_token_from:
            return @"from";
        case sql_symbol_token_isolation:
            return @"isolation";
        case sql_symbol_token_level:
            return @"level";
        case sql_symbol_token_load:
            return @"load";
        case sql_symbol_token_only:
            return @"only";
        case sql_symbol_token_read:
            return @"read";
        case sql_symbol_token_repeatable:
            return @"repeatable";
        case sql_symbol_token_rollback:
            return @"rollback";
        case sql_symbol_token_select:
            return @"select";
        case sql_symbol_token_serializable:
            return @"serializable";
        case sql_symbol_token_show:
            return @"show";
        case sql_symbol_token_table:
            return @"table";
        case sql_symbol_token_transaction:
            return @"transaction";
        case sql_symbol_token_uncommitted:
            return @"uncommitted";
        case sql_symbol_token_work:
            return @"work";
        case sql_symbol_token_write:
            return @"write";
        default:
            return nil;
    }
}

@end
