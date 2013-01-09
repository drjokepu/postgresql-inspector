#include <stdlib.h>
#include "sql_context.h"

static const size_t sql_context_possible_token_list_initial_capacity = 64;
static const size_t sql_conmment_list_initial_capacity = 16;

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

struct sql_comment_list *sql_comment_list_init(void)
{
    struct sql_comment_list *list = calloc(1, sizeof(struct sql_comment_list));
    list->capacity = sql_conmment_list_initial_capacity;
    list->comments = calloc(sql_conmment_list_initial_capacity, sizeof(struct sql_symbol*));
    return list;
}

void sql_comment_list_free(struct sql_comment_list *list)
{
    if (list->comments != NULL)
    {
        for (off_t i = 0; i < list->count; i++)
        {
            sql_symbol_free(list->comments[i]);
            list->comments[i] = NULL;
        }
        free(list->comments);
        list->comments = NULL;
    }
    list->capacity = 0;
    list->count = 0;
    free(list);
}

void sql_comment_list_add_token(struct sql_comment_list *restrict list, struct sql_symbol *restrict comment_symbol)
{
    if (list->capacity == list->count)
    {
        const size_t new_capacity = list->capacity * 2;
        list->comments = realloc(list->comments, new_capacity * sizeof(struct sql_symbol*));
    }
    list->comments[list->count++] = comment_symbol;
}