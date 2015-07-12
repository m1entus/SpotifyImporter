//
//  SISong.m
//  SpotifyImporter
//
//  Created by Michal Zaborowski on 12.07.2015.
//  Copyright (c) 2015 Michal Zaborowski. All rights reserved.
//

#import "SISong.h"

@implementation SISong

+ (instancetype)songWithTrackName:(NSString *)trackName artistName:(NSString *)artistName {
    SISong *song = [[[self class] alloc] init];
    song.trackName = [trackName stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    song.artistName = [artistName stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    return song;
}
@end
