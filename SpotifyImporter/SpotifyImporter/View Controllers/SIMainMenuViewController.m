//
//  ViewController.m
//  SpotifyImporter
//
//  Created by Michal Zaborowski on 12.07.2015.
//  Copyright (c) 2015 Michal Zaborowski. All rights reserved.
//

#import "SIMainMenuViewController.h"
#import <AFNetworking.h>
#import "SICSVImporter.h"
#import <DJProgressHUD.h>
#import "SISong.h"
#import "NSString+Score.h"
#import "SIImporterViewController.h"

@interface SIMainMenuViewController ()
@property (nonatomic, strong) NSArray *songs;
@end

@implementation SIMainMenuViewController


- (IBAction)importFromCSVButtonTapped:(id)sender {
    
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setMessage:@"Choose .csv file."];
    [openPanel setAllowedFileTypes:@[@"csv",@"CSV"]];
    
    __weak typeof(openPanel) weakOpenPanel = openPanel;
    [openPanel beginWithCompletionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            [weakOpenPanel orderOut:weakOpenPanel];
            NSURL *csvFileURL = [[weakOpenPanel URLs] objectAtIndex:0];
            
            [DJProgressHUD showStatus:@"Parsing CSV file..." FromView:self.view];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                SICSVImporter *parser = [[SICSVImporter alloc] init];
                [parser importCSVWithContentsOfURL:csvFileURL completionHandler:^(NSArray *songs, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [DJProgressHUD dismiss];
                        [self findMusicUsingSongsArray:songs error:error];
                    });
                }];
            });
            
        }
    }];
}


- (void)findMusicUsingSongsArray:(NSArray *)songs error:(NSError *)error {
    
    if (error) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
    } else {
        
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        sessionConfiguration.HTTPMaximumConnectionsPerHost = 6;
        
        AFHTTPSessionManager *sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://itunes.apple.com"] sessionConfiguration:sessionConfiguration];
        sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html",@"application/json",nil];
        [sessionManager.requestSerializer setValue:@"application/json; target=itml; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
        [sessionManager.requestSerializer setValue:@"iTunes/12.2 (Macintosh; OS X 10.10.4) AppleWebKit/0600.7.12" forHTTPHeaderField:@"User-Agent"];
        [sessionManager.requestSerializer setValue:@"https://apps.itunes.apple.com/files/desktop-music-app/" forHTTPHeaderField:@"Referer"];
        [sessionManager.requestSerializer setValue:@"143478-20,32 t:music2" forHTTPHeaderField:@"X-Apple-Store-Front"];
        [sessionManager.requestSerializer setValue:@"7200" forHTTPHeaderField:@"X-Apple-Tz"];
        
        dispatch_group_t sessionGroup = dispatch_group_create();
        
        [DJProgressHUD showProgress:0.0 withStatus:@"Searching songs..." FromView:self.view];
        
        __block NSInteger progress = 0;
        NSInteger numberOfSongs = songs.count;
        
        [songs enumerateObjectsUsingBlock:^(SISong *song, NSUInteger idx, BOOL *stop) {
            dispatch_group_enter(sessionGroup);
            
            [sessionManager GET:@"WebObjects/MZStore.woa/wa/search" parameters:@{@"clientApplication" : @"MusicPlayer", @"term" : song.trackName } success:^(NSURLSessionDataTask *task, id responseObject) {
                
                NSDictionary *resultsDictionary = responseObject[@"storePlatformData"][@"lockup"][@"results"];
                NSArray *results = [resultsDictionary allValues];
                
                [results enumerateObjectsUsingBlock:^(NSDictionary *resultObject, NSUInteger idx, BOOL *stop) {
                    if ([resultObject[@"kind"] isEqualToString:@"song"]) {
                        if (song.matchingScore && [song.matchingScore floatValue] >= 0.9) {
                            *stop = YES;
                        }
                        
                        NSString *resultObjectName = resultObject[@"name"];
                        NSString *resultObjectArtistName = resultObject[@"artistName"];
                        if ([resultObjectName.lowercaseString isEqualToString:song.trackName.lowercaseString] && [song.artistName.lowercaseString containsString:resultObjectArtistName.lowercaseString]) {
                            song.itunesIdentifier = resultObject[@"id"];
                            song.matchingScore = @(1.0);
                            
                        } else if ([resultObjectName.lowercaseString isEqualToString:song.trackName.lowercaseString]) {
                            song.itunesIdentifier = resultObject[@"id"];
                            song.matchingScore = @(0.9);
                            
                        } else if ([resultObjectName.lowercaseString scoreAgainst:song.trackName.lowercaseString] > 0.8) {
                            song.itunesIdentifier = resultObject[@"id"];
                            song.matchingScore = @([resultObjectName.lowercaseString scoreAgainst:song.trackName.lowercaseString]);
                        } else {
                            CGFloat matchingScore = [resultObjectName.lowercaseString scoreAgainst:song.trackName.lowercaseString];
                            if (!song.matchingScore || matchingScore > [song.matchingScore floatValue]) {
                                song.itunesIdentifier = resultObject[@"id"];
                                song.matchingScore = @(matchingScore);
                            }
                        }
                    }
                }];
                song.fetched = YES;
                progress++;
                [DJProgressHUD showProgress:(CGFloat)progress/(CGFloat)numberOfSongs withStatus:@"Searching songs..." FromView:self.view];
                dispatch_group_leave(sessionGroup);

            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                progress++;
                [DJProgressHUD showProgress:(CGFloat)progress/(CGFloat)numberOfSongs withStatus:@"Searching songs..." FromView:self.view];
                dispatch_group_leave(sessionGroup);
            }];
        }];
        
        dispatch_group_notify(sessionGroup,dispatch_get_main_queue(),^{
            self.songs = [songs copy];
            [DJProgressHUD dismiss];
            [self performSegueWithIdentifier:@"importCSV" sender:self];
        });
    }
    
}

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"importCSV"]) {
        SIImporterViewController *importerViewController = segue.destinationController;
        importerViewController.songs = self.songs;
    }
}

@end
