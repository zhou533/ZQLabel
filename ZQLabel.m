//
//  ZQLabel.m
//  ZQLabel
//
//  Created by Chou Chris on 13-1-9.
//  Copyright (c) 2013年 Gozap. All rights reserved.
//

#import "ZQLabel.h"

/*
 ZQEmoji
 */
@interface ZQEmoji : NSObject
@property (nonatomic, retain) NSString *filename;
@property (nonatomic, assign) CGSize size;
@end

@implementation ZQEmoji

@synthesize filename;

- (void)dealloc
{
    [filename release];
    [super dealloc];
}

@end

/*
 ZQLine
 */
@interface ZQLine : NSObject
{
    @private
    NSMutableArray *_parts;
}
@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, assign) NSUInteger length;
@property (nonatomic, assign) BOOL hasEmoji;
@property (nonatomic, readonly) NSArray *parts;
- (void)appendStr:(NSString*)string;
- (void)appendEmoji:(ZQEmoji*)emoji;
@end

@implementation ZQLine

@synthesize parts = _parts;

- (void)dealloc
{
    [_parts release];
    [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self) {
        _parts = [[NSMutableArray alloc] init];
        self.hasEmoji = NO;
    }
    return self;
}

- (void)appendEmoji:(ZQEmoji *)emoji
{
    self.hasEmoji = YES;
    [_parts addObject:emoji];
    self.length += 1;
}

- (void)appendStr:(NSString *)string
{
    [_parts addObject:string];
    self.length += [string length];
}

@end

/*
 
 */
@interface ZQLinkRange : NSObject
@property (nonatomic) NSUInteger location;
@property (nonatomic) NSUInteger length;
@property (nonatomic) NSInteger offset;
- (NSRange)range;
+ (ZQLinkRange*)rangeWithLocation:(NSUInteger)location length:(NSUInteger)length offset:(NSInteger)offset;
@end

@implementation ZQLinkRange

- (NSRange)range
{
    return NSMakeRange(self.location + self.offset, self.length);
}

+ (ZQLinkRange*)rangeWithLocation:(NSUInteger)location length:(NSUInteger)length offset:(NSInteger)offset
{
    ZQLinkRange *range = [[[ZQLinkRange alloc] init] autorelease];
    range.location = location;
    range.length = length;
    range.offset = offset;
    return range;
}

@end

/*
 
 */
#define kEmojiWidth 18.0f
#define kEmojiHeight 18.0f

/*
 ZQLabel
 */
@interface ZQLabel ()
{
    CGFloat paddingLeft;
    CGFloat paddingTop;
    CGFloat lineHeight;
    CGFloat rowSpacing;
    CGFloat wordSpacing;
    CGFloat chinesewidth;
    
    //NSMutableArray *linkRanges;
    //NSRange activeLinkRange;
}
@property (nonatomic, retain) NSMutableArray *linkRanges;
@property (nonatomic, retain) NSMutableArray *strArray;
@property (nonatomic, retain) ZQLinkRange *activeLinkRange;

@end

@implementation ZQLabel

@synthesize text = _text;
@synthesize font = _font;
@synthesize textColor = _textColor;
@synthesize strArray = _strArray;

- (void)dealloc
{
    self.linkRanges = nil;
    
    [_strArray release];
    [_textColor release];
    [_font release];
    [_text release];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        paddingLeft = 0;
        paddingTop = 0;
        lineHeight = 15;
        rowSpacing = 0;
        wordSpacing = 0;
        chinesewidth = 0;
        
        //activeLinkRange = NSMakeRange(0, 0);
        //linkRanges = [[NSMutableArray alloc] init];
        self.activeLinkRange = nil;
    }
    return self;
}

- (void)setFont:(UIFont *)font
{
    [_font release];
    _font = [font retain];
    chinesewidth = [@"国" sizeWithFont:_font constrainedToSize:CGSizeMake(320, MAXFLOAT) lineBreakMode:NSLineBreakByWordWrapping].width;
    lineHeight = _font.lineHeight;
}

