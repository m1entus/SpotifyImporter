//
//  SISpotifyURIImporterViewController.h
//  SpotifyImporter
//
//  Created by Michal Zaborowski on 13/07/15.
//  Copyright © 2015 Michal Zaborowski. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef void(^SISpotifyURIImporterViewControllerCompletionHandler)(NSArray *songs, BOOL canceled);

@interface SISpotifyURIImporterViewController : NSViewController
@property (nonatomic, copy) SISpotifyURIImporterViewControllerCompletionHandler compeltionHandler;
@end
