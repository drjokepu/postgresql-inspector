//
//  PGForeignKeyMatchType.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 06/13/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef PostgreSQL_Inspector_PGForeignKeyMatchType_h
#define PostgreSQL_Inspector_PGForeignKeyMatchType_h

typedef enum
{
    PGForeignKeyMatchTypeFull = 'f',
    PGForeignKeyMatchTypePartial = 'p',
    PGForeignKeyMatchTypeSimple = 'u'
} PGForeignKeyMatchType;

#endif
