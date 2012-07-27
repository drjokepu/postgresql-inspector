//
//  SqliteColumnTypeAffinity.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 05/06/2011.
//  Copyright 2011 Tamas Czinege. All rights reserved.
//

typedef enum
{
    SqliteColumnTypeAffinityText,
    SqliteColumnTypeAffinityNumeric,
    SqliteColumnTypeAffinityInteger,
    SqliteColumnTypeAffinityReal,
    SqliteColumnTypeAffinityNone
} SqliteColumnTypeAffinity;