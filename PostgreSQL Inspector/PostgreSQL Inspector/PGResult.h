//
//  PGResult.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 13/12/2012.
//
//

#import <Foundation/Foundation.h>

@interface PGResult : NSObject

@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, strong) NSArray *columnNames;
@property (nonatomic, strong) NSArray *columnTypes;

@end
