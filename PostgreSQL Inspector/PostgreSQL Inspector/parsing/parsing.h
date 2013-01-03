#ifndef __PARSING_H__
#define __PARSING_H__

#include "parsing_data_types.h"

enum sql_ast_node_type;
struct parsing_result;

extern struct parsing_result *sql_parse(const char *const restrict sql);

#endif /* __PARSING_H__ */