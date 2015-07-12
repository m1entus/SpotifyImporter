//
//  SICSVImporter.h
//  SpotifyImporter
//
//  Created by Michal Zaborowski on 12.07.2015.
//  Copyright (c) 2015 Michal Zaborowski. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^SICSVImporterCompletionHandler)(NSArray *songs, NSError *error);

@interface SICSVImporter : NSObject
@property (nonatomic, copy) SICSVImporterCompletionHandler completionHandler;

- (void)importCSVWithContentsOfURL:(NSURL *)URL completionHandler:(SICSVImporterCompletionHandler)completionHandler;

@end
