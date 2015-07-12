//
//  NSArray+Filter.m
//  SpotifyImporter
//
//  Created by Michal Zaborowski on 12.07.2015.
//  Copyright (c) 2015 Michal Zaborowski. All rights reserved.
//

#import "NSArray+Filter.h"

@implementation NSArray (Filter)
- (NSArray *)filteredArrayPassingTest:(BOOL (^)(id obj, NSUInteger idx, BOOL *stop))predicate {
    return [self objectsAtIndexes:[self indexesOfObjectsPassingTest:predicate]];
}
@end