- (void)setText:(NSString *)text
{
    [_text release];
    _text = [text retain];
    
    //match links range
    NSError* error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"((@|#)([A-Z0-9a-z(é|ë|ê|è|à|â|ä|á|ù|ü|û|ú|ì|ï|î|í)_]+))|(http(s)?://([A-Z0-9a-z._-]*(/)?)*)" options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *matches = [regex matchesInString:_text options:0 range:NSMakeRange(0, [_text length])];
    if (matches && [matches count] > 0) {
        if (self.linkRanges) {
            [self.linkRanges removeAllObjects];
        }else{
            self.linkRanges = [NSMutableArray array];
        }
        for (NSTextCheckingResult *match in matches) {
            [self.linkRanges addObject:[ZQLinkRange rangeWithLocation:match.range.location length:match.range.length offset:0]];
            NSLog(@"link %@ range:%d, %d", [_text substringWithRange:match.range],match.range.location, match.range.length);
        }
    }else{
        self.linkRanges = nil;
    }
    /*NSDataDetector* linkDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&error];
    [linkDetector enumerateMatchesInString:_text options:0 range:NSMakeRange(0, _text.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop){
    
        linkRange = result.range;
        NSLog(@"link range:%d, %d",linkRange.location, linkRange.length);
    }];*/
    
    //segment string
    self.strArray = [self strArrayFromString:_text];
}
#if 0
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetLineWidth(context, 1.0);
	//CGContextSetStrokeColorWithColor(context, _textColor.CGColor);
	//CGContextSetFillColorWithColor(context, _textColor.CGColor);
    /*
    CGFloat drawX = paddingLeft;
    int lineIndex = 0;
    for (int i = 0, length = [_text length]; i < length; i++) {
        CGFloat ww = 0;
        NSString *tmpStr = [_text substringWithRange:NSMakeRange(i, 1)];
        if ([_text characterAtIndex:i] < 127) {
            ww += [tmpStr sizeWithFont:_font constrainedToSize:CGSizeMake(320, MAXFLOAT) lineBreakMode:NSLineBreakByWordWrapping].width;
            ww += wordSpacing;
            
        }
        else
        {
            ww += chinesewidth;
            ww += wordSpacing;
        }
        
        if ((drawX + ww) > rect.size.width) {
            drawX = paddingLeft;
            lineIndex++;
        }
        
        [tmpStr drawAtPoint:CGPointMake(drawX, paddingTop+(lineHeight + rowSpacing +1)*lineIndex)
                   forWidth:rect.size.width
                   withFont:_font
              lineBreakMode:NSLineBreakByWordWrapping];
        drawX += ww;

    }*/
    
    int n = 0;
    for (int i = 0; i < [_strArray count]; i++) {
        ZQLine *line = [_strArray objectAtIndex:i];
        NSString *str = line.txt;
        CGFloat drawX = paddingLeft;
        for (int j = 0; j < [str length]; j++, n++) {
            
            NSString *tempstring = [str substringWithRange:(NSMakeRange(j,1))];
            CGFloat w = 0;
            if ([str characterAtIndex:j] < 127) {
                w += [tempstring sizeWithFont:_font constrainedToSize:CGSizeMake(320, MAXFLOAT) lineBreakMode:NSLineBreakByWordWrapping].width;
                w += wordSpacing;
                
            }
            else
            {
                w += chinesewidth;
                w += wordSpacing;
            }
            
            NSRange tmpR = [self rangeAtIndex:n];
            if (!NSEqualRanges(tmpR, NSMakeRange(0, 0))) {
                
                if (!NSEqualRanges(activeLinkRange, NSMakeRange(0, 0)) && NSEqualRanges(tmpR, activeLinkRange)) {
                    CGContextSetFillColorWithColor(context, [UIColor lightGrayColor].CGColor);
                    CGContextFillRect(context, CGRectMake(drawX, paddingTop+(lineHeight + rowSpacing +1)*i, w, lineHeight + rowSpacing));
                }
                CGContextSetFillColorWithColor(context, [UIColor blueColor].CGColor);
            }else{
                CGContextSetFillColorWithColor(context, _textColor.CGColor);
            }
            
            
            [tempstring drawAtPoint:CGPointMake(drawX, paddingTop+(lineHeight + rowSpacing +1)*i)
                           forWidth:rect.size.width
                           withFont:_font
                      lineBreakMode:NSLineBreakByWordWrapping];
            
            
            
            
            
            /*if (NSLocationInRange(n,linkRange)) {
                CGContextBeginPath(context);
                //CGFloat dashes[] = { 2, 1 };
                CGContextSetLineWidth(context, 0.5);
                //CGContextSetLineDash( context, 0.0, dashes, 2 );
                CGContextSetStrokeColorWithColor(context, _textColor.CGColor);
                CGContextMoveToPoint(context, drawX, paddingTop+(lineHeight + rowSpacing +1)*(i+1)-rowSpacing);
                CGContextAddLineToPoint(context, drawX+w,paddingTop+(lineHeight + rowSpacing +1)*(i+1)-rowSpacing);
                CGContextStrokePath(context);
            }*/
            drawX += w;
        }
    }
}
#else
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetLineWidth(context, 1.0);
    //CGContextSetFillColorWithColor(context, _textColor.CGColor);
    int n = 0;
    
    for (int i = 0; i < [_strArray count]; i++) {
        ZQLine *line = [_strArray objectAtIndex:i];
        CGFloat drawX = paddingLeft;
        CGFloat drawY = paddingTop+(lineHeight + rowSpacing +1)*i;
        for (id part in line.parts) {
            if ([part isKindOfClass:[ZQEmoji class]]) {
                UIImage *em = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png",((ZQEmoji*)part).filename]];
                [em drawInRect:CGRectMake(drawX, drawY, kEmojiWidth, kEmojiHeight)];
                drawX += kEmojiWidth;
                drawX += wordSpacing;
                n++;
            }else{
                NSString *str = (NSString*)part;
                for (int j = 0; j < [str length]; j++,n++) {
                    NSString *tempstring = [str substringWithRange:(NSMakeRange(j,1))];
                    CGFloat w = 0;
                    if ([str characterAtIndex:j] < 127) {
                        w += [tempstring sizeWithFont:_font constrainedToSize:CGSizeMake(320, MAXFLOAT) lineBreakMode:NSLineBreakByWordWrapping].width;
                        w += wordSpacing;
                        
                    }
                    else
                    {
                        w += chinesewidth;
                        w += wordSpacing;
                    }
                    
                    ZQLinkRange *tmpR = [self rangeAtIndex:n];
                    if (tmpR) {
                        
                        if (self.activeLinkRange && self.activeLinkRange.location == tmpR.location && self.activeLinkRange.length == tmpR.length) {
                            CGContextSetFillColorWithColor(context, [UIColor lightGrayColor].CGColor);
                            CGContextFillRect(context, CGRectMake(drawX, paddingTop+(lineHeight + rowSpacing +1)*i, w, lineHeight + rowSpacing));
                        }
                        CGContextSetFillColorWithColor(context, [UIColor blueColor].CGColor);
                    }else{
                        CGContextSetFillColorWithColor(context, _textColor.CGColor);
                    }
                    
                    [tempstring drawAtPoint:CGPointMake(drawX, drawY)
                                   forWidth:rect.size.width
                                   withFont:_font
                              lineBreakMode:NSLineBreakByWordWrapping];
                    drawX+= w;
                }
            }
        }
        
    }
}
#endif

