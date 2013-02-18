//
//  Utils.c
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 18/02/2013.
//

#include "Utils.h"

inline bool isNotFirstItem(const long long selectedRow)
{
    return selectedRow > 0;
}

inline bool isNotLastItem(const long long selectedRow, const long long rowCount)
{
    return (selectedRow >= 0) && ((selectedRow + 1) < rowCount);
}