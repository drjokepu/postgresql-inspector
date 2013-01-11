//
//  PGType.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 30/04/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#ifndef PostgreSQL_Inspector_PGType_h
#define PostgreSQL_Inspector_PGType_h

typedef enum
{
    PGTypeBool              = 16,
    PGTypeByte              = 17,
    PGTypeChar              = 18,
    PGTypeName              = 19,
    PGTypeInt64             = 20,
    PGTypeInt16             = 21,
    PGTypeInt16A            = 22,
    PGTypeInt32             = 23,
    PGTypeRegProc           = 24,
    PGTypeVarCharU          = 25,
    PGTypeOid               = 26,
    PGTypeTid               = 27,
    PGTypeXid               = 28,
    PGTypeCid               = 29,
    PGTypeOidA              = 30,
    PGTypeJson              = 114,
    PGTypeXml               = 142,
    PGTypeNodeTree          = 194,
    PGTypeStorageManager    = 210,
    PGTypePoint             = 600,
    PGTypeLineSegment       = 601,
    PGTypeBox               = 603,
    PGTypePolygon           = 604,
    PGTypeLine              = 628,
    PGTypeSingle            = 700,
    PGTypeDouble            = 701,
    PGTypeDateTime          = 702,
    PGTypeTimespan          = 703,
    PGTypeTimerange         = 704,
    PGTypeCircle            = 718,
    PGTypeMoney             = 790,
    PGTypeMacAddress        = 829,
    PGTypeInet              = 869,
    PGTypeNet               = 650,
    PGTypeInt16AU           = 1005,
    PGTypeInt32A            = 1007,
    PGTypeTextA             = 1009,
    PGTypeVarCharNA         = 1015,
    PGTypeFloatA            = 1021,
    PGTypeOidAU             = 1028,
    PGTypeAcl               = 1033,
    PGTypeAclA              = 1034,
    PGTypeCString           = 1263,
    PGTypeCharN             = 1042,
    PGTypeVarCharN          = 1043,
    PGTypeDate              = 1082,
    PGTypeTime              = 1083,
    PGTypeTimestamp         = 1114,
    PGTypeTimestampZ        = 1184,
    PGTypeInterval          = 1186,
    PGTypeTimeZ             = 1266,
    PGTypeFixBitString      = 1560,
    PGTypeVarBitString      = 1562,
    PGTypeNumeric           = 1700,
    PGTypeRefCursor         = 2202,
    PGTypeRegOp             = 2203,
    PGTypeRegOpWithArg      = 2204,
    PGTypeRegClass          = 2205,
    PGTypeRegType           = 2206,
    PGTypeRegTypeA          = 2211,
    PGTypeUuid              = 2950,
    // To be continued ...
} PGType;

#endif
