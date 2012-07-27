//
//  PGConstraintColumn.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 06/13/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PGConstraintColumn : NSObject

@property (nonatomic, assign) NSInteger columnNumber;

@property (nonatomic, assign) NSUInteger foreignKeyReferencedColumnNumber;
@property (nonatomic, assign) NSInteger foreignKeyPKFKEqualityOperator;
@property (nonatomic, assign) NSInteger foreignKeyPKPKEqualityOperator;
@property (nonatomic, assign) NSInteger foreignKeyFKFKEqualityOperator;

@property (nonatomic, assign) NSInteger exclusionOperator;

@end
