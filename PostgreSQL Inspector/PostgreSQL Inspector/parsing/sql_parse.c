#include "sql_parse.h"
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include "parsing_result.h"
#include "sql_context.h"
#include "sql_lexer.h"
#include "sql_symbol.h"
#include "lemon/sql.h"

#define SqlParseTOKENTYPE  struct sql_symbol* 
#define SqlParseARG_PDECL , struct sql_context* context 

extern void *SqlParseAlloc(void *(*mallocProc)(size_t));
extern void SqlParseFree(void *p, void (*freeProc)(void*));
extern void SqlParse(
              void *yyp,                   /* The parser */
              int yymajor,                 /* The major token code number */
              SqlParseTOKENTYPE yyminor       /* The value for the token */
              SqlParseARG_PDECL               /* Optional %extra_argument parameter */
              );
extern void SqlParseTrace(FILE *stream, char *zPrefix);

static struct sql_symbol *get_symbol_from_token_id(const int token_id, const struct sql_context *const restrict context);
static struct parsing_result *create_result(const struct sql_parser_state *const restrict parser_state);
static void add_tokens_to_parsing_result(const struct sql_symbol *const restrict symbol, struct parsing_result *restrict result);
static void add_possible_tokens_to_parsing_result(const struct sql_context_possible_token_list *const restrict list, struct parsing_result *restrict result);

struct parsing_result *sql_parse(const char *const restrict sql, unsigned int cursor_position)
{
    void *parser = SqlParseAlloc(malloc);
    struct sql_lexer *lexer = sql_lexer_init(sql);
    struct parsing_result *result = NULL;
    struct sql_context_possible_token_list *possible_token_list = sql_context_possible_token_list_init();
    struct sql_parser_state parser_state =
    {
        .accepted = false,
        .failed = false,
        .has_error = false,
        .has_parsed_wrench = false,
        .root_symbol = NULL,
        .possible_token_list = possible_token_list
    };
    
    unsigned int token_counter = 0;
    while (true)
    {
        off_t token_start = 0;
        size_t token_length = 0;
        const int token_id = sql_lexer_get_next_token(lexer, &token_start, &token_length);
        struct sql_context context =
        {
            .report_errors = false,
            .accept_grammar = true,
            .parser_state = &parser_state,
            .symbol_start = token_start,
            .symbol_length = token_length
        };
        struct sql_symbol *symbol = get_symbol_from_token_id(token_id, &context);
        // print_symbol(symbol, sql);
        
        SqlParse(parser, token_id, symbol, &context);
        
        if (token_id == T_EOF)
        {
            sql_symbol_free(symbol);
        }
        
        if (token_id == T_UNKNOWN || token_id == T_EOF) break;
        if (!parser_state.has_error)
        {
            token_counter++;
        }
    }
    
    sql_lexer_free(lexer);
    lexer = NULL;
    // we need to reparse the whole thing to trigger a fake T_EOF
    char *reparse_sql = strdup(sql);
    if (cursor_position < strlen(sql))
    {
        reparse_sql[cursor_position] = 0;
    }
    lexer = sql_lexer_init(reparse_sql);
    free(reparse_sql);
    reparse_sql = NULL;
    
    unsigned int reparse_token_counter = 0;
    while (true)
    {
        off_t token_start = 0;
        size_t token_length = 0;
        int token_id = sql_lexer_get_next_token(lexer, &token_start, &token_length);
        if (reparse_token_counter == token_counter) token_id = T_WRENCH;
        struct sql_context context =
        {
            .report_errors = true,
            .accept_grammar = false,
            .parser_state = &parser_state,
            .symbol_start = token_start,
            .symbol_length = token_length
        };
        struct sql_symbol *symbol = get_symbol_from_token_id(token_id, &context);
        SqlParse(parser, token_id, symbol, &context);
        if (token_id == T_WRENCH || token_id == T_UNKNOWN || token_id == T_EOF) break;
        reparse_token_counter++;
    }
    sql_lexer_free(lexer);
    lexer = NULL;
    
    result = create_result(&parser_state);
    sql_symbol_free_recursive(parser_state.root_symbol);
    
    SqlParseFree(parser, free);
    
    sql_context_possible_token_list_free(possible_token_list);
    
    return result;
}

static struct sql_symbol *get_symbol_from_token_id(const int token_id, const struct sql_context *const restrict context)
{
    struct sql_symbol *token = sql_symbol_init_with_token_id(token_id);
    token->start = context->symbol_start;
    token->length = context->symbol_length;
    return token;
}

static struct parsing_result *create_result(const struct sql_parser_state *const restrict parser_state)
{
    struct parsing_result *result = parsing_result_init();
    if (parser_state->root_symbol != NULL)
    {
        add_tokens_to_parsing_result(parser_state->root_symbol, result);
        parsing_result_sort_tokens(result);
    }
    
    if (parser_state->possible_token_list != NULL)
    {
        add_possible_tokens_to_parsing_result(parser_state->possible_token_list, result);
    }
    
    return result;
}

static void add_tokens_to_parsing_result(const struct sql_symbol *const restrict symbol, struct parsing_result *restrict result)
{
    if (symbol == NULL || result == NULL) return;
    
    for (unsigned int i = 0; i < symbol->child_count; i++)
    {
        add_tokens_to_parsing_result(symbol->children[i], result);
    }
    
    if (is_node_token(symbol->symbol_type))
    {
        parsing_result_add_token(result, symbol->start, symbol->length, symbol->symbol_type);
    }
}

static void add_possible_tokens_to_parsing_result(const struct sql_context_possible_token_list *const restrict list, struct parsing_result *restrict result)
{
    if (list == NULL || result == NULL || list->count == 0) return;
    enum sql_symbol_type *symbols = malloc(list->count * sizeof(enum sql_symbol_type));
    
    for (unsigned int i = 0; i < list->count; i++)
    {
        symbols[i] = get_symbol_type_by_token_id(list->tokens[i]);
    }
    
    result->possible_symbol_list.count = list->count;
    result->possible_symbol_list.symbol_types = symbols;
}