//
//  SIHelpGuidViewController.m
//  SpotifyImporter
//
//  Created by Michal Zaborowski on 14/07/15.
//  Copyright © 2015 Michal Zaborowski. All rights reserved.
//

#import "SIHelpGuidViewController.h"

@interface SITextAttachmentCell : NSTextAttachmentCell
@end

@implementation SITextAttachmentCell

- (NSRect)cellFrameForTextContainer:(nonnull NSTextContainer *)textContainer proposedLineFragment:(NSRect)lineFrag glyphPosition:(NSPoint)position characterIndex:(NSUInteger)charIndex {
    CGRect superRect = [super cellFrameForTextContainer:textContainer proposedLineFragment:lineFrag glyphPosition:position characterIndex:charIndex];
    superRect.size = CGSizeMake(textContainer.textView.frame.size.width, superRect.size.height * textContainer.textView.frame.size.width/self.image.size.width);
    return superRect;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(nonnull NSView *)controlView {
    [self.image drawInRect:cellFrame];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    [self.image drawInRect:cellFrame];
}

@end

@interface SIHelpGuidViewController ()
@property (unsafe_unretained) IBOutlet NSTextView *textView;

@end

@implementation SIHelpGuidViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] init];
    
    [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:@"We are going to retrieve cookie data from iTunes using Charles Proxy.\n\n"]];
    
    [attributedText addAttribute:NSLinkAttributeName value:@"http://www.charlesproxy.com" range:[attributedText.string rangeOfString:@"Charles Proxy"]];
    
    [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:@"1. From the Menu Proxy go to SSL Proxy Settings\n\n"]];
    [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:@"2. Check 'Enable SSL Proxying'\n\n"]];
    [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:@"3. Click on add and insert '*itunes.apple.com'\n\n"]];
    [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:@"4. In the same Menu check on 'Mac OS X Proxy'\n\n"]];
    [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:@"5. Go to iTunes go to an Apple Music playlist but don't do nothing\n\n"]];
    [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:@"6. Check you have enabled recording (please refer to image below)\n\n"]];
    [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:@"7. When recording is enabled add the playlist to my Music\n\n"]];
    [attributedText addAttributes:@{ NSFontAttributeName : [NSFont systemFontOfSize:16.0]} range:NSMakeRange(0, attributedText.length)];
    
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];

    NSTextAttachmentCell *attachmentCell =[[SITextAttachmentCell alloc] initImageCell:[NSImage imageNamed:@"instructions"]];
    [attachment setAttachmentCell: attachmentCell ];
    
    [attributedText appendAttributedString:[NSAttributedString attributedStringWithAttachment:attachment]];
    
    [attributedText appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    
    [self.textView.textStorage setAttributedString:attributedText];
}
@end