- (void)fixLinkRangeAfterIndex:(NSUInteger)originalIndex withOffset:(NSInteger)offset
{
    if (self.linkRanges && [self.linkRanges count] > 0) {
        for (ZQLinkRange *lr in self.linkRanges) {
            if (lr.location >= originalIndex) {
                lr.offset += offset;
            }
        }
    }
}

- (NSMutableArray*)strArrayFromString:(NSString*)strW
{
    NSMutableArray *strArray = [[NSMutableArray alloc] init];
    int screenWidth = self.frame.size.width;
    int showwidth = 0;
    int index = 0;
    
    int subindex = 0;
    int sublength = 0;
    
    int objIndex = 0;
    
    while (index < [strW length]) {
        NSString *strtemp;
        showwidth = 0;
        sublength = 0;
        subindex = index;
        
        ZQLine *line = [[ZQLine alloc] init];
        
        while (showwidth < (screenWidth - paddingLeft*2)) {
            sublength += 1;
            if ([strW characterAtIndex:index] == '\r'){
                index += 1;
                if (index >= [strW length]) {
                    strtemp = [strW substringWithRange:NSMakeRange(subindex, sublength)];
                    objIndex += [strtemp length];
                    [line appendStr:strtemp];
                    break;
                }
            }
            
            if ([strW characterAtIndex:index] == '\n') {
                index += 1;
                strtemp = [strW substringWithRange:NSMakeRange(subindex,sublength)];
                objIndex += [strtemp length];
                [line appendStr:strtemp];
                break;
            }
            
            NSString *emoji = nil;
            if ([strW characterAtIndex:index] == '[') {
                int emojiIndex = index;
                int emojiSubIndex = index;
                
                do {
                    emojiSubIndex += 1;
                    if (emojiSubIndex >= [strW length]) {
                        break;
                    }
                    if ([strW characterAtIndex:emojiSubIndex] == ']') {
                        emoji = [strW substringWithRange:NSMakeRange(emojiIndex + 1, emojiSubIndex - emojiIndex - 1)];
                        if (0) {//TODO not in map
                            emoji = nil;
                        }
                        break;
                    }
                } while (1);
                
                if (emoji) {
                    //TODO append string() into ZQLine
                    //string : [strW substringWithRange:NSMakeRange(subindex,sublength)];
                    strtemp = [strW substringWithRange:NSMakeRange(subindex,sublength-1)];
                    objIndex += [strtemp length];
                    [line appendStr:strtemp];
                    
                    index = emojiSubIndex + 1;
                    subindex = index;
                    sublength = 0;
                }
            }
            
            if (emoji) {
                showwidth += kEmojiWidth;
            }else{
                if ([strW characterAtIndex:index] < 127) {
                    showwidth += [[strW substringWithRange:NSMakeRange(index,1)] sizeWithFont:_font
                                                                        constrainedToSize:CGSizeMake(320, MAXFLOAT)
                                                                            lineBreakMode:NSLineBreakByCharWrapping].width;
                }else{
                    showwidth += chinesewidth;
                }
            }
            
            if (showwidth > (screenWidth - paddingLeft*2)) {
                if (emoji) {
                    index -= ([emoji length]+2);
                    break;
                }else{
                    strtemp = [strW substringWithRange:NSMakeRange(subindex,sublength-1)];
                    objIndex += [strtemp length];
                    [line appendStr:strtemp];
                    break;
                }
            }else{
                if (emoji) {
                    ZQEmoji *e = [[ZQEmoji alloc] init];
                    e.filename = emoji;
                    objIndex += 1;
                    [line appendEmoji:e];
                    [e release];
                    [self fixLinkRangeAfterIndex:index withOffset:-([emoji length]+1)];
                    if (index >= [strW length])
                        break;
                }else{
                    index += 1;
                    if (index >= [strW length])
                    {
                        strtemp = [strW substringWithRange:NSMakeRange(subindex,sublength)];
                        objIndex += [strtemp length];
                        [line appendStr:strtemp];
                        break;
                    }
                    
                    showwidth += wordSpacing;
                    if (showwidth >= screenWidth -2*paddingLeft)
                    {
                        strtemp = [strW substringWithRange:NSMakeRange(subindex,sublength)];
                        objIndex += [strtemp length];
                        [line appendStr:strtemp];
                        break;
                    }
                }
                
            }
            //
        }
        
        //
        //NSLog(@"index:%d, len:%d",subindex,strtemp.length);
        //line.txt = strtemp;
        line.index = objIndex - line.length;
        //line.length = strtemp.length;
        [strArray addObject:line];
        [line release];
    }
    return [strArray autorelease];
}
#if 1
- (BOOL)isIndexInLinkRanges:(int)index
{
    if (self.linkRanges) {
        for (ZQLinkRange *lr in self.linkRanges) {
            if (NSLocationInRange(index, [lr range])) {
                return YES;
            }
        }
    }
    
    return NO;
}

