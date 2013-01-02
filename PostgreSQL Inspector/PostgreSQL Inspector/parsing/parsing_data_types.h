#ifndef __PARSING_DATA_TYPES_H__
#define __PARSING_DATA_TYPES_H__

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

enum sql_token_type
{
    sql_token_type_identifier,
    sql_token_type_literal,
    sql_token_type_keyword,
    sql_token_type_unknown
};

struct sql_ast_location
{
    off_t start;
    off_t length;
};

#endif /* __PARSING_DATA_TYPES_H__ */