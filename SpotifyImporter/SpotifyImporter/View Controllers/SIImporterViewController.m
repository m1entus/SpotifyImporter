//
//  SIImporterViewController.m
//  SpotifyImporter
//
//  Created by Michal Zaborowski on 12.07.2015.
//  Copyright (c) 2015 Michal Zaborowski. All rights reserved.
//

#import "SIImporterViewController.h"
#import "SISong.h"
#import "NSArray+Filter.h"
#import "SIDelayOperation.h"
#import <AFNetworking.h>
#import "NSData+HexString.h"
#import <DJProgressHUD.h>

NSString *const SIAppleRequestBodyString = @"61 6a 43 41 00 00 00 45 6d 73 74 63 00 00 00 04 55 94 17 a3 6d 6c 69 64 00 00 00 04 00 00 00 00 6d 75 73 72 00 00 00 04 00 00 00 81 6d 69 6b 64 00 00 00 01 02 6d 69 64 61 00 00 00 10 61 65 41 69 00 00 00 08 00 00 00 00 11 8c d9 2c 00";

@interface SIImporterViewController () <NSTableViewDelegate, NSTableViewDataSource>
@property (weak) IBOutlet NSTextField *cookieTextField;
@property (weak) IBOutlet NSTextField *dsidTextField;
@property (weak) IBOutlet NSTextField *guidTextField;
@property (weak) IBOutlet NSTextField *importDelayTextField;
@property (weak) IBOutlet NSTableView *tableView;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@end

@implementation SIImporterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.maxConcurrentOperationCount = 1;
    
    self.dsidTextField.stringValue = @"";
    self.guidTextField.stringValue = @"";
    self.cookieTextField.stringValue = @"";
    
    self.songs = [self.songs sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"matchingScore" ascending:NO selector:@selector(compare:)]]];
    
    [self.tableView reloadData];
}


- (IBAction)cancelButtonTapped:(id)sender {
    [self.view.window.sheetParent endSheet:self.view.window returnCode:NSModalResponseCancel];
}
- (IBAction)importMatchedButtonTapped:(id)sender {
    NSArray *songsToImport = [self.songs filteredArrayPassingTest:^BOOL(SISong *obj, NSUInteger idx, BOOL *stop) {
        if (obj.matchingScore && obj.fetched && [obj.matchingScore floatValue] >= 0.8 && obj.itunesIdentifier) {
            return YES;
        }
        return NO;
    }];
    [self importSongs:songsToImport];
}
- (IBAction)importSelectedButtonTapped:(id)sender {
    
    NSArray *songsToImport = [[self.songs objectsAtIndexes:self.tableView.selectedRowIndexes] filteredArrayPassingTest:^BOOL(SISong *obj, NSUInteger idx, BOOL *stop) {
        return obj.itunesIdentifier != nil;
    }];
    [self importSongs:songsToImport];
}
- (IBAction)importAllButtonTapped:(id)sender {
    NSArray *songsToImport = [self.songs filteredArrayPassingTest:^BOOL(SISong *obj, NSUInteger idx, BOOL *stop) {
        if (obj.matchingScore && obj.fetched && [obj.matchingScore floatValue] > 0.0 && obj.itunesIdentifier) {
            return YES;
        }
        return NO;
    }];
    [self importSongs:songsToImport];
}

- (void)importSongs:(NSArray *)songs {
    
    if (songs.count <= 0) {
        return;
    }

    NSMutableArray *songsToImport = [songs mutableCopy];
    
    [DJProgressHUD showStatus:@"Checking authentication data..." FromView:self.view];
    
    [self importFirstSong:[songsToImport firstObject] andVerifyAuthenticationData:^(BOOL authenticationSuccess) {
        [DJProgressHUD dismiss];
        
        if (authenticationSuccess) {
            [songsToImport removeObjectAtIndex:0];
            [self continueImportingSongs:songsToImport];
        }
    }];
}

- (void)continueImportingSongs:(NSArray *)songs {
    [self.operationQueue cancelAllOperations];
    
    AFHTTPRequestOperationManager *operationManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://ld-3.itunes.apple.com"]];
    operationManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html",@"application/x-dmap-tagged",nil];
    
    [DJProgressHUD showProgress:0.0 withStatus:@"Importing songs..." FromView:self.view];
    __block NSInteger currentProgress = 0;
    NSInteger finalProgress = songs.count;
    
    for (SISong *song in songs) {
        
        __weak typeof(self) weakSelf = self;
        AFHTTPRequestOperation *requestOperation = [self requestOperationForManager:operationManager song:song];
        [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            currentProgress++;
            [DJProgressHUD showProgress:(CGFloat)currentProgress/(CGFloat)finalProgress withStatus:@"Importing songs..." FromView:weakSelf.view];
            if (currentProgress >= finalProgress) {
                [DJProgressHUD dismiss];
                [weakSelf.view.window.sheetParent endSheet:weakSelf.view.window returnCode:NSModalResponseOK];
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (error) {
                [weakSelf.operationQueue cancelAllOperations];
            }
        }];

        NSInteger delay = self.importDelayTextField.integerValue;
        if (delay <= 1) {
            delay = 1;
        }
        SIDelayOperation *operation = [[SIDelayOperation alloc] initWithDelay:delay];
        [self.operationQueue addOperations:@[requestOperation,operation] waitUntilFinished:NO];
    }
}

