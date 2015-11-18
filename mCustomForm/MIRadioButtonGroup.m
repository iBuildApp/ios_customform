/*
 
 Copyright (c) 2010, Mobisoft Infotech
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are
 permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of
 conditions and the following disclaimer.
 
 Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 Neither the name of Mobisoft Infotech nor the names of its contributors may be used to
 endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS
 OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
 OF SUCH DAMAGE.
 
 */

/*
 * Contains modifications by iBuildApp, 2014-2015.
 */

#import "MIRadioButtonGroup.h"
#import "mCFRadioButton.h"
#import "NSString+size.h"

@interface MIRadioButtonGroup()

@property (nonatomic, strong) NSMutableArray *radioButtons;
@property (nonatomic, strong) NSMutableArray *labels;

@end

@implementation MIRadioButtonGroup
@synthesize radioButtons, labels;


#pragma mark -
- (id)initWithFrame:(CGRect)frame andOptions:(NSArray *)options andColumns:(int)columns andTextColor:(UIColor *)textColor
{
  if ((self = [super initWithFrame:frame]))
  {

    self.radioButtons = [NSMutableArray array];
    self.labels = [NSMutableArray array];

    const CGFloat RADIO_BUTTON_SIZE = 34.f;
    
    CGFloat y = 0;
    for (int i = 0; i < ([options count] / columns); i++)
    {
      mCFRadioButton *rb = [[mCFRadioButton alloc] initWithFrame:CGRectMake(0, y, RADIO_BUTTON_SIZE, RADIO_BUTTON_SIZE)];
      [rb addTarget:self action:@selector(radioButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
      [self addSubview:rb];
      [self.radioButtons addObject:rb];
      
      CGSize textSize = [[options objectAtIndex:i] sizeForFont:[UIFont systemFontOfSize:17.f]
                                                    limitSize:CGSizeMake(frame.size.width - RADIO_BUTTON_SIZE - 10, CGFLOAT_MAX)
                                              nslineBreakMode:NSLineBreakByWordWrapping];

      
      UIButton *labelButton = [[UIButton alloc] initWithFrame:CGRectMake(RADIO_BUTTON_SIZE + 10, y + 7,
                                                              frame.size.width - RADIO_BUTTON_SIZE - 10, textSize.height)];
      labelButton.backgroundColor                    = [UIColor clearColor];
      labelButton.titleLabel.adjustsFontSizeToFitWidth = NO;
      labelButton.titleLabel.font                    = [UIFont systemFontOfSize:17.f];
      labelButton.titleLabel.textColor               = textColor;
      //            label.shadowColor               = [UIColor colorWithWhite:0.0 alpha:0.5];
      labelButton.titleLabel.textAlignment           = NSTextAlignmentLeft;
      labelButton.contentHorizontalAlignment         = UIControlContentHorizontalAlignmentLeft;
      labelButton.titleLabel.lineBreakMode           = NSLineBreakByWordWrapping;
      
      labelButton.titleLabel.numberOfLines           = 0;
      [labelButton setTitle:[options objectAtIndex:i] forState:UIControlStateNormal];
      [labelButton setTitleColor:textColor forState:UIControlStateNormal];
      [labelButton addTarget:self action:@selector(labelButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
      labelButton.tag = i;
        
      [self addSubview:labelButton];
      [self.labels addObject:labelButton];
  
      y += MAX(RADIO_BUTTON_SIZE + 15, 7 + labelButton.frame.size.height + 15);
    }
    
    self.frame = CGRectMake(frame.origin.x, frame.origin.y, self.frame.size.width, y);
    
  }
  return self;
}


#pragma mark -

- (void)labelButtonClicked:(UIButton *) sender
{
  [self clearAll];
  ((mCFRadioButton *)self.radioButtons[sender.tag]).checked = YES;
}

- (void)radioButtonClicked:(mCFRadioButton *) sender
{
  [self clearAll];
  sender.checked = YES;
}

- (void)removeButtonAtIndex:(int)index
{
  [[self.radioButtons objectAtIndex:index] removeFromSuperview];
}

-(void) setSelected:(int)index
{
  [self clearAll];
  
  if (index > -1)
    ((mCFRadioButton *)self.radioButtons[index]).checked = YES;
}

- (NSString*)getSelected
{
  for (int i = 0; i < self.radioButtons.count; i++)
  {
    if (((mCFRadioButton *)self.radioButtons[i]).checked)
      return ((UIButton *)self.labels[i]).titleLabel.text;
  }
  
  return nil;
}

- (void)clearAll
{
  for (int i = 0; i < self.radioButtons.count; i++)
    ((mCFRadioButton *)self.radioButtons[i]).checked = NO;
}

@end
