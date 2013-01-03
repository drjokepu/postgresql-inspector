%token_prefix T_
%name SqlParse

%include {
#include <string.h>
}

start ::= ROLLBACK.
