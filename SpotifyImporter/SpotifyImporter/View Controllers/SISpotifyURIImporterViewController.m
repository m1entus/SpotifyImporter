//
//  SISpotifyURIImporterViewController.m
//  SpotifyImporter
//
//  Created by Michal Zaborowski on 13/07/15.
//  Copyright © 2015 Michal Zaborowski. All rights reserved.
//

#import "SISpotifyURIImporterViewController.h"
#import <AFNetworking.h>
#import <DJProgressHUD.h>
#import "SISong.h"

@interface SISpotifyURIImporterViewController ()
@property (unsafe_unretained) IBOutlet NSTextView *textView;
@end

@implementation SISpotifyURIImporterViewController

- (IBAction)helpButtonTapped:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString: @"https://lupin.rocks/entry/seamlessly-import-your-spotify-playlists-into-itunes#uris"]];
}
- (IBAction)cancelButtonTapped:(id)sender {
    [self.view.window.sheetParent endSheet:self.view.window returnCode:NSModalResponseCancel];
    if (self.compeltionHandler) {
        self.compeltionHandler(nil,YES);
    }

}
- (IBAction)continueButtonTapped:(id)sender {
    
    
    NSArray *lines = [self.textView.string componentsSeparatedByString:@"\n"];
    NSMutableArray *splitedSongsURIs = [NSMutableArray array];
    
    [lines enumerateObjectsUsingBlock:^(NSString *obj, NSUInteger idx, BOOL *stop) {
        NSString *URI = [obj stringByReplacingOccurrencesOfString:@"spotify:track:" withString:@""];
        // Required. A comma-separated list of the Spotify IDs for the tracks. Maximum: 50 IDs.
        NSInteger groupIndex = idx / 50;
        NSMutableArray *groupedSongs = nil;
        if (splitedSongsURIs.count <= groupIndex) {
            groupedSongs = [NSMutableArray arrayWithCapacity:50];
            splitedSongsURIs[groupIndex] = groupedSongs;
        } else {
            groupedSongs = splitedSongsURIs[groupIndex];
        }
        [groupedSongs addObject:URI];
    }];
    
    AFHTTPSessionManager *sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.spotify.com"] sessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    dispatch_group_t sessionGroup = dispatch_group_create();
    
    [DJProgressHUD showProgress:0.0 withStatus:@"Searching songs..." FromView:self.view];
    
    __block NSError *networkError = nil;
    __block NSInteger progress = 0;
    NSInteger numberOfSongs = splitedSongsURIs.count;
    
    NSMutableArray *songs = [NSMutableArray array];
    
    for (NSArray *songsURIs in splitedSongsURIs) {
        dispatch_group_enter(sessionGroup);
        
        [sessionManager GET:@"v1/tracks" parameters:@{ @"ids" : [songsURIs componentsJoinedByString:@","] } success:^(NSURLSessionDataTask *task, id responseObject) {
            
            NSArray *tracks = responseObject[@"tracks"];
            [tracks enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
                NSDictionary *album = obj[@"album"];
                NSArray *artists = obj[@"artists"];
                NSMutableString *artistName = [[NSMutableString alloc] init];
                [artists enumerateObjectsUsingBlock:^(id  obj, NSUInteger idx, BOOL *stop) {
                    if (idx <= 0) {
                        [artistName appendString:obj[@"name"]];
                    } else {
                        [artistName appendFormat:@" & %@",obj[@"name"]];
                    }
                }];
                SISong *song = [SISong songWithTrackName:album[@"name"] artistName:[artistName copy]];
                [songs addObject:song];
            }];
            
            
            progress++;
            [DJProgressHUD showProgress:(CGFloat)progress/(CGFloat)numberOfSongs withStatus:@"Fetching songs..." FromView:self.view];
            
            dispatch_group_leave(sessionGroup);
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            progress++;
            [DJProgressHUD showProgress:(CGFloat)progress/(CGFloat)numberOfSongs withStatus:@"Fetching songs..." FromView:self.view];
            
            networkError = error;
            dispatch_group_leave(sessionGroup);
        }];
    }
    
    dispatch_group_notify(sessionGroup,dispatch_get_main_queue(),^{

        [DJProgressHUD dismiss];
        
        if (networkError) {
            [[NSAlert alertWithError:networkError] runModal];
        } else {
            [self.view.window.sheetParent endSheet:self.view.window returnCode:NSModalResponseCancel];
            if (self.compeltionHandler) {
                self.compeltionHandler([songs copy],NO);
            }
        }
    });
    
    
    
}

@end
