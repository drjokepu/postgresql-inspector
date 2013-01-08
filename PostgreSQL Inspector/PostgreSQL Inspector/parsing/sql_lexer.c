#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "sql_lexer.h"
#include "lemon/sql.h"

struct token_lookup_item
{
    char *text;
    int value;
};

static const struct token_lookup_item const token_lookup[] =
{
    (struct token_lookup_item){ .text = ";", .value = T_SYM_COMMAND_SEPARATOR },
    (struct token_lookup_item){ .text = ".", .value = T_SYM_NAME_SEPARATOR },
    (struct token_lookup_item){ .text = ",", .value = T_SYM_EXPR_SEPARATOR },
    (struct token_lookup_item){ .text = "*", .value = T_SYM_ALL_FIELDS },
    (struct token_lookup_item){ .text = "ABORT", .value = T_ABORT },
    (struct token_lookup_item){ .text = "FROM", .value = T_FROM },
    (struct token_lookup_item){ .text = "LOAD", .value = T_LOAD },
    (struct token_lookup_item){ .text = "ROLLBACK", .value = T_ROLLBACK },
    (struct token_lookup_item){ .text = "SELECT", .value = T_SELECT },
    (struct token_lookup_item){ .text = "TRANSACTION", .value = T_TRANSACTION },
    (struct token_lookup_item){ .text = "WORK", .value = T_WORK },
};

static const size_t token_lookup_count = sizeof(token_lookup) / sizeof(struct token_lookup_item);

static inline bool is_eof(const struct sql_lexer *const restrict lexer);
static inline bool is_whitespace(const char c);
static inline bool is_digit(const char c);

static inline char peek(const struct sql_lexer *const restrict lexer);
static inline char char_to_upper(const char input);
static inline void skip_whitespace(struct sql_lexer *restrict lexer);

static int sql_lexer_scan_keyword(struct sql_lexer *restrict lexer, off_t *restrict out_start, size_t *restrict out_length);
static int sql_lexer_scan_identifier(struct sql_lexer *restrict lexer, off_t *restrict out_start, size_t *restrict out_length);
static int sql_lexer_scan_identifier_unquoted(struct sql_lexer *restrict lexer, off_t *restrict out_start, size_t *restrict out_length);
static int sql_lexer_scan_identifier_quoted(struct sql_lexer *restrict lexer, off_t *restrict out_start, size_t *restrict out_length);
static int sql_lexer_scan_literal(struct sql_lexer *restrict lexer, off_t *restrict out_start, size_t *restrict out_length);
static int sql_lexer_scan_numeric_literal(struct sql_lexer *restrict lexer, off_t *restrict out_start, size_t *restrict out_length);
static int sql_lexer_scan_string_literal(struct sql_lexer *restrict lexer, off_t *restrict out_start, size_t *restrict out_length);

struct sql_lexer *sql_lexer_init(const char *const restrict text)
{
    struct sql_lexer *lexer = malloc(sizeof(struct sql_lexer));
    lexer->text = strdup(text);
    lexer->length = strlen(text);
    lexer->position = 0;
    
    return lexer;
}

void sql_lexer_free(struct sql_lexer *lexer)
{
    if (lexer == NULL) return;
    if (lexer->text != NULL)
        free(lexer->text);
    
    free(lexer);
}

static inline bool is_eof(const struct sql_lexer *const restrict lexer)
{
    return (lexer == NULL) || (lexer->position >= lexer->length);
}

bool sql_lexer_is_eof(const struct sql_lexer *const restrict lexer)
{
    return is_eof(lexer);
}

static inline bool is_whitespace(const char c)
{
    return c == 0 || c == '\n' || c == '\r' || c == '\t' || c == ' ';
}

static inline bool is_digit(const char c)
{
    return c >= '0' && c < '9';
}

static inline char peek(const struct sql_lexer *const restrict lexer)
{
    if (!is_eof(lexer))
        return lexer->text[lexer->position];
    else
        return 0;
}

static char char_to_upper(const char input)
{
    if (input >= 'a' && input <= 'z')
        return input - ('a' - 'A');
    else
        return input;
}

