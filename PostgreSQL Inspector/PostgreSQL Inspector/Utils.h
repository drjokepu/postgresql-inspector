//
//  Utils.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 18/02/2013.
//
//

#ifndef PostgreSQL_Inspector_Utils_h
#define PostgreSQL_Inspector_Utils_h

#include <stdbool.h>

extern inline bool isNotFirstItem(const long long selectedRow);
extern inline bool isNotLastItem(const long long selectedRow, const long long rowCount);

#endif
