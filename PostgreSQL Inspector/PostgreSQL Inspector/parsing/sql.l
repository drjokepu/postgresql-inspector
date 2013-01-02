%option prefix="sql_yy"
%option case-insensitive
%option bison-locations
%option yylineno
%{
    #include "sql_parse.h"
    #include "y.tab.h"
    
    static yy_size_t yycolumn = 1;
    
    #define YY_USER_ACTION sql_yylloc.first_line = sql_yylloc.last_line = yylineno; sql_yylloc.first_column = (int)yycolumn; sql_yylloc.last_column = (int)(yycolumn + yyleng - 1); yycolumn += yyleng;

    static const char *sql_input = NULL;
    static unsigned int sql_input_offset = 0;
    static unsigned int sql_input_length = 0;
    static void sql_lexer_static_init(void);
    extern void sql_lexer_static_destroy(void);
    extern void sql_lexer_init_with_input(const char *const restrict input);
    
    static off_t first_byte(YYLTYPE location);
    static inline unsigned int min_ui(const unsigned int a, const unsigned int b);
    static int sql_read_input(char *restrict buffer, yy_size_t *restrict num_bytes_read, const yy_size_t max_bytes_to_read);
    static inline int yywrap(void);
    static enum yytokentype set_token(const enum yytokentype token_type, off_t start, size_t length);
    static enum yytokentype set_token_with_unquoted_identifier(const enum yytokentype token_type, off_t start, size_t length, const char* string_value);
    static enum yytokentype set_token_with_string(const enum yytokentype token_type, off_t start, size_t length, const char* string_value);
    static enum yytokentype set_token_with_numeric(const enum yytokentype token_type, off_t start, size_t length, const char* string_value);
    static enum sql_ast_node_type nt(const enum yytokentype token);
    
    #undef YY_USER_INIT
    #define YY_USER_INIT sql_lexer_static_init()

    #undef YY_INPUT
    #define YY_INPUT(b,r,s) sql_read_input((b), &(r), s)
    
    #define T(token) return set_token(token, first_byte(sql_yylloc), (size_t)yyleng)
    #define T_ID_UQ(token, string_value) return set_token_with_unquoted_identifier(token, first_byte(sql_yylloc), (size_t)yyleng, string_value)
    #define T_STR(token, string_value) return set_token_with_string(token, first_byte(sql_yylloc), (size_t)yyleng, string_value)
    #define T_NUM(token, string_value) return set_token_with_numeric(token, first_byte(sql_yylloc), (size_t)yyleng, string_value)
%}

digit   [0-9]

%%

"abort"             { T(T_ABORT); }
"from"              { T(T_FROM); }
"load"              { T(T_LOAD); }
"rollback"          { T(T_ROLLBACK); }
"select"            { T(T_SELECT); }
"transaction"       { T(T_TRANSACTION); }
"work"              { T(T_WORK); }

";"                 { T(T_SYM_COMMAND_SEPARATOR); }
","                 { T(T_SYM_EXPR_SEPARATOR); }
"."                 { T(T_SYM_NAME_SEPARATOR); }
"*"                 { T(T_SYM_ALL_FIELDS); }

[ \t\n\r]

\'((\'\')|[^\'])*\'      { T_STR(T_STRING_LITERAL, yytext); }
{digit}+                 { T_NUM(T_NUMERIC_LITERAL, yytext); }

[a-z_][a-z0-9_$]*        { T_ID_UQ(T_IDENTIFIER_UNQUOTED, yytext); }

%%

static void sql_lexer_static_init(void)
{
    yyout = fopen("/dev/null", "w");
}

static inline int yywrap(void)
{
    return 1;
}

void sql_lexer_init_with_input(const char *const restrict input)
{
    sql_input = input;
    sql_input_offset = 0;
    sql_input_length = (unsigned int)strlen(input);
    yycolumn = 1;
}

void sql_lexer_static_destroy(void)
{
    if (yyout != stdout && yyout != NULL)
    {
        fclose(yyout);
        yyout = NULL;
    }
}

static off_t first_byte(YYLTYPE location)
{
//    printf("location: (%i, %i, %i, %i)\n", location.first_line - 1, location.first_column - 1, location.last_line - 1, location.last_column - 1);

    return line_positions->positions[location.first_line - 1] + location.first_column - 1;
}

static int sql_read_input(char *restrict buffer, yy_size_t *restrict num_bytes_read, const yy_size_t max_bytes_to_read)
{
    const unsigned int bytes_remaining = sql_input_length - sql_input_offset;
    const unsigned int num_bytes_to_read = min_ui((unsigned int)max_bytes_to_read, bytes_remaining);
    memcpy(buffer, sql_input + sql_input_offset, (size_t)num_bytes_to_read);
    *num_bytes_read = (int)num_bytes_to_read;
    sql_input_offset += num_bytes_to_read;

    return num_bytes_to_read;
}

static inline unsigned int min_ui(const unsigned int a, const unsigned int b)
{
    return a < b ? a : b;
}

static enum yytokentype set_token(const enum yytokentype token_type, off_t start, size_t length)
{
    sql_yylval = sql_create_node_0(nt(token_type));
    sql_yylval->start = start;
    sql_yylval->length = length;
    return token_type;
}

static enum yytokentype set_token_with_unquoted_identifier(const enum yytokentype token_type, off_t start, size_t length, const char* string_value)
{
    set_token(token_type, start, length);
    sql_yylval->value.string = sql_unquoted_identifier_string(string_value);
    return token_type;
}

static enum yytokentype set_token_with_string(const enum yytokentype token_type, off_t start, size_t length, const char* string_value)
{
    set_token(token_type, start, length);
    sql_yylval->value.string = sql_literal_string(string_value);
    return token_type;
}

static enum yytokentype set_token_with_numeric(const enum yytokentype token_type, off_t start, size_t length, const char* string_value)
{
    set_token(token_type, start, length);
    sql_yylval->value.string = sql_numeric_string(string_value);
    return token_type;
}

static enum sql_ast_node_type nt(const enum yytokentype token)
{
    switch (token)
    {
        case T_ABORT:
            return sql_ast_abort;
        case T_IDENTIFIER_QUOTED:
            return sql_ast_identifier_quoted;
        case T_IDENTIFIER_UNQUOTED:
            return sql_ast_identifier_unquoted;
        case T_LOAD:
            return sql_ast_load;
        case T_FROM:
            return sql_ast_from;
        case T_NUMERIC_LITERAL:
            return sql_ast_literal_numeric;
        case T_ROLLBACK:
            return sql_ast_rollback;
        case T_SELECT:
            return sql_ast_select;
        case T_STRING_LITERAL:
            return sql_ast_literal_string;
        case T_SYM_ALL_FIELDS:
            return sql_ast_reference_all_fields;
        case T_WORK:
            return sql_ast_work;
        case T_TRANSACTION:
            return sql_ast_transaction;
        default:
            return sql_ast_unknown;
    }
}


#undef yylex