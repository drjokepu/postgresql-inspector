#ifdef __FUNCTIONS_H__
#error "functions.h is already included."
#endif /* __FUNCTIONS_H__ */
#define __FUNCTIONS_H__

#include <stdarg.h>
#include "../sql_symbol.h"

static struct sql_symbol *with_children(struct sql_symbol *restrict parent, const unsigned int number_of_children, ...)
{
    va_list ap;
    va_start(ap, number_of_children);
    for (unsigned int i = 0;  i < number_of_children; i++)
    {
        struct sql_symbol *child = va_arg(ap, struct sql_symbol*);
        sql_symbol_add_child(parent, child);
    }
    va_end(ap);
    return parent;
}

static struct sql_symbol *new_with_children(const enum sql_symbol_type symbol_type, const unsigned int number_of_children, ...)
{
    va_list ap;
    struct sql_symbol *symbol = sql_symbol_init_with_symbol_type(symbol_type);
    va_start(ap, number_of_children);
    for (unsigned int i = 0;  i < number_of_children; i++)
    {
        struct sql_symbol *child = va_arg(ap, struct sql_symbol*);
        sql_symbol_add_child(symbol, child);
    }
    va_end(ap);
    return symbol;
}