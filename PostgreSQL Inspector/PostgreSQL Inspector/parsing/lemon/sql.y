%name SqlParse
%token_prefix T_

%default_type       { struct sql_symbol* }
%token_type         { struct sql_symbol* }
%default_destructor { sql_symbol_free($$); }
%token_destructor   { sql_symbol_free($$); }

%start_symbol start
%extra_argument { struct sql_context* context }

%include {
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include "../sql_context.h"
#include "../sql_symbol.h"
#include "functions.h"
#include "sql.h"

}

%parse_accept {
    if (context->accept_grammar)
    {
        context->parser_state->accepted = true;
    }
}

%parse_failure {
    context->parser_state->accepted = true;
}

%syntax_error {
    context->parser_state->has_error = true;
    if (context->report_errors)
    {
        const int n = sizeof(yyTokenName) / sizeof(yyTokenName[0]);
        for (int i = 0; i < n; i++)
        {
            const int a = yy_find_shift_action(yypParser, (YYCODETYPE)i);
            if (a < YYNSTATE + YYNRULE)
            {
                sql_context_possible_token_list_add_token(context->parser_state->possible_token_list, i);
                //printf("possible token: %s\n", yyTokenName[i]);
            }
        }
    }
}

%nonassoc COMMENT.
%nonassoc WRENCH.

start ::= command_list(L). { if (context->accept_grammar) { context->parser_state->root_symbol = L; } }

command_list(X) ::= command(A).                                         { X = A; }
command_list(X) ::= command(A) SYM_COMMAND_SEPARATOR.                   { X = A; }
command_list(X) ::= command(A) SYM_COMMAND_SEPARATOR command_list(T).   { X = new_with_children(sql_symbol_command_list_tail, 2, A, T); }

command(X) ::= begin(A).            { X = new_with_children(sql_symbol_command, 1, A); }
command(X) ::= commit(A).           { X = new_with_children(sql_symbol_command, 1, A); }
command(X) ::= load(A).             { X = new_with_children(sql_symbol_command, 1, A); }
command(X) ::= rollback(A).         { X = new_with_children(sql_symbol_command, 1, A); }
command(X) ::= select(A).           { X = new_with_children(sql_symbol_command, 1, A); }
command(X) ::= show(A).             { X = new_with_children(sql_symbol_command, 1, A); }
command(X) ::= table(A).            { X = new_with_children(sql_symbol_command, 1, A); }

load ::= LOAD STRING_LITERAL.

rollback(X) ::= ABORT(A).                   { X = A; }
rollback(X) ::= ABORT(A) WORK(B).           { X = with_children(A, 1, B); }
rollback(X) ::= ABORT(A) TRANSACTION(B).    { X = with_children(A, 1, B); }
rollback(X) ::= ROLLBACK(A).                { X = A; }
rollback(X) ::= ROLLBACK(A) WORK(B).        { X = with_children(A, 1, B); }
rollback(X) ::= ROLLBACK(A) TRANSACTION(B). { X = with_children(A, 1, B); }

select(X) ::= select_body(A). { X = A; }

select_body(X) ::= SELECT(SEL) expression_list(COL) from_clause(FROM). { X = with_children(SEL, 2, COL, FROM); }

expression_list(X) ::= expression_list_1(A). { X = A; }

expression_list_1(X) ::= expression_op(A). { X = A; }
expression_list_1(X) ::= expression_op(A) SYM_EXPR_SEPARATOR expression_list_1(T). { X = new_with_children(sql_symbol_expression_list_tail, 2, A, T); }

expression_op(X) ::= expression_op(A) operator(O) expression(B). { X = new_with_children(sql_symbol_operator_expression, 3, A, O, B); }
expression_op(X) ::= expression_op(A) operator(O). { X = new_with_children(sql_symbol_operator_expression, 2, A, O); }
expression_op(X) ::= operator(O) expression(A). { X = new_with_children(sql_symbol_operator_expression, 2, O, A); }
expression_op(X) ::= expression(A).     { X = A; }

expression(X) ::= constant(A).          { X = A; }
expression(X) ::= column_reference(A).  { X = A; }

from_clause(X) ::= FROM(A) from_item_list(B). { X = with_children(A, 1, B); }
from_clause ::= .

from_item_list(X) ::= from_item(A). { X = A; }
from_item_list(X) ::= from_item(A) SYM_EXPR_SEPARATOR from_item_list(T). { X = new_with_children(sql_symbol_from_list_tail, 2, A, T); }

from_item(X) ::= from_item_table(A). { X = A; }

from_item_table(X) ::= table_reference(A). { X = A; }

