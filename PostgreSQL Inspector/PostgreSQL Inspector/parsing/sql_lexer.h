#ifndef __SQL_LEXER_H__
#define __SQL_LEXER_H__

#include <stdbool.h>
#include <string.h>
#include <sys/types.h>

#define T_UNKNOWN -1
#define T_EOF 0

struct sql_lexer
{
    char *text;
    size_t length;
    off_t position;
};

struct sql_lexer *sql_lexer_init(const char *const restrict text);
void sql_lexer_free(struct sql_lexer *lexer);

bool sql_lexer_is_eof(const struct sql_lexer *const restrict lexer);
int sql_lexer_get_next_token(struct sql_lexer *restrict lexer, off_t *restrict out_start, size_t *restrict out_length);

#endif