%name-prefix="sql_yy"
%error-verbose
%defines
%start root

%{
#include <stdio.h>
#include "sql_parse.h"

#define WITH_CHILD(parent, c1) (parent->links[parent->link_count++] = sql_node_offset(c1), parent)


static void yyerror(char const *s);
extern int yylex(void);

%}

%token T_ABORT
%token T_LOAD
%token T_ROLLBACK
%token T_SELECT
%token T_WORK
%token T_TRANSACTION

%token T_SYM_COMMAND_SEPARATOR
%token T_SYM_EXPR_SEPARATOR

%token T_STRING_LITERAL
%token T_NUMERIC_LITERAL

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
    expression                                          { $$ = $1; }
  | expression T_SYM_EXPR_SEPARATOR expression_list     { $$ = sql_create_node_link($1, $3); }

expression:
    constant                    { $$ = $1; }
;
    
constant:
    T_STRING_LITERAL            { $$ = $1; }
  | T_NUMERIC_LITERAL           { $$ = $1; }
;

%%

static void yyerror(char const *s)
{
//    static unsigned int error_number = 0;
//    fprintf (stderr, "%u: %s\n", (++error_number), s);
}

#undef yylex
#undef yyerror