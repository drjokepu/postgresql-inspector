//
//  PGNull.h
//  PostgreSQL Inspector
//
//  Created by Tamas Czinege on 30/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PGNull : NSObject <NSCopying>

+(PGNull*)sharedValue;

@end
