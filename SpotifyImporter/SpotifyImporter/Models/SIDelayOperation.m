//
//  SIDelayOperation.m
//  SpotifyImporter
//
//  Created by Michal Zaborowski on 12.07.2015.
//  Copyright (c) 2015 Michal Zaborowski. All rights reserved.
//

#import "SIDelayOperation.h"

@implementation SIDelayOperation

- (instancetype)init {
    if (self = [super init]) {
        self.delay = 30;
    }
    return self;
}

- (instancetype)initWithDelay:(NSTimeInterval)delay {
    if (self = [self init]) {
        self.delay = delay;
    }
    return self;
}

- (void)main {
    [NSThread sleepForTimeInterval:self.delay];
}

@end
