#include <stdlib.h>
#include "sql_context.h"

static const size_t sql_context_possible_token_list_initial_capacity = 64;

struct sql_context_possible_token_list *sql_context_possible_token_list_init(void)
{
    struct sql_context_possible_token_list *list = calloc(1, sizeof(struct sql_context_possible_token_list));
    list->capacity = sql_context_possible_token_list_initial_capacity;
    list->tokens = calloc(sql_context_possible_token_list_initial_capacity, sizeof(int));
    return list;
}

void sql_context_possible_token_list_free(struct sql_context_possible_token_list *list)
{
    if (list->tokens != NULL)
    {
        free(list->tokens);
        list->tokens = NULL;
    }
    list->capacity = 0;
    list->count = 0;
    free(list);
}

void sql_context_possible_token_list_add_token(struct sql_context_possible_token_list *restrict list, const int token)
{
    if (list->capacity == list->count)
    {
        const size_t new_capacity = list->capacity * 2;
        list->tokens = realloc(list->tokens, new_capacity * sizeof(int));
    }
    list->tokens[list->count++] = token;
}