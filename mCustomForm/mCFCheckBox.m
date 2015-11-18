#import "mCFCheckBox.h"

@implementation mCFCheckBox


- (id)init
{
  self = [super init];
  if ( self )
  {
    self.checked = NO;
    self.backgroundColor = [UIColor whiteColor];
    self.contentMode = UIViewContentModeCenter;
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
    [self setImage:[UIImage imageNamed:resourceFromBundle(@"mCF_checkbox.png")] forState:UIControlStateNormal];
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
