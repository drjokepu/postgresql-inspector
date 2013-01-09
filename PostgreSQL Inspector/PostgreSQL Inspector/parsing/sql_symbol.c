#include <stdio.h>
#include <stdlib.h>
#include "sql_symbol.h"
#include "lemon/sql.h"
#include "sql_lexer.h"

static inline void sql_symbol_destroy(struct sql_symbol *restrict symbol);
static const char* get_symbol_name(const enum sql_symbol_type symbol_type);

struct sql_symbol *sql_symbol_init(void)
{
    struct sql_symbol *symbol = calloc(1, sizeof(struct sql_symbol));
    symbol->symbol_type = sql_symbol_unknown;
    symbol->token_id = T_UNKNOWN;
    return symbol;
}

struct sql_symbol *sql_symbol_init_with_symbol_type(const enum sql_symbol_type symbol_type)
{
    struct sql_symbol* symbol = sql_symbol_init();
    symbol->symbol_type = symbol_type;
    return symbol;
}

struct sql_symbol *sql_symbol_init_with_token_id(const int token_id)
{
    struct sql_symbol *symbol = sql_symbol_init_with_symbol_type(get_symbol_type_by_token_id(token_id));
    symbol->token_id = token_id;
    return symbol;
}

void sql_symbol_free(struct sql_symbol *symbol)
{
    if (symbol == NULL) return;
    sql_symbol_destroy(symbol);
    free(symbol);
}

void sql_symbol_free_recursive(struct sql_symbol *symbol)
{
    if (symbol == NULL) return;
    for (unsigned int i = 0; i < symbol->child_count; i++)
    {
        sql_symbol_free_recursive(symbol->children[i]);
    }
    sql_symbol_destroy(symbol);
    free(symbol);
}

static inline void sql_symbol_destroy(struct sql_symbol *restrict symbol)
{
}

void sql_symbol_add_child(struct sql_symbol *restrict symbol, struct sql_symbol *restrict child)
{
    if (symbol->child_count + 1 < SQL_SYMBOL_MAX_CHILD_COUNT)
    {
        symbol->children[symbol->child_count++] = child;
    }
}

void print_symbol(const struct sql_symbol *restrict symbol, const char *const full_text)
{
    char value[symbol->length];
    memcpy(&value, full_text + symbol->start, symbol->length);
    value[symbol->length] = 0;
    printf("scanned: %s (%lli + %zi) %s\n", get_symbol_name(symbol->symbol_type), symbol->start, symbol->length, value);
}

enum sql_symbol_type get_symbol_type_by_token_id(const int token_id)
{
    switch (token_id)
    {
        case 0:
            return sql_symbol_eof;
        case T_ABORT:
            return sql_symbol_token_abort;
        case T_AND:
            return sql_symbol_operator_and;
        case T_COMMENT:
            return sql_symbol_comment;
        case T_FROM:
            return sql_symbol_token_from;
        case T_IDENTIFIER_QUOTED:
            return sql_symbol_identifier_quoted;
        case T_IDENTIFIER_UNQUOTED:
            return sql_symbol_identifier_unquoted;
        case T_LOAD:
            return sql_symbol_token_load;
        case T_NOT:
            return sql_symbol_operator_not;
        case T_NUMERIC_LITERAL:
            return sql_symbol_literal_numeric;
        case T_OPERATOR:
            return sql_symbol_operator;
        case T_OR:
            return sql_symbol_operator_or;
        case T_ROLLBACK:
            return sql_symbol_token_rollback;
        case T_SELECT:
            return sql_symbol_token_select;
        case T_STRING_LITERAL:
            return sql_symbol_literal_string;
        case T_SYM_ALL_FIELDS:
            return sql_symbol_all_fields;
        case T_SYM_COMMAND_SEPARATOR:
            return sql_symbol_command_separator;
        case T_SYM_EXPR_SEPARATOR:
            return sql_symbol_expression_separator;
        case T_SYM_NAME_SEPARATOR:
            return sql_symbol_name_separator;
        case T_TRANSACTION:
            return sql_symbol_token_transaction;
        case T_WORK:
            return sql_symbol_token_work;
        default:
            return sql_symbol_unknown;
    }
}

static const char* get_symbol_name(const enum sql_symbol_type symbol_type)
{
    switch (symbol_type)
    {
        case sql_symbol_all_fields:
            return "ALL_FIELDS";
        case sql_symbol_command:
            return "command";
        case sql_symbol_command_list_tail:
            return "command_list_tail";
        case sql_symbol_comment:
            return "comment";
        case sql_symbol_expression_list_tail:
            return "sql_symbol_expression_list_tail";
        case sql_symbol_from_list_tail:
            return "from_list_tail";
        case sql_symbol_command_separator:
            return "COMMAND_SEPARATOR";
        case sql_symbol_expression_separator:
            return "EXPRESSION_SEPARATOR";
        case sql_symbol_identifier_quoted:
            return "IDENTIFIER_QUOTED";
        case sql_symbol_identifier_unquoted:
            return "IDENTIFIER_UNQUOTED";
        case sql_symbol_literal_numeric:
            return "LITERAL_NUMERIC";
        case sql_symbol_literal_string:
            return "LITERAL_STRING";
        case sql_symbol_name_separator:
            return "NAME_SEPARATOR";
        case sql_symbol_token_abort:
            return "ABORT";
        case sql_symbol_token_from:
            return "FROM";
        case sql_symbol_token_load:
            return "LOAD";
        case sql_symbol_token_rollback:
            return "ROLLBACK";
        case sql_symbol_token_select:
            return "SELECT";
        case sql_symbol_token_transaction:
            return "TRANSACTION";
        case sql_symbol_token_work:
            return "WORK";
        case sql_symbol_unknown:
        default:
            return "unknown";
    }
}