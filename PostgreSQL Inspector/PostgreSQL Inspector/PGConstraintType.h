//
//  PGConstraintType.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 06/13/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef PostgreSQL_Inspector_PGConstraintType_h
#define PostgreSQL_Inspector_PGConstraintType_h

typedef enum
{
    PGConstraintTypeCheck = 'c',
    PGConstraintTypeForeignKey = 'f',
    PGConstraintTypePrimaryKey = 'p',
    PGConstraintTypeUniqueKey = 'u',
    PGConstraintTypeTrigger = 't',
    PGConstraintTypeExclusion = 'x'
} PGConstraintType;

#endif