- (ZQLinkRange*)rangeAtIndex:(int)index
{
    if (self.linkRanges) {
        for (ZQLinkRange *lr in self.linkRanges) {
            if (NSLocationInRange(index, [lr range])) {
                return lr;
            }
        }
    }
    
    return nil;
}

- (int)indexAtPiont:(CGPoint)pt
{
    int h = pt.y - paddingTop;
    int lineNo = ceil(h/(lineHeight + rowSpacing + 1)) - 1;
    
    NSLog(@"point on line: %d", lineNo);
    if (lineNo >= 0 && lineNo < _strArray.count) {
        ZQLine *line = [_strArray objectAtIndex:lineNo];
        int index = line.index;
        CGFloat startX = paddingLeft;
        CGFloat curse = startX;
        
        /*for (int i = 0; i < line.length; i++, index++) {
            curse = startX;
            if ([line.txt characterAtIndex:i] < 127) {
                startX += [[line.txt substringWithRange:NSMakeRange(i,1)] sizeWithFont:_font
                                                                     constrainedToSize:CGSizeMake(320, MAXFLOAT)
                                                                         lineBreakMode:NSLineBreakByCharWrapping].width;
            }else{
                startX += chinesewidth;
            }
            startX += wordSpacing;
            
            if (curse <= pt.x && pt.x < startX) {
                found = YES;
                break;
            }
        }*/
        for (id part in line.parts) {
            curse = startX;
            if ([part isKindOfClass:[ZQEmoji class]]) {
                startX += kEmojiWidth;
                startX += wordSpacing;
                
                if (curse <= pt.x && pt.x < startX) {
                    return index;
                }
                
                index++;
            }else{
                NSString *str = (NSString*)part;
                for (int i = 0, count = [str length]; i < count; i++, index++) {
                    if ([str characterAtIndex:i] < 127) {
                        startX += [[str substringWithRange:NSMakeRange(i,1)] sizeWithFont:_font
                                                                        constrainedToSize:CGSizeMake(320, MAXFLOAT)
                                                                            lineBreakMode:NSLineBreakByCharWrapping].width;
                    }else{
                        startX += chinesewidth;
                    }
                    startX += wordSpacing;
                    
                    if (curse <= pt.x && pt.x < startX) {
                        return index;
                    }
                }
            }
            
        }
    }
    return -1;
}

