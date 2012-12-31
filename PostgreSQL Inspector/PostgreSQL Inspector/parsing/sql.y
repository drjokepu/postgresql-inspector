%name-prefix="sql_yy"
%error-verbose
%defines
%start root

%{
#include <stdio.h>
#include "sql_parse.h"

#define WITH_TYPE(c, t) (c->node_type = t, c)
#define WITH_CHILD(parent, c1) (parent->links[parent->link_count++] = sql_node_offset(c1), parent)
#define WITH_CHILD_2(parent, c1, c2) (WITH_CHILD(WITH_CHILD(parent, c1), c2))
#define WITH_CHILD_3(parent, c1, c2, c3) (WITH_CHILD(WITH_CHILD_2(parent, c1, c2), c3))
#define NEW(t) (sql_create_node_0(t))
#define NEW_WITH_CHILD(t, c1) (node_new_with_child_1(t, c1))
#define NEW_WITH_CHILD_2(t, c1, c2) (node_new_with_child_2(t, c1, c2))
#define NEW_WITH_CHILD_3(t, c1, c2, c3) (node_new_with_child_3(t, c1, c2, c3))

static void yyerror(char const *s);
extern int yylex(void);

static struct sql_ast_node* node_new_with_child_1(
    enum sql_ast_node_type type,
    const struct sql_ast_node *const restrict child_1);
    
static struct sql_ast_node* node_new_with_child_2(
    enum sql_ast_node_type type,
    const struct sql_ast_node *const restrict child_1,
    const struct sql_ast_node *const restrict child_2);
    
static struct sql_ast_node* node_new_with_child_3(
    enum sql_ast_node_type type, const struct sql_ast_node *const restrict child_1,
    const struct sql_ast_node *const restrict child_2,
    const struct sql_ast_node *const restrict child_3);
    
%}

%token T_ABORT
%token T_LOAD
%token T_ROLLBACK
%token T_SELECT
%token T_WORK
%token T_TRANSACTION

%token T_SYM_COMMAND_SEPARATOR
%token T_SYM_EXPR_SEPARATOR
%token T_SYM_NAME_SEPARATOR

%token T_STRING_LITERAL
%token T_NUMERIC_LITERAL

%token T_IDENTIFIER_UNQUOTED
%token T_IDENTIFIER_QUOTED

%%

root:
    commands                    { sql_parse_result = $1; }
;

commands:
    command                                     { $$ = $1; }
  | command T_SYM_COMMAND_SEPARATOR             { $$ = $1; }
  | command T_SYM_COMMAND_SEPARATOR commands    { $$ = sql_create_node_link($1, $3); }
;

command:
    load
  | rollback
  | select
;

load:
    T_LOAD T_STRING_LITERAL     { $$ = WITH_CHILD($1, $2); }
;

rollback:
    T_ABORT                     { $$ = $1; }
  | T_ABORT T_WORK              { $$ = WITH_CHILD($1, $2); }
  | T_ABORT T_TRANSACTION       { $$ = WITH_CHILD($1, $2); }
  | T_ROLLBACK                  { $$ = $1; }
  | T_ROLLBACK T_WORK           { $$ = WITH_CHILD($1, $2); }
  | T_ROLLBACK T_TRANSACTION    { $$ = WITH_CHILD($1, $2); }
;

select:
    select_body                 { $$ = $1; }
    
select_body:
    T_SELECT expression_list    { $$ = WITH_CHILD($1, $2); }
;

expression_list:
    expression_list_1           { $$ = NEW_WITH_CHILD(sql_ast_expression_list, $1); }
;

expression_list_1:
    expression                                          { $$ = $1; }
  | expression T_SYM_EXPR_SEPARATOR expression_list_1   { $$ = sql_create_node_link($1, $3); }
;

expression:
    constant                    { $$ = $1; }
  | column_reference            { $$ = $1; }
;
    
constant:
    T_STRING_LITERAL            { $$ = $1; }
  | T_NUMERIC_LITERAL           { $$ = $1; }
;

column_reference:
    identifier { $$ = NEW_WITH_CHILD(sql_ast_reference_column, NEW_WITH_CHILD(sql_ast_reference_column_name, $1)); }
  | identifier T_SYM_NAME_SEPARATOR identifier { $$ = NEW_WITH_CHILD_2(sql_ast_reference_column, NEW_WITH_CHILD(sql_ast_reference_table_name, $1), NEW_WITH_CHILD(sql_ast_reference_column_name, $3)); }
  | identifier T_SYM_NAME_SEPARATOR identifier T_SYM_NAME_SEPARATOR identifier { $$ = NEW_WITH_CHILD_3(sql_ast_reference_column, NEW_WITH_CHILD(sql_ast_reference_schema_name, $1), NEW_WITH_CHILD(sql_ast_reference_table_name, $3), NEW_WITH_CHILD(sql_ast_reference_column_name, $5)); }
;

identifier:
    T_IDENTIFIER_UNQUOTED       { $$ = $1; }
  | T_IDENTIFIER_QUOTED         { $$ = $1; }
;

%%

static void yyerror(char const *s)
{
//    static unsigned int error_number = 0;
//    fprintf (stderr, "%u: %s\n", (++error_number), s);
}

static struct sql_ast_node* node_new_with_child_1(enum sql_ast_node_type type, const struct sql_ast_node *const restrict child_1)
{
    struct sql_ast_node *parent = NEW(type);
    parent = WITH_CHILD(parent, child_1);
    return parent;
}

static struct sql_ast_node* node_new_with_child_2(enum sql_ast_node_type type, const struct sql_ast_node *const restrict child_1, const struct sql_ast_node *const restrict child_2)
{
    struct sql_ast_node *parent = NEW(type);
    parent = WITH_CHILD(parent, child_1);
    parent = WITH_CHILD(parent, child_2);
    return parent;
}

static struct sql_ast_node* node_new_with_child_3(enum sql_ast_node_type type, const struct sql_ast_node *const restrict child_1, const struct sql_ast_node *const restrict child_2, const struct sql_ast_node *const restrict child_3)
{
    struct sql_ast_node *parent = NEW(type);
    parent = WITH_CHILD(parent, child_1);
    parent = WITH_CHILD(parent, child_2);
    parent = WITH_CHILD(parent, child_3);
    return parent;
}

#undef yylex
#undef yyerror