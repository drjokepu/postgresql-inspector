#include <stdbool.h>
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
    (struct token_lookup_item){ .text = "ROLLBACK", .value = T_ROLLBACK }
};

static const size_t token_lookup_count = sizeof(token_lookup) / sizeof(struct token_lookup_item);

static inline bool is_eof(const struct sql_lexer *const restrict lexer);
static inline char peek(const struct sql_lexer *const restrict lexer);
static inline char char_to_upper(const char input);
static inline void skip_whitespace(struct sql_lexer *restrict lexer);
static int sql_lexer_get_next_token_keyword(struct sql_lexer *restrict lexer, off_t *restrict out_start, size_t *restrict out_length);

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
    
    const int keyword_token_id = sql_lexer_get_next_token_keyword(lexer, out_start, out_length);
    if (keyword_token_id > 0)
        return keyword_token_id;
    
    return T_UNKNOWN;
}

static inline void skip_whitespace(struct sql_lexer *restrict lexer)
{
    while (!is_eof(lexer) && is_whitespace(peek(lexer))) lexer->position++;
}

static int sql_lexer_get_next_token_keyword(struct sql_lexer *restrict lexer, off_t *restrict out_start, size_t *restrict out_length)
{
    bool unacceptable_tokens[token_lookup_count];
    bzero(&unacceptable_tokens, sizeof(unacceptable_tokens));
    
    for(off_t position = lexer->position; position <= lexer->length; position++)
    {
        for (unsigned int i = 0; i < token_lookup_count; i++)
        {
            if (!unacceptable_tokens[i])
            {
                const char token_char = token_lookup[i].text[position];
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
            }
        }
    }
    
    return T_UNKNOWN;
}