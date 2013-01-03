//
//  sql_parse.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 27/12/2012.
//
//

#ifndef PostgreSQL_Inspector_sql_parse_h
#define PostgreSQL_Inspector_sql_parse_h

#include <stdio.h>
#include <string.h>
#include "parsing.h"

#define YYSTYPE struct sql_ast_node*

struct sql_ast_node
{
    enum sql_ast_node_type node_type;
    off_t start;
    size_t length;
    unsigned int link_count;
    off_t links[8];
    union
    {
        const char *string;
    } value;
};

struct sql_node_array
{
    size_t count;
    size_t capacity;
    struct sql_ast_node nodes[];
};

struct sql_allocations
{
    size_t count;
    size_t capacity;
    void *list[];
};

struct sql_line_positions
{
    size_t count;
    size_t capacity;
    off_t positions[];
};

#endif
