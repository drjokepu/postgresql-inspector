#ifndef __SQL_CONTEXT_H__
#define __SQL_CONTEXT_H__

#include <sys/types.h>
#include "sql_symbol.h"

struct sql_context
{
    off_t symbol_start;
    size_t symbol_length;
    struct sql_symbol *root_symbol;
};

#endif /* __SQL_CONTEXT_H__ */