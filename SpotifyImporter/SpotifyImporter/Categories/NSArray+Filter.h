//
//  NSArray+Filter.h
//  SpotifyImporter
//
//  Created by Michal Zaborowski on 12.07.2015.
//  Copyright (c) 2015 Michal Zaborowski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Filter)
- (NSArray *)filteredArrayPassingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate;
@end
