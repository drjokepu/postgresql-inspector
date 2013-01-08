#ifndef __SQL_SYMBOL_H__
#define __SQL_SYMBOL_H__

#include <sys/types.h>

#define SQL_SYMBOL_MAX_CHILD_COUNT 8
#define SQL_SYMBOL_ALLOCATION_TABLE_INITIAL_CAPACITY 1024

enum sql_symbol_type
{
    sql_symbol_command,
    sql_symbol_command_list_tail,
    sql_symbol_expression_list_tail,
    sql_symbol_from_list_tail,
    sql_symbol_identifier_quoted,
    sql_symbol_identifier_unquoted,
    sql_symbol_literal_numeric,
    sql_symbol_literal_string,
    sql_symbol_all_fields,
    sql_symbol_command_separator,
    sql_symbol_expression_separator,
    sql_symbol_name_separator,
    sql_symbol_eof,
    sql_symbol_column_reference,
    sql_symbol_table_reference,
    sql_symbol_token_abort,
    sql_symbol_token_load,
    sql_symbol_token_from,
    sql_symbol_token_rollback,
    sql_symbol_token_select,
    sql_symbol_token_transaction,
    sql_symbol_token_work,
    sql_symbol_unknown
};

enum sql_token_type
{
    sql_token_type_identifier,
    sql_token_type_literal,
    sql_token_type_keyword,
    sql_token_type_unknown
};

struct sql_symbol
{
    int token_id;
    enum sql_symbol_type symbol_type;
    off_t start;
    size_t length;
    unsigned int child_count;
    struct sql_symbol *children[SQL_SYMBOL_MAX_CHILD_COUNT];
};

extern struct sql_symbol *sql_symbol_init(void);
extern struct sql_symbol *sql_symbol_init_with_symbol_type(const enum sql_symbol_type symbol_type);
extern struct sql_symbol *sql_symbol_init_with_token_id(const int token_id);

extern void sql_symbol_free(struct sql_symbol *symbol);
extern void sql_symbol_free_recursive(struct sql_symbol *symbol);

void sql_symbol_add_child(struct sql_symbol *restrict symbol, struct sql_symbol *restrict child);
enum sql_symbol_type get_symbol_type_by_token_id(const int token_id);
void print_symbol(const struct sql_symbol *restrict symbol, const char *const full_text);

#endif /* __SQL_SYMBOL_H__ */