//
//  PGSQLParser.m
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 27/12/2012.
//
//

#import "PGSQLParser.h"
#import "PGSQLParsingResult.h"
#import "PGSQLToken.h"
#import "parsing/sql_parse.h"
#import "parsing/parsing_result.h"

@implementation PGSQLParser

+(PGSQLParsingResult*)parse:(NSString *)sql
{
    struct parsing_result *result = sql_parse([sql UTF8String]);
    if (result != NULL)
    {
        PGSQLParsingResult *resultObject = [PGSQLParser createResultObject:result];
        parsing_result_free(result);
        return resultObject;
    }
    else
    {
        return nil;
    }
}

+(PGSQLParsingResult*)createResultObject:(struct parsing_result*)result
{
    PGSQLParsingResult *resultObject = [[PGSQLParsingResult alloc] init];
    [PGSQLParser populateTokenListInResultObject:resultObject fromResult:result];
    [PGSQLParser populatePossibleTokenListInResultObject:resultObject fromResult:result];
    
    return resultObject;
}

+(void)populateTokenListInResultObject:(PGSQLParsingResult*)resultObject fromResult:(struct parsing_result*)result
{
    NSMutableArray *tokenList = [[NSMutableArray alloc] initWithCapacity:result->token_list.count];
    for (NSUInteger i = 0; i < result->token_list.count; i++)
    {
        const struct parsing_token *const token = result->token_list.tokens + i;
        PGSQLToken *tokenObject = [[PGSQLToken alloc] init];
        tokenObject.nodeType = token->node_type;
        tokenObject.start = (NSUInteger)token->start;
        tokenObject.length = (NSUInteger)token->length;
        [tokenList addObject:tokenObject];
    }
    resultObject.tokens = tokenList;
}

+(void)populatePossibleTokenListInResultObject:(PGSQLParsingResult*)resultObject fromResult:(struct parsing_result*)result
{
    NSMutableArray *tokenList = [[NSMutableArray alloc] initWithCapacity:result->possible_symbol_list.count];
    for (NSUInteger i = 0; i < result->possible_symbol_list.count; i++)
    {
        PGSQLToken *tokenObject = [[PGSQLToken alloc] init];
        tokenObject.nodeType = result->possible_symbol_list.symbol_types[i];
        tokenObject.start = 0;
        tokenObject.length = 0;
        [tokenList addObject:tokenObject];
    }
    resultObject.possibleTokens = tokenList;
}

@end
