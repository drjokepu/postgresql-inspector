//
//  PGForeignKeyAction.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 06/13/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef PostgreSQL_Inspector_PGForeignKeyAction_h
#define PostgreSQL_Inspector_PGForeignKeyAction_h

typedef enum
{
    PGForeignKeyActionNone = 0,
    PGForeignKeyActionNoAction = 'a',
    PGForeignKeyActionRestrict = 'r',
    PGForeignKeyActionCascade = 'c',
    PGForeignKeyActionSetNull = 'n',
    PGForeignKeyActionSetDefault = 'd'
} PGForeignKeyAction;

#endif
