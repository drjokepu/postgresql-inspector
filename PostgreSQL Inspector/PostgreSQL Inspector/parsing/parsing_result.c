#include <stdlib.h>
#include <strings.h>
#include "parsing_result.h"
#include "sql_parse.h"

static const size_t initial_token_list_capacity = 32;

static void parsing_result_destroy(struct parsing_result *restrict result);
static inline size_t token_list_size(const size_t capacity);

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

void parsing_result_add_token(struct parsing_result *restrict result, const size_t start, const size_t length, const enum sql_ast_node_type node_type)
{
    if (result == NULL)
        return;
    
//    printf("parsing_result_add_token(result, start = %zu, length = %zu, node_type = %i)\n", start, length, (int)node_type);
    
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
    token->node_type = node_type;
}

bool is_node_token(const enum sql_ast_node_type node_type)
{
    return get_sql_token_type(node_type) != sql_token_type_unknown;
}

enum sql_token_type get_sql_token_type(const enum sql_ast_node_type node_type)
{
    switch (node_type)
    {
        case sql_ast_identifier_quoted:
        case sql_ast_identifier_unquoted:
            return sql_token_type_identifier;
        case sql_ast_literal_numeric:
        case sql_ast_literal_string:
            return sql_token_type_literal;
        case sql_ast_abort:
        case sql_ast_from:
        case sql_ast_load:
        case sql_ast_rollback:
        case sql_ast_select:
        case sql_ast_transaction:
        case sql_ast_work:
            return sql_token_type_keyword;
        default:
            return sql_token_type_unknown;
    }
}