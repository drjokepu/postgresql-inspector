//
//  SqliteParamString.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 03/05/2011.
//  Copyright 2011 Tamas Czinege. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SqliteParam.h"

@interface SqliteParamString : SqliteParam

@property (nonatomic, strong) NSString *value;

- (id) initWithName:(NSString *)theName stringValue:(NSString*)theValue;

@end