int sql_lexer_get_next_token(struct sql_lexer *restrict lexer, off_t *restrict out_start, size_t *restrict out_length)
{
    skip_whitespace(lexer);
    if (is_eof(lexer)) return T_EOF;
    
    const int keyword_token_id = sql_lexer_scan_keyword(lexer, out_start, out_length);
    if (keyword_token_id > 0)
        return keyword_token_id;
    
    const int identifier_token_id = sql_lexer_scan_identifier(lexer, out_start, out_length);
    if (identifier_token_id > 0)
        return identifier_token_id;
    
    const int literal_token_id = sql_lexer_scan_literal(lexer, out_start, out_length);
    if (literal_token_id > 0)
        return literal_token_id;
    
    return T_UNKNOWN;
}

static inline void skip_whitespace(struct sql_lexer *restrict lexer)
{
    while (!is_eof(lexer) && is_whitespace(peek(lexer))) lexer->position++;
}

static int sql_lexer_scan_keyword(struct sql_lexer *restrict lexer, off_t *restrict out_start, size_t *restrict out_length)
{
    bool unacceptable_tokens[token_lookup_count];
    bzero(&unacceptable_tokens, sizeof(unacceptable_tokens));
    
    for(off_t position = lexer->position; position <= lexer->length; position++)
    {
        for (unsigned int i = 0; i < token_lookup_count; i++)
        {
            if (!unacceptable_tokens[i])
            {
                const char token_char = token_lookup[i].text[position - lexer->position];
                const char input_char = char_to_upper(lexer->text[position]);
                
                if (token_char == 0 && is_whitespace(input_char))
                {
                    *out_start = lexer->position;
                    *out_length = position - lexer->position;
                    lexer->position = position;
                    return token_lookup[i].value;
                }
                else if (token_char != input_char)
                {
                    unacceptable_tokens[i] = true;
                }
                else if (input_char != 0 && token_char != 0 && token_lookup[i].text[position - lexer->position + 1] == 0)
                {
                    const char next_char = char_to_upper(lexer->text[position + 1]);
                    if ((next_char < 'A' || next_char > 'Z') &&
                        (next_char < '0' || next_char > '9'))
                    {
                        position++;
                        *out_start = lexer->position;
                        *out_length = position - lexer->position;
                        lexer->position = position;
                        return token_lookup[i].value;
                    }
                }
            }
        }
    }
    
    return T_UNKNOWN;
}

static int sql_lexer_scan_identifier(struct sql_lexer *restrict lexer, off_t *restrict out_start, size_t *restrict out_length)
{
    const int unquoted_identifier_token_id = sql_lexer_scan_identifier_unquoted(lexer, out_start, out_length);
    if (unquoted_identifier_token_id > 0)
        return unquoted_identifier_token_id;
    
    const int quoted_identifier_token_id = sql_lexer_scan_identifier_quoted(lexer, out_start, out_length);
    if (quoted_identifier_token_id > 0)
        return quoted_identifier_token_id;
    
    return T_UNKNOWN;
}

static int sql_lexer_scan_identifier_unquoted(struct sql_lexer *restrict lexer, off_t *restrict out_start, size_t *restrict out_length)
{
    for(off_t position = lexer->position; position <= lexer->length; position++)
    {
        const char input_char = char_to_upper(lexer->text[position]);
        if (is_whitespace(input_char))
        {
            if (position != lexer->position)
            {
                *out_start = lexer->position;
                *out_length = position - lexer->position;
                lexer->position = position;
                return T_IDENTIFIER_UNQUOTED;
            }
        }
        else
        {
            if (position == lexer->position) // first character
            {
                // [A-Z_]
                if ((input_char < 'A' || input_char > 'Z') && input_char != '_')
                {
                    return T_UNKNOWN;
                }
            }
            else
            {
                // [A-Z0-9_$]
                if ((input_char < 'A' || input_char > 'Z') &&
                    (input_char < '0' || input_char > '9') &&
                    input_char != '_' &&
                    input_char != '&')
                {
                    *out_start = lexer->position;
                    *out_length = position - lexer->position;
                    lexer->position = position;
                    return T_IDENTIFIER_UNQUOTED;
                }
            }
        }
    }
    return T_UNKNOWN;
}

