//
//  PGSchemaObjectGroupType.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 30/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#ifndef PostgreSQL_Inspector_PGSchemaObjectGroupType_h
#define PostgreSQL_Inspector_PGSchemaObjectGroupType_h

typedef enum
{
    PGSchemaObjectGroupTypeTables,
    PGSchemaObjectGroupTypeViews,
    PGSchemaObjectGroupTypeRoles
} PGSchemaObjectGroupType;

#endif
