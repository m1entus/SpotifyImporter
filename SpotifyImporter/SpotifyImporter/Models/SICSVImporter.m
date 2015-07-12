//
//  SICSVImporter.m
//  SpotifyImporter
//
//  Created by Michal Zaborowski on 12.07.2015.
//  Copyright (c) 2015 Michal Zaborowski. All rights reserved.
//

#import "SICSVImporter.h"
#import <CHCSVParser.h>
#import "SISong.h"

@interface SICSVImporter () <CHCSVParserDelegate>
@property (strong) NSMutableArray *lines;
@property (strong) NSError *error;

@property (strong) NSMutableArray *currentLine;
@end

@implementation SICSVImporter

- (void)importCSVWithContentsOfURL:(NSURL *)URL completionHandler:(SICSVImporterCompletionHandler)completionHandler {
    
    self.completionHandler = completionHandler;
    CHCSVParser *parser = [[CHCSVParser alloc] initWithContentsOfDelimitedURL:URL delimiter:','];
    parser.delegate = self;
    
    [parser parse];
}

#pragma mark - <CHCSVParserDelegate>

- (void)parserDidBeginDocument:(CHCSVParser *)parser {
    self.lines = [[NSMutableArray alloc] init];
}

- (void)parser:(CHCSVParser *)parser didBeginLine:(NSUInteger)recordNumber {
    self.currentLine = [[NSMutableArray alloc] init];
}

- (void)parser:(CHCSVParser *)parser didEndLine:(NSUInteger)recordNumber {
    [self.lines addObject:self.currentLine];
    self.currentLine = nil;
}

- (void)parser:(CHCSVParser *)parser didReadField:(NSString *)field atIndex:(NSInteger)fieldIndex {
    [self.currentLine addObject:field];
}

- (void)parser:(CHCSVParser *)parser didFailWithError:(NSError *)error {
    
    self.error = error;
    
    if (error && error.code == CHCSVErrorCodeInvalidFormat) {
        self.error = [NSError errorWithDomain:error.domain code:error.code userInfo:@{ NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Invalid CSV format, please verify %@ line of your CSV file.",@(self.lines.count)]}];
    }
    if (self.completionHandler) {
        self.completionHandler(@[],self.error);
    }
}

- (void)parserDidEndDocument:(CHCSVParser *)parser {
    
    NSMutableArray *songs = [NSMutableArray arrayWithCapacity:self.lines.count];
    
    if (self.lines.count) {
        // Remove column info line
        [self.lines removeObjectAtIndex:0];
        
        for (NSArray *line in self.lines) {
            if (line.count >= 2) {
                [songs addObject:[SISong songWithTrackName:line[1] artistName:line[2]]];
            }
        }
    }
    
    if (self.completionHandler) {
        self.completionHandler([songs copy],self.error);
    }
}
@end