static int sql_lexer_scan_identifier_quoted(struct sql_lexer *restrict lexer, off_t *restrict out_start, size_t *restrict out_length)
{
    if (peek(lexer) != '"') // must start with "
    {
        return T_UNKNOWN;
    }
    
    for(off_t position = lexer->position + 1; position <= lexer->length; position++)
    {
        const char input_char = lexer->text[position];
        if (input_char == '"')
        {
            if (lexer->text[position + 1] == '"')
            {
                position++;
            }
            else
            {
                position++;
                *out_start = lexer->position;
                *out_length = position - lexer->position;
                lexer->position = position;
                return T_IDENTIFIER_QUOTED;
            }
        }
    }
    
    return T_UNKNOWN;
}

static int sql_lexer_scan_literal(struct sql_lexer *restrict lexer, off_t *restrict out_start, size_t *restrict out_length)
{
    const int numeric_literal_token_id = sql_lexer_scan_numeric_literal(lexer, out_start, out_length);
    if (numeric_literal_token_id > 0)
        return numeric_literal_token_id;
    
    const int string_literal_token_id = sql_lexer_scan_string_literal(lexer, out_start, out_length);
    if (string_literal_token_id > 0)
        return string_literal_token_id;
    
    return T_UNKNOWN;
}

static int sql_lexer_scan_numeric_literal(struct sql_lexer *restrict lexer, off_t *restrict out_start, size_t *restrict out_length)
{
    const char first_char = peek(lexer);
    if (is_digit(first_char) || first_char == '.')
    {
        bool scanned_decimal_separator = false;
        bool scanned_exponential_notation = false;
        
        for(off_t position = lexer->position; position <= lexer->length; position++)
        {
            const char input_char = lexer->text[position];
            if (is_whitespace(input_char)) // whitespace
            {
                *out_start = lexer->position;
                *out_length = position - lexer->position;
                lexer->position = position;
                return T_NUMERIC_LITERAL;
            }
            else if (input_char == '.')    // .
            {
                if (scanned_decimal_separator || scanned_exponential_notation)
                {
                    if (position > lexer->position)
                    {
                        *out_start = lexer->position;
                        *out_length = position - lexer->position;
                        lexer->position = position;
                        return T_NUMERIC_LITERAL;
                    }
                    else
                    {
                        return T_UNKNOWN;
                    }
                }
                else
                {
                    scanned_decimal_separator = true;
                }
            }
            else if (input_char == 'e' || input_char == 'E')   // e+-
            {
                if (scanned_exponential_notation)
                {
                    if (position > lexer->position)
                    {
                        *out_start = lexer->position;
                        *out_length = position - lexer->position;
                        lexer->position = position;
                        return T_NUMERIC_LITERAL;
                    }
                    else
                    {
                        return T_UNKNOWN;
                    }
                }
                else
                {
                    scanned_exponential_notation = true;
                    const char next_char = lexer->text[position + 1];
                    if (next_char == '+' && next_char == '-')
                    {
                        position++;
                    }
                }
            }
            else if (!is_digit(input_char))
            {
                if (position > lexer->position)
                {
                    *out_start = lexer->position;
                    *out_length = position - lexer->position;
                    lexer->position = position;
                    return T_NUMERIC_LITERAL;
                }
                else
                {
                    return T_UNKNOWN;
                }
            }
        }
        
        return T_UNKNOWN;
    }
    else
    {
        return T_UNKNOWN;
    }
}

static int sql_lexer_scan_string_literal(struct sql_lexer *restrict lexer, off_t *restrict out_start, size_t *restrict out_length)
{
    if (peek(lexer) != '\'') // must start with '
    {
        return T_UNKNOWN;
    }
    
    for(off_t position = lexer->position + 1; position <= lexer->length; position++)
    {
        const char input_char = lexer->text[position];
        if (input_char == '\\')
        {
            position++;
        }
        else if (input_char == '\'')
        {
            position++;
            *out_start = lexer->position;
            *out_length = position - lexer->position;
            lexer->position = position;
            return T_STRING_LITERAL;
        }
    }
    
    return T_UNKNOWN;
}
