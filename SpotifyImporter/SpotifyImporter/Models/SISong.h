//
//  SISong.h
//  SpotifyImporter
//
//  Created by Michal Zaborowski on 12.07.2015.
//  Copyright (c) 2015 Michal Zaborowski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SISong : NSObject
@property (nonatomic, copy) NSString *trackName;
@property (nonatomic, copy) NSString *artistName;
@property (nonatomic, copy) NSString *itunesIdentifier;
@property (nonatomic, strong) NSNumber *matchingScore;
@property (nonatomic, assign) BOOL fetched;

+ (instancetype)songWithTrackName:(NSString *)trackName artistName:(NSString *)artistName;
@end
