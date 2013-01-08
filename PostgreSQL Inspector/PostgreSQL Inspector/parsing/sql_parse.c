#include "sql_parse.h"
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include "parsing_result.h"
#include "sql_context.h"
#include "sql_lexer.h"
#include "sql_symbol.h"

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

static struct sql_symbol *get_symbol_from_token_id(const int token_id, const struct sql_context *const restrict context);
static struct parsing_result *create_result(const struct sql_symbol *const restrict root_symbol);
static void add_tokens_to_parsing_result(const struct sql_symbol *const restrict symbol, struct parsing_result *restrict result);

struct parsing_result *sql_parse(const char *const restrict sql)
{
    bool accepted = false;
    void *parser = SqlParseAlloc(malloc);
    struct sql_lexer *lexer = sql_lexer_init(sql);
    struct parsing_result *result = NULL;
    
    do
    {
        off_t token_start = 0;
        size_t token_length = 0;
        const int token_id = sql_lexer_get_next_token(lexer, &token_start, &token_length);
        struct sql_context context = { .symbol_start = token_start, .symbol_length = token_length, .root_symbol = NULL };
        struct sql_symbol *symbol = get_symbol_from_token_id(token_id, &context);
        // print_symbol(symbol, sql);
        
        SqlParse(parser, token_id, symbol, &context);
        
        if (context.root_symbol != NULL)
        {
            accepted = true;
            result = create_result(context.root_symbol);
            sql_symbol_free_resursive(context.root_symbol);
        }
        
        if (token_id == T_EOF)
        {
            sql_symbol_free(symbol);
        }
        
        if (token_id == T_UNKNOWN || token_id == T_EOF) break;
    } while (!accepted);
    
    SqlParseFree(parser, free);
    sql_lexer_free(lexer);
    
    return result;
}

static struct sql_symbol *get_symbol_from_token_id(const int token_id, const struct sql_context *const restrict context)
{
    struct sql_symbol *token = sql_symbol_init_with_token_id(token_id);
    token->start = context->symbol_start;
    token->length = context->symbol_length;
    return token;
}

static struct parsing_result *create_result(const struct sql_symbol *const restrict root_symbol)
{
    struct parsing_result *result = parsing_result_init();
    add_tokens_to_parsing_result(root_symbol, result);
    parsing_result_sort_tokens(result);
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