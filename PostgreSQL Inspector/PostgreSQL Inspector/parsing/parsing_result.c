#include <stdlib.h>
#include <strings.h>
#include "parsing_result.h"
#include "sql_parse.h"

static const size_t initial_token_list_capacity = 32;

static void parsing_result_destroy(struct parsing_result *restrict result);
static inline size_t token_list_size(const size_t capacity);
static int compare_tokens(const void *t0, const void *t1);

struct parsing_result *parsing_result_init(void)
{
    struct parsing_result *result = calloc(1, sizeof(struct parsing_result));
    result->token_list.capacity = initial_token_list_capacity;
    result->token_list.count = 0;
    result->token_list.tokens = calloc(initial_token_list_capacity, sizeof(struct parsing_token));
    
    return result;
}

void parsing_result_free(struct parsing_result *result)
{
    if (result == NULL) return;
    parsing_result_destroy(result);
    free(result);
}

static void parsing_result_destroy(struct parsing_result *restrict result)
{
    if (result->token_list.tokens != NULL)
    {
        free(result->token_list.tokens);
        result->token_list.tokens = NULL;
        result->token_list.capacity = 0;
        result->token_list.count = 0;
    }
}

static inline size_t token_list_size(const size_t capacity)
{
    return sizeof(struct parsing_token) * capacity;
}

void parsing_result_add_token(struct parsing_result *restrict result, const size_t start, const size_t length, const enum sql_symbol_type symbol_type)
{
    if (result == NULL)
        return;
       
    if (result->token_list.capacity == result->token_list.count)
    {
        const size_t new_capacity = result->token_list.capacity * 2;
        result->token_list.tokens = realloc(result->token_list.tokens, token_list_size(new_capacity));
        result->token_list.capacity = new_capacity;
    }
    
    struct parsing_token *token = result->token_list.tokens + (result->token_list.count++);
    bzero(token, sizeof(struct parsing_token));
    token->start = start;
    token->length = length;
    token->node_type = symbol_type;
}

bool is_node_token(const enum sql_symbol_type symbol_type)
{
    return get_sql_token_type(symbol_type) != sql_token_type_unknown;
}

enum sql_token_type get_sql_token_type(const enum sql_symbol_type symbol_type)
{
    switch (symbol_type)
    {
        case sql_symbol_identifier_quoted:
        case sql_symbol_identifier_unquoted:
            return sql_token_type_identifier;
        case sql_symbol_literal_numeric:
        case sql_symbol_literal_string:
            return sql_token_type_literal;
        case sql_symbol_token_abort:
        case sql_symbol_token_from:
        case sql_symbol_token_load:
        case sql_symbol_token_rollback:
        case sql_symbol_token_select:
        case sql_symbol_token_transaction:
        case sql_symbol_token_work:
            return sql_token_type_keyword;
        default:
            return sql_token_type_unknown;
    }
}

void parsing_result_sort_tokens(struct parsing_result *result)
{
    qsort(result->token_list.tokens, result->token_list.count, sizeof(struct parsing_token), compare_tokens);
}

static int compare_tokens(const void *t0, const void *t1)
{
    const struct parsing_token *const token0 = (const struct parsing_token *const)t0;
    const struct parsing_token *const token1 = (const struct parsing_token *const)t1;
    
    if (token0->start < token1->start)
    {
        return -1;
    }
    else if (token0->start > token1->start)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}