- (ZQLinkRange*)linkRangeAtPoint:(CGPoint)pt
{
    int index = [self indexAtPiont:pt];
    NSLog(@"index index %d", index);
    if (index >= 0) {
        return [self rangeAtIndex:index];
    }
    return nil;
}

//
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch* touch = [touches anyObject];
	CGPoint pt = [touch locationInView:self];
    
    /*int index = [self indexAtPiont:pt];
    NSLog(@"index index %d", index);
    if (index >= 0) {
        [self setNeedsDisplay];
    }*/
    
    ZQLinkRange *r = [self linkRangeAtPoint:pt];
    if (r) {
        self.activeLinkRange = r;
        [self setNeedsDisplay];
    }
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
/*    if (!linkHighlighted) {
        return;
    }
    UITouch* touch = [touches anyObject];
	CGPoint pt = [touch locationInView:self];
    
    if ([self linkAtPiont:pt]) {
        linkHighlighted = NO;
        
    }
    
*/
    if (self.activeLinkRange) {
        NSLog(@"%@",[_text substringWithRange:NSMakeRange(self.activeLinkRange.location, self.activeLinkRange.length)]);
        self.activeLinkRange = nil;
        [self setNeedsDisplay];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    /*if (linkHighlighted) {
        UITouch* touch = [touches anyObject];
        CGPoint pt = [touch locationInView:self];
        if (![self linkAtPiont:pt]) {
            linkHighlighted = NO;
            [self setNeedsDisplay];
        }
    }*/
    /*
    if (!NSEqualRanges(activeLinkRange, NSMakeRange(0, 0))) {
        UITouch* touch = [touches anyObject];
        CGPoint pt = [touch locationInView:self];
        NSRange r = [self linkRangeAtPoint:pt];
        if (NSEqualRanges(r, NSMakeRange(0, 0))) {
            activeLinkRange = NSMakeRange(0, 0);
            [self setNeedsDisplay];
        }
    }*/
}
#endif

@end

