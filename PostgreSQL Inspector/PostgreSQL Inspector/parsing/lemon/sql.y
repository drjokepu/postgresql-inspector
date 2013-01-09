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
    context->parser_state->accepted = true;
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

start ::= command_list(L). { context->parser_state->root_symbol = L; }
start ::= IMPOSSIBLE WRENCH.

command_list(X) ::= command(A).                                         { X = A; }
command_list(X) ::= command(A) SYM_COMMAND_SEPARATOR.                   { X = A; }
command_list(X) ::= command(A) SYM_COMMAND_SEPAROTOR command_list(T).   { X = new_with_children(sql_symbol_command_list_tail, 2, A, T); }

command(X) ::= load(A).             { X = new_with_children(sql_symbol_command, 1, A); }
command(X) ::= rollback(A).         { X = new_with_children(sql_symbol_command, 1, A); }
command(X) ::= select(A).           { X = new_with_children(sql_symbol_command, 1, A); }

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

expression_list_1(X) ::= expression(A). { X = A; }
expression_list_1(X) ::= expression(A) SYM_EXPR_SEPARATOR expression_list_1(T). { X = new_with_children(sql_symbol_expression_list_tail, 2, A, T); }

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

