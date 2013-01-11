//
//  PGSchemaObject.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 02/05/2012.
//  Copyright (c) 2012 Tamas Czinege. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PGConnection;

@interface PGSchemaObject : NSObject

@property (nonatomic, assign) NSInteger oid;
@property (nonatomic, strong) NSString *name;

-(id)initWithOid:(NSInteger)theOid;
+(NSString*)escapeIdentifier:(NSString*)identifier;

@end
