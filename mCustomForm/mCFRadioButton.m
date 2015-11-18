#import "mCFRadioButton.h"


@implementation mCFRadioButton

- (id)initWithFrame:(CGRect)rect
{
  self = [super initWithFrame:rect];
  if ( self )
  {
    self.checked = NO;
    self.backgroundColor = [UIColor whiteColor];
    self.contentMode = UIViewContentModeCenter;
    self.layer.cornerRadius = rect.size.width / 2;
    self.layer.borderWidth = 1.f;
    self.layer.borderColor = [[UIColor blackColor] colorWithAlphaComponent:0.4f].CGColor;
    
    [self addTarget:self action:@selector(onTap) forControlEvents:UIControlEventTouchUpInside];
  }
  return self;
}

- (void) setChecked:(BOOL)checked
{
  if (checked)
  {
    [self setImage:[UIImage imageNamed:resourceFromBundle(@"mCF_radio_on.png")] forState:UIControlStateNormal];
    _checked = YES;
  }
  else
  {
    [self setImage:nil forState:UIControlStateNormal];
    _checked = NO;
  }
}

- (void) onTap
{
  self.checked = !self.checked;
}

@end
