//
//  sql_parse.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 27/12/2012.
//
//

#ifndef __SQL_PARSE_H__
#define __SQL_PARSE_H__

#include "parsing_result.h"

extern struct parsing_result *sql_parse(const char *const restrict sql);

#endif /* __SQL_PARSE_H__ */
