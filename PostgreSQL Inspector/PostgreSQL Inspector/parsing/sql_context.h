#ifndef __SQL_CONTEXT_H__
#define __SQL_CONTEXT_H__

#include <stdbool.h>
#include <sys/types.h>
#include "sql_symbol.h"

struct sql_parser_state;
struct sql_context_possible_token_list;

struct sql_context
{
    bool report_errors;
    bool accept_grammar;
    off_t symbol_start;
    size_t symbol_length;
    struct sql_parser_state *parser_state;
};

struct sql_context_possible_token_list
{
    size_t count;
    size_t capacity;
    int *tokens;
};

struct sql_parser_state
{
    bool accepted;
    bool failed;
    bool has_error;
    bool has_parsed_wrench;
    struct sql_symbol *root_symbol;
    struct sql_context_possible_token_list *possible_token_list;
};

struct sql_context_possible_token_list *sql_context_possible_token_list_init(void);
void sql_context_possible_token_list_free(struct sql_context_possible_token_list *list);
void sql_context_possible_token_list_add_token(struct sql_context_possible_token_list *restrict list, const int token);

#endif /* __SQL_CONTEXT_H__ */