#ifndef __PARSING_H__
#define __PARSING_H__

extern void sql_parser_static_init(void);
extern void sql_parser_static_destroy(void);

extern void sql_parse(const char *const restrict sql);

#endif /* __PARSING_H__ */