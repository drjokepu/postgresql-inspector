#include "sql_parse.h"
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include "parsing_result.h"
#include "sql_lexer.h"

#define SqlParseTOKENTYPE void*
#define SqlParseARG_PDECL

extern void *SqlParseAlloc(void *(*mallocProc)(size_t));
extern void SqlParseFree(void *p, void (*freeProc)(void*));
extern void SqlParse(
              void *yyp,                   /* The parser */
              int yymajor,                 /* The major token code number */
              SqlParseTOKENTYPE yyminor       /* The value for the token */
              SqlParseARG_PDECL               /* Optional %extra_argument parameter */
              );

struct parsing_result *sql_parse(const char *const restrict sql)
{
    void *parser = SqlParseAlloc(malloc);
    struct sql_lexer *lexer = sql_lexer_init(sql);
    
    do {
        off_t token_start = 0;
        size_t token_length = 0;
        const int token_id = sql_lexer_get_next_token(lexer, &token_start, &token_length);
        printf("scanned token: %i\n", token_id);
        
        SqlParse(parser, token_id, NULL);
        if (token_id == T_UNKNOWN || token_id == T_EOF) break;
    } while (true);
    
    SqlParseFree(parser, free);
    sql_lexer_free(lexer);
    return NULL;
}
