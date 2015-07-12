//
//  NSData+HexString.h
//  SpotifyImporter
//
//  Created by Michal Zaborowski on 12.07.2015.
//  Copyright (c) 2015 Michal Zaborowski. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (HexString)
+ (instancetype)dataWithHexString:(NSString *)hex;
- (NSData *)reversedData;
@end
