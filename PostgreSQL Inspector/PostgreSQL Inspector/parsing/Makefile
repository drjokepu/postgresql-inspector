OUTPUT=lex.sql_yy.c sql.tab.c sql.tab.h

all: $(OUTPUT)
lex.sql_yy.c:
	flex sql.l

sql.tab.c sql.tab.h:
	bison sql.y

clean:
	rm -rf $(OUTPUT)