- (void)importFirstSong:(SISong *)song andVerifyAuthenticationData:(void(^)(BOOL authenticationSuccess))completion {
    
    AFHTTPRequestOperationManager *operationManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:@"https://ld-3.itunes.apple.com"]];
    operationManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html",@"application/x-dmap-tagged",nil];
    
    AFHTTPRequestOperation *requestOperation = [self requestOperationForManager:operationManager song:song];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (completion) {
            completion(YES);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(NO);
        }
        if (operation.response.statusCode == 401) {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"OK"];
            [alert setMessageText:@"Unable to authenticate user."];
            [alert setInformativeText:@"Import operation aborted. Make sure you enter correct X-Dsid and X-Guid identifiers."];
            [alert setAlertStyle:NSWarningAlertStyle];
            [alert runModal];
        } else {
            [[NSAlert alertWithError:error] runModal];
        }
    }];
    
    [requestOperation start];
}

- (AFHTTPRequestOperation *)requestOperationForManager:(AFHTTPRequestOperationManager *)manager song:(SISong *)song {

     NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"/WebObjects/MZDaap.woa/daap/databases/1/cloud-add" relativeToURL:manager.baseURL]];
    [request setHTTPMethod:@"POST"];
    
    NSDictionary *headers = @{
        @"X-Apple-Store-Front" : @"143478-20,32",
        @"Client-iTunes-Sharing-Version" : @"3.12",
        @"Accept-Language" : @"pl-pl, pl;q=0.75, en-us;q=0.50, en;q=0.25",
        @"Client-Cloud-DAAP-Version" : @"1.0/iTunes-12.2.0.145",
        @"Accept-Encoding" : @"gzip",
        @"X-Apple-itre" : @"0",
        @"Client-DAAP-Version" : @"3.13",
        @"User-Agent" : @"iTunes/12.2 (Macintosh; OS X 10.10.4) AppleWebKit/0600.7.12",
        @"Connection" : @"keep-alive",
        @"Content-Type" : @"application/x-dmap-tagged",
        @"X-Dsid" : self.dsidTextField.stringValue,
        @"Cookie" : self.cookieTextField.stringValue,
        @"X-Guid" : self.guidTextField.stringValue,
        @"Content-Length" : @"77"
        };
    
    
    unsigned int timeInterval = (unsigned int)([[NSDate date] timeIntervalSince1970]);
    unsigned int itunesIdentifier = (unsigned int)([song.itunesIdentifier integerValue]);
    
    NSMutableData *data = [[NSData dataWithHexString:[SIAppleRequestBodyString stringByReplacingOccurrencesOfString:@" " withString:@""]] mutableCopy];
    
    NSData *timeIntervalData = [[NSData dataWithBytes:&timeInterval length:sizeof(timeInterval)] reversedData];
    [data replaceBytesInRange:NSMakeRange(16, 4) withBytes:timeIntervalData.bytes];
    
    NSData *itunesIdentifierData = [[NSData dataWithBytes:&itunesIdentifier length:sizeof(itunesIdentifier)] reversedData];
    [data replaceBytesInRange:NSMakeRange(data.length-5, 5) withBytes:itunesIdentifierData.bytes];
    
    [request setHTTPBody:data];
    [request setAllHTTPHeaderFields:headers];
    
    return [manager HTTPRequestOperationWithRequest:request success:nil failure:nil];
}

- (NSData *)HTTPBodyForSong:(SISong *)song {
    return nil;
}

#pragma mark - <NSTableViewDataSource>

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.songs.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    SISong *song = [self.songs objectAtIndex:row];
    id value = [song valueForKey:tableColumn.identifier];
    if ([tableColumn.identifier isEqualToString:@"matchingScore"]) {
        if (song.fetched) {
            if ([value floatValue] <= 0) {
                return @"Not Found";
            } else {
                return value;
            }
        } else {
            return @"Couldn't fetched";
        }
    }
    
    return value;
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    SISong *song = [self.songs objectAtIndex:row];
    if ([tableColumn.identifier isEqualToString:@"matchingScore"]) {
        if ([song.matchingScore doubleValue] >= 0.8) {
            [cell setTextColor:[NSColor greenColor]];
        } else if ([song.matchingScore doubleValue] >= 0.4) {
            [cell setTextColor:[NSColor yellowColor]];
        } else {
            [cell setTextColor:[NSColor redColor]];
        }
    }
}

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
    NSArray *newDescriptors = [tableView sortDescriptors];
    self.songs = [self.songs sortedArrayUsingDescriptors:newDescriptors];
    [tableView reloadData];
}

@end