column_reference(X) ::= identifier(A). { X = new_with_children(sql_symbol_column_reference, 1, A); }
column_reference(X) ::= identifier(A) SYM_NAME_SEPARATOR identifier(B). { X = new_with_children(sql_symbol_column_reference, 2, A, B); }
column_reference(X) ::= identifier(A) SYM_NAME_SEPARATOR identifier(B) SYM_NAME_SEPARATOR identifier(C). { X = new_with_children(sql_symbol_column_reference, 3, A, B, C); }
column_reference(X) ::= SYM_ALL_FIELDS(A). { X = new_with_children(sql_symbol_column_reference, 1, A); }
column_reference(X) ::= identifier(A) SYM_NAME_SEPARATOR SYM_ALL_FIELDS(B). { X = new_with_children(sql_symbol_column_reference, 2, A, B); }
column_reference(X) ::= identifier(A) SYM_NAME_SEPARATOR identifier(B) SYM_NAME_SEPARATOR SYM_ALL_FIELDS(C). { X = new_with_children(sql_symbol_column_reference, 3, A, B, C); }

table_reference(X) ::= identifier(A). { X = new_with_children(sql_symbol_table_reference, 1, A); }
table_reference(X) ::= identifier(A) SYM_NAME_SEPARATOR identifier(B). { X = new_with_children(sql_symbol_table_reference, 2, A, B); }

constant(X) ::= STRING_LITERAL(A).        { X = A; }
constant(X) ::= NUMERIC_LITERAL(A).       { X = A; }

identifier(X) ::= IDENTIFIER_UNQUOTED(A). { X = A; }
identifier(X) ::= IDENTIFIER_QUOTED(A).   { X = A; }

operator(X) ::= OPERATOR(A).    { X = A; }
operator(X) ::= AND(A).         { X = A; }
operator(X) ::= OR(A).          { X = A; }
operator(X) ::= NOT(A).         { X = A; }

begin(X) ::= BEGIN(A) transaction_mode_list(B).                 { X = with_children(A, 1, B); }
begin(X) ::= BEGIN(A) WORK(B) transaction_mode_list(C).         { X = with_children(A, 2, B, C); }
begin(X) ::= BEGIN(A) TRANSACTION(B) transaction_mode_list(C).  { X = with_children(A, 2, B, C); }

commit(X) ::= COMMIT(A).                { X = A; }
commit(X) ::= COMMIT(A) WORK(B).        { X = with_children(A, 1, B); }
commit(X) ::= COMMIT(A) TRANSACTION(B). { X = with_children(A, 1, B); }
commit(X) ::= END(A).                   { X = A; }
commit(X) ::= END(A) WORK(B).           { X = with_children(A, 1, B); }
commit(X) ::= END(A) TRANSACTION(B).    { X = with_children(A, 1, B); }

transaction_mode_list ::= .
transaction_mode_list(X) ::= transaction_mode_list_1(A). { X = A; }

transaction_mode_list_1(X) ::= transaction_mode(A). { X = A; }
transaction_mode_list_1(X) ::= transaction_mode(A) SYM_EXPR_SEPARATOR transaction_mode_list_1(T). { X = new_with_children(sql_symbol_transaction_mode_list_tail, 2, A, T); }

transaction_mode(X) ::= ISOLATION(A) LEVEL(B) isolation_level(C).   { X = with_children(A, 2, B, C); }
transaction_mode(X) ::= READ(A) ONLY(B).                            { X = with_children(A, 1, B); }
transaction_mode(X) ::= READ(A) WRITE(B).                           { X = with_children(A, 1, B); }
transaction_mode(X) ::= DEFERRABLE(A).                              { X = A; }
transaction_mode(X) ::= NOT(A) DEFERRABLE(B).                       { X = with_children(A, 1, B); }

isolation_level(X) ::= SERIALIZABLE(A).         { X = A; }
isolation_level(X) ::= REPEATABLE(A) READ(B).   { X = with_children(A, 1, B); }
isolation_level(X) ::= READ(A) COMMITTED(B).    { X = with_children(A, 1, B); }
isolation_level(X) ::= READ(A) UNCOMMITTED(B).  { X = with_children(A, 1, B); }

show(X) ::= SHOW(A) ALL(B).         { X = with_children(A, 1, B); }
show(X) ::= SHOW(A) identifier(B).  { X = with_children(A, 1, B); }

table(X) ::= TABLE(T) ONLY(O) table_reference(N) SYM_ALL_FIELDS(S). { X = with_children(T, 3, O, N, S); }
table(X) ::= TABLE(T) ONLY(O) table_reference(N).                   { X = with_children(T, 2, O, N); }
table(X) ::= TABLE(T) table_reference(N) SYM_ALL_FIELDS(S).         { X = with_children(T, 2, N, S); }
table(X) ::= TABLE(T) table_reference(N).                           { X = with_children(T, 1, N); }
