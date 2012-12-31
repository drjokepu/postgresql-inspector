#include "sql_parse.h"
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

static const size_t sql_node_array_default_capacity = 1024;
static const size_t sql_allocations_default_capacity = 1024;

static struct sql_node_array *node_array = NULL;
static struct sql_allocations *allocations = NULL;
struct sql_ast_node *sql_parse_result;

static struct sql_node_array *sql_node_array_init(void);
static void sql_node_array_free(struct sql_node_array *array);
static void sql_node_array_reset(struct sql_node_array **array);
static inline size_t sql_node_array_size(const size_t capacity);
static struct sql_ast_node *sql_node_alloc(void);
static inline off_t sql_node_index(const struct sql_node_array *restrict array, const struct sql_ast_node *restrict node);
static inline off_t sql_node_index_global(const struct sql_ast_node *restrict node);

static void print_node_tree(const struct sql_ast_node *restrict root_node);
static void print_node(const struct sql_ast_node *restrict node, const unsigned int depth);
static void print_node_value(const struct sql_ast_node *restrict node);
static const char *const node_name(const enum sql_ast_node_type node_type);

static void sql_allocations_init(void);
static void sql_allocations_free(void);
static void sql_allocations_expand_if_necessary(void);
static inline size_t sql_allocations_size(const size_t capacity);
static void *sql_malloc(size_t size);

void sql_parse(const char *const restrict sql)
{
    sql_allocations_init();
    sql_lexer_init_with_input(sql);
    const bool parse_succesful = (sql_yyparse() == 0);
    if (parse_succesful)
    {
        print_node_tree(sql_parse_result);
    }
    sql_node_array_reset(&node_array);
    sql_allocations_free();
}

void sql_parser_static_init(void)
{
    if (node_array == NULL)
    {
        node_array = sql_node_array_init();
    }
}

void sql_parser_static_destroy(void)
{
    if (node_array != NULL)
    {
        sql_node_array_free(node_array);
        node_array = NULL;
    }
    sql_allocations_free();
}

static void sql_allocations_init(void)
{
    if (allocations != NULL)
    {
        sql_allocations_free();
    }
    allocations = malloc(sql_allocations_size(sql_allocations_default_capacity));
    allocations->count = 0;
    allocations->capacity = sql_allocations_default_capacity;
}

static void sql_allocations_free(void)
{
    if (allocations == NULL) return;
    for (unsigned int i = 0; i < allocations->count; i++)
    {
        free(allocations->list[i]);
    }
    free(allocations);
    allocations = NULL;
}

static void sql_allocations_expand_if_necessary(void)
{
    if (allocations->capacity == allocations->count)
    {
        const size_t new_capacity = allocations->capacity * 2;
        allocations = realloc(allocations, new_capacity);
        allocations->capacity = new_capacity;
    }
}

static inline size_t sql_allocations_size(const size_t capacity)
{
    return sizeof(struct sql_allocations) + (capacity * (sizeof(void*)));
}

static void *sql_malloc(size_t size)
{
    void *memory = malloc(size);
    if (memory != NULL)
    {
        sql_allocations_expand_if_necessary();
        allocations->list[allocations->count++] = memory;
    }
    return memory;
}

struct sql_node_array *sql_node_array_init(void)
{
    struct sql_node_array *array = calloc(1, sql_node_array_size(sql_node_array_default_capacity));
    array->capacity = sql_node_array_default_capacity;
    return array;
}

static void sql_node_array_free(struct sql_node_array *array)
{
    free(array);
}

static void sql_node_array_reset(struct sql_node_array **array)
{
    (*array)->count = 0;
    if ((*array)->capacity <= sql_node_array_default_capacity)
    {
        *array = realloc(*array, sql_node_array_size(sql_node_array_default_capacity));
        (*array)->capacity = sql_node_array_default_capacity;
    }
}

static inline size_t sql_node_array_size(const size_t capacity)
{
    return sizeof(struct sql_node_array) + (capacity * sizeof(struct sql_ast_node));
}

static struct sql_ast_node *sql_node_alloc(void)
{
    if (node_array->count == node_array->capacity)
    {
        const size_t new_capacity = node_array->capacity * 2;
        node_array = realloc(node_array, new_capacity);
        node_array->capacity = new_capacity;
    }
    return node_array->nodes + (node_array->count++);
}

static inline off_t sql_node_index(const struct sql_node_array *restrict array, const struct sql_ast_node *restrict node)
{
    return node - array->nodes;
}

static inline off_t sql_node_index_global(const struct sql_ast_node *restrict node)
{
    return sql_node_index(node_array, node);
}

extern off_t sql_node_offset(const struct sql_ast_node *restrict node)
{
    return sql_node_index_global(node);
}

extern void sql_node_add_child(struct sql_ast_node *restrict node, const struct sql_ast_node *const restrict child)
{
    if (node != NULL && child != NULL && node->link_count < 8)
    {
        node->links[node->link_count++] = sql_node_index_global(child);
    }
}

static void print_node_tree(const struct sql_ast_node *restrict root_node)
{
    print_node(root_node, 0);
}

static void print_node(const struct sql_ast_node *restrict node, const unsigned int depth)
{
    for (unsigned int i = 0; i < depth; i++)
    {
        printf("  ");
    }
    
    if (node == NULL)
    {
        printf("NULL\n");
        return;
    }
    
    print_node_value(node);
    for (unsigned int i = 0; i < node->link_count; i++)
    {
        print_node(node_array->nodes + node->links[i], depth + 1);
    }
}

static void print_node_value(const struct sql_ast_node *restrict node)
{
    switch (node->node_type)
    {
        case sql_ast_identifier_unquoted:
        case sql_ast_identifier_quoted:
        case sql_ast_literal_numeric:
        case sql_ast_literal_string:
            printf("%s: %s\n", node_name(node->node_type), node->value.string);
            break;
        default:
            printf("%s\n", node_name(node->node_type));
            break;
    }
}

static const char *const node_name(const enum sql_ast_node_type node_type)
{
    switch (node_type)
    {
        case sql_ast_node_link:
            return "NODE-LINK";
        case sql_ast_identifier_unquoted:
        case sql_ast_identifier_quoted:
            return "IDENTIFIER";
        case sql_ast_literal_numeric:
            return "NUMERIC-LITERAL";
        case sql_ast_literal_string:
            return "STRING-LITERAL";
        case sql_ast_reference_column:
            return "COLUMN-REFERENCE";
        case sql_ast_reference_table:
            return "TABLE-REFERENCE";
        case sql_ast_reference_column_name:
            return "COLUMN-REFERENCE-NAME";
        case sql_ast_reference_table_name:
            return "TABLE-REFERENCE-NAME";
        case sql_ast_reference_schema_name:
            return "SCHEMA-REFERENCE-NAME";
        case sql_ast_expression_list:
            return "EXPRESSION-LIST";
        case sql_ast_expression:
            return "EXPRESSION";
        case sql_ast_from_item:
            return "FROM-ITEM";
        case sql_ast_abort:
            return "ABORT";
        case sql_ast_from:
            return "FROM";
        case sql_ast_load:
            return "LOAD";
        case sql_ast_rollback:
            return "ROLLBACK";
        case sql_ast_select:
            return "SELECT";
        case sql_ast_transaction:
            return "TRANSACTION";
        case sql_ast_work:
            return "WORK";
        case sql_ast_unknown:
        default:
            return "???";
    }
}

struct sql_ast_node *sql_create_node_0(const enum sql_ast_node_type node_type)
{
    struct sql_ast_node *node = sql_node_alloc();
    node->node_type = node_type;
    node->link_count = 0;
    return node;
}

struct sql_ast_node *sql_create_node_l1(const enum sql_ast_node_type node_type, const struct sql_ast_node *const restrict l0)
{
    struct sql_ast_node *node = sql_create_node_0(node_type);
    sql_node_add_child(node, l0);
    return node;
}

struct sql_ast_node *sql_create_node_l1_(const enum sql_ast_node_type node_type, const enum sql_ast_node_type t0)
{
    return sql_create_node_l1(node_type, sql_create_node_0(t0));
}

struct sql_ast_node *sql_create_node_l2(const enum sql_ast_node_type node_type, const struct sql_ast_node *const restrict l0, const struct sql_ast_node *const restrict l1)
{
    struct sql_ast_node *node = sql_create_node_0(node_type);
    sql_node_add_child(node, l0);
    sql_node_add_child(node, l1);
    return node;
}

struct sql_ast_node *sql_create_node_link(const struct sql_ast_node *const restrict value, const struct sql_ast_node *const restrict tail)
{
    return sql_create_node_l2(sql_ast_node_link, value, tail);
}

const char *sql_unquoted_identifier_string(const char *const restrict yytext)
{
    const size_t length = strlen(yytext);
    char *copy = sql_malloc(length + 1);
    memcpy(copy, yytext, length);
    copy[length] = 0;
    return copy;
}

const char *sql_literal_string(const char *const restrict yytext)
{
    // no escaping for the time being
    const size_t length = strlen(yytext);
    char *copy = sql_malloc(length - 1);
    memcpy(copy, yytext + 1, length - 2);
    copy[length - 2] = 0;
    return copy;
}

const char *sql_numeric_string(const char *const restrict yytext)
{
    const size_t length = strlen(yytext);
    char *copy = sql_malloc(length + 1);
    memcpy(copy, yytext, length);
    copy[length] = 0;
    return copy;
}