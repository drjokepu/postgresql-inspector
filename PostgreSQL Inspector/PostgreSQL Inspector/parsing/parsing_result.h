#ifndef __PARSING_RESULT_H__
#define __PARSING_RESULT_H__

#include <stdbool.h>
#include <stdio.h>
#include "sql_symbol.h"

struct parsing_token
{
    size_t start;
    size_t length;
    enum sql_symbol_type node_type;
};

struct parsing_result
{
    struct
    {
        size_t count;
        size_t capacity;
        struct parsing_token* tokens;
    } token_list;
};

extern struct parsing_result *parsing_result_init(void);
extern void parsing_result_free(struct parsing_result *result);

extern void parsing_result_add_token(struct parsing_result *restrict result, const size_t start, const size_t length, const enum sql_symbol_type symbol_type);
void parsing_result_sort_tokens(struct parsing_result *result);

extern bool is_node_token(const enum sql_symbol_type symbol_type);
extern enum sql_token_type get_sql_token_type(const enum sql_symbol_type symbol_type);

#endif /* __PARSING_RESULT_H__ */