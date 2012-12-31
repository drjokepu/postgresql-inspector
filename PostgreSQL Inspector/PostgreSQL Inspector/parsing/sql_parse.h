//
//  sql_parse.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 27/12/2012.
//
//

#ifndef PostgreSQL_Inspector_sql_parse_h
#define PostgreSQL_Inspector_sql_parse_h

#include <stdio.h>
#include <string.h>
#include "parsing.h"

#define YYSTYPE struct sql_ast_node*

enum sql_ast_node_type
{
    sql_ast_node_link,
    sql_ast_identifier_unquoted,
    sql_ast_identifier_quoted,
    sql_ast_literal_numeric,
    sql_ast_literal_string,
    sql_ast_reference_column,
    sql_ast_reference_table,
    sql_ast_reference_column_name,
    sql_ast_reference_table_name,
    sql_ast_reference_schema_name,
    sql_ast_reference_all_fields,
    sql_ast_from_item,
    sql_ast_expression_list,
    sql_ast_expression,
    sql_ast_abort,
    sql_ast_from,
    sql_ast_load,
    sql_ast_rollback,
    sql_ast_select,
    sql_ast_transaction,
    sql_ast_work,
    sql_ast_unknown
};

struct sql_ast_node
{
    enum sql_ast_node_type node_type;
    unsigned int link_count;
    off_t links[8];
    union
    {
        const char *string;
    } value;
};

struct sql_node_array
{
    size_t count;
    size_t capacity;
    struct sql_ast_node nodes[];
};

struct sql_allocations
{
    size_t count;
    size_t capacity;
    void *list[];
};

extern void sql_lexer_init_with_input(const char *const restrict input);
extern void sql_lexer_static_destroy(void);

extern int sql_yyparse(void);
extern struct sql_ast_node *sql_parse_result;

extern off_t sql_node_offset(const struct sql_ast_node *restrict node);
extern void sql_node_add_child(struct sql_ast_node *restrict node, const struct sql_ast_node *const restrict child);

extern struct sql_ast_node *sql_create_node_0(const enum sql_ast_node_type node_type);
struct sql_ast_node *sql_create_node_l1(const enum sql_ast_node_type node_type,
                                        const struct sql_ast_node *const restrict l0);
struct sql_ast_node *sql_create_node_l2(const enum sql_ast_node_type node_type,
                                        const struct sql_ast_node *const restrict l0,
                                        const struct sql_ast_node *const restrict l1);
struct sql_ast_node *sql_create_node_l1_(const enum sql_ast_node_type node_type,
                                         const enum sql_ast_node_type t0);
extern struct sql_ast_node *sql_create_node_link(const struct sql_ast_node *const restrict value, const struct sql_ast_node *const restrict tail);

extern const char *sql_unquoted_identifier_string(const char *const restrict yytext);
extern const char *sql_literal_string(const char *const restrict yytext);
extern const char *sql_numeric_string(const char *const restrict yytext);

#endif
