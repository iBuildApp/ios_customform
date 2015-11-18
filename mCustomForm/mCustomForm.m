/****************************************************************************
 *                                                                           *
 *  Copyright (C) 2014-2015 iBuildApp, Inc. ( http://ibuildapp.com )         *
 *                                                                           *
 *  This file is part of iBuildApp.                                          *
 *                                                                           *
 *  This Source Code Form is subject to the terms of the iBuildApp License.  *
 *  You can obtain one at http://ibuildapp.com/license/                      *
 *                                                                           *
 ****************************************************************************/

#import "mCustomForm.h"
#import <QuartzCore/QuartzCore.h>
#import "NSString+colorizer.h"
#import "UIImage+color.h"
#import "UIColor+HSL.h"
#import "MIRadioButtonGroup.h"
#import "functionLibrary.h"
#import "TPKeyboardAvoidingTableView.h"
#import "GCPlaceholderTextView.h"
#import "TBXML.h"

#import "mCFCheckBox.h"

#define SystemDefaultFontSize 17.0f
#define SystemDefaultFont [UIFont boldSystemFontOfSize:SystemDefaultFontSize]
#define FormHeaderFont    [UIFont fontWithName:@"Helvetica-Bold" size:18.0f]

#define kCheckboxMarginLeft 10.0f
#define kCheckboxMarginTop 0.f
#define kCheckboxWidth 34.0f

#define kCheckboxLabelOriginX (kCheckboxWidth + 2 * kCheckboxMarginLeft)
#define kCheckboxLabelWidth (320 - kCheckboxLabelOriginX - kCheckboxMarginLeft)

#define kTextFieldHeight 44.f

/**
 *  Customized UILabel
 */
@interface TExtendedLabel : UILabel

/**
 *  Content inset
 */
@property (nonatomic, assign) UIEdgeInsets contentInset;

@end

@implementation TExtendedLabel

- (id)init
{
  self = [super init];
  if ( self )
  {
    self.contentInset = UIEdgeInsetsMake(0.f, 0.f, 0.f, 0.f);
  }
  return self;
}

- (void)drawTextInRect:(CGRect)rect
{
  return [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.contentInset)];
}

@end


@interface TExtendedLabel(DropdownBackground)

-(UIView *)generateBackroundWithColor:(UIColor *) color;

@end

@implementation TExtendedLabel(DropdownBackground)

-(UIView *)generateBackroundWithColor:(UIColor *) color{
  /*
   * Little workaround to remove ugly white corners on dropdown.
   */
  UIView *dropDownBackgroundView = [[UIView alloc] initWithFrame:self.frame];
  dropDownBackgroundView.backgroundColor = color;
  dropDownBackgroundView.layer.cornerRadius = self.layer.cornerRadius;
  return dropDownBackgroundView;
}

@end


/**
 *  Content inset
 */
@interface TExtendedTextField : UITextField

/**
 *  Content inset
 */
@property (nonatomic, assign) UIEdgeInsets contentInset;

@end



@implementation TExtendedTextField

- (id)init
{
  self = [super init];
  if ( self )
  {
    self.contentInset = UIEdgeInsetsMake(0.f, 0.f, 0.f, 0.f);
  }
  return self;
}

- (CGRect)textRectForBounds:(CGRect)bounds
{
  return UIEdgeInsetsInsetRect( bounds, _contentInset );
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
  return UIEdgeInsetsInsetRect( bounds, _contentInset );
}

@end


@interface mCustomFormViewController()
/**
 *  TableView with magic autoscrolling, for displaying components of the form
 */
@property(nonatomic, strong) TPKeyboardAvoidingTableView *tableView;

/**
 *  Index of focused element
 */
@property(nonatomic, strong) NSIndexPath                 *elementIndex;

/**
 *  Add link to ibuildapp.com to email messages
 */
@property (nonatomic, assign) BOOL                        showLink;

#pragma mark -
/**
 *  Create radio buttons
 *
 *  @param obj Dictionary to set values
 */
- (void)createRadioButtons:(NSMutableDictionary *)obj;

/**
 *  Create groups with settings for UI elements
 */
- (void)createElements;

/**
 *  Save picker values
 */
- (void)saveDropdown;

/**
 *  Save date picker values
 */
- (void)saveDatePicker;

/**
 *  Remove child views from pickerView
 */
- (void)removeChildViews;

/**
 *  Send email
 */
- (void)sendEmail;

/**
 *  resignFirstResponder after editing
 */
- (void)textFieldFinished;
@end


@interface mCustomFormViewController()
@property (nonatomic, assign) float fieldWidth;
@property (nonatomic, retain) UIColor *color3spec;
@property (nonatomic, retain) UIColor *color5spec;
@end

@implementation mCustomFormViewController


/**
 *  Special parser for processing original xml file
 *
 *  @param xmlElement_ NSValue* xmlElement_
 *  @param params_     NSMutableDictionary* params_
 */
+ (void)parseXML:(NSValue *)xmlElement_
     withParams:(NSMutableDictionary *)params_
{
  TBXMLElement element;
  [xmlElement_ getValue:&element];

  NSMutableArray *contentArray = [[NSMutableArray alloc] init];
  
  NSMutableDictionary *colorSkin = [NSMutableDictionary dictionary];
  
  TBXMLElement *data = &element;
  TBXMLElement *dataChild = data->firstChild;
  
  while(dataChild)
  {
    if ([[TBXML elementName:dataChild] isEqualToString:@"colorskin"])
    {
      if ([TBXML childElementNamed:@"color1" parentElement:dataChild])
        [colorSkin setValue:[TBXML textForElement:[TBXML childElementNamed:@"color1" parentElement:dataChild]] forKey:@"color1"];
      
      if ([TBXML childElementNamed:@"color2" parentElement:dataChild])
        [colorSkin setValue:[TBXML textForElement:[TBXML childElementNamed:@"color2" parentElement:dataChild]] forKey:@"color2"];
      
      if ([TBXML childElementNamed:@"color3" parentElement:dataChild])
        [colorSkin setValue:[TBXML textForElement:[TBXML childElementNamed:@"color3" parentElement:dataChild]] forKey:@"color3"];
      
      if ([TBXML childElementNamed:@"color4" parentElement:dataChild])
        [colorSkin setValue:[TBXML textForElement:[TBXML childElementNamed:@"color4" parentElement:dataChild]] forKey:@"color4"];
      
      if ([TBXML childElementNamed:@"color5" parentElement:dataChild])
        [colorSkin setValue:[TBXML textForElement:[TBXML childElementNamed:@"color5" parentElement:dataChild]] forKey:@"color5"];
    }
    
    dataChild = dataChild->nextSibling;
  };
  
  NSString *szTitle = @"";
  TBXMLElement *titleElement = [TBXML childElementNamed:@"title" parentElement:&element];
  
  if ( titleElement )
    szTitle = [TBXML textForElement:titleElement];
  
    // 1. adding a zero element to array
  [contentArray addObject:[NSDictionary dictionaryWithObject:szTitle ? szTitle : @"" forKey:@"title" ] ];
  
  TBXMLElement *formItemElement = [TBXML childElementNamed:@"form" parentElement:&element];
    // start cycle for all form's elements
  while( formItemElement )
  {
    NSMutableDictionary *formDictionary = [[NSMutableDictionary alloc] init];
    TBXMLElement *emailElement = [TBXML childElementNamed:@"email" parentElement:formItemElement];
    
    if ( emailElement )
    {
      TBXMLElement *emailAddress      = [TBXML childElementNamed:@"address" parentElement:emailElement];
      TBXMLElement *emailSubject      = [TBXML childElementNamed:@"subject" parentElement:emailElement];
      TBXMLElement *emailButton       = [TBXML childElementNamed:@"button"  parentElement:emailElement];
      TBXMLElement *emailButtonLabel  = nil;
      
      if ( emailButton )
        emailButtonLabel  = [TBXML childElementNamed:@"label"   parentElement:emailButton];
      
      NSMutableDictionary *emailDictionary = [[NSMutableDictionary alloc] init];
      
      if ( emailAddress )
        [emailDictionary setObject:[TBXML textForElement:emailAddress] forKey:@"address"];
      
      if ( emailSubject )
        [emailDictionary setObject:[TBXML textForElement:emailSubject] forKey:@"subject"];
      
      if ( emailButtonLabel )
        [emailDictionary setObject:[TBXML textForElement:emailButtonLabel] forKey:@"label"];
      
      [formDictionary setObject:emailDictionary
                         forKey:@"email"];
    }
    
    NSMutableArray *groupsArray = [[NSMutableArray alloc] init];
    TBXMLElement *groupElement = [TBXML childElementNamed:@"group" parentElement:formItemElement];
    while( groupElement )
    {
      NSMutableArray *singleGroupArray = [[NSMutableArray alloc] init];
      
      TBXMLElement *title = [TBXML childElementNamed:@"title" parentElement:groupElement];
      
      if ( title )
        [singleGroupArray addObject:[NSDictionary dictionaryWithObjectsAndKeys: [TBXML textForElement:title ], @"title", nil]];
      
      NSArray *itemsNameFilter = [NSArray arrayWithObjects:@"entryfield",
                                  @"textarea",
                                  @"checkbox",
                                  @"radiobutton",
                                  @"dropdown",
                                  @"datepicker", nil];
      
      TBXMLElement *groupItem = groupElement->firstChild;
      
      while( groupItem )
      {
        if ( [itemsNameFilter containsObject:[TBXML elementName:groupItem]] )
        {
          NSMutableDictionary *itemDictionary = [[NSMutableDictionary alloc] init];
          [itemDictionary setObject:[TBXML elementName:groupItem] forKey:@"type"];
          
            // cycle for all attributes
          TBXMLAttribute *itemAttribute = groupItem->firstAttribute;
          while( itemAttribute )
          {
            if ( [[TBXML attributeName:itemAttribute] isEqualToString:@"format"] )
            {
              [itemDictionary setObject:[TBXML attributeValue:itemAttribute] forKey:@"format"];
              break;
            }
            itemAttribute = itemAttribute->next;
          }
          TBXMLElement *label = [TBXML childElementNamed:@"label" parentElement:groupItem];
          
          if ( label )
            [itemDictionary setObject:[TBXML textForElement:label] forKey:@"label"];
          
          NSMutableArray *itemValues = [[NSMutableArray alloc] init];
          TBXMLElement *value = [TBXML childElementNamed:@"value" parentElement:groupItem];
          
          while( value )
          {
            [itemValues addObject:[TBXML textForElement:value]];
            value = [TBXML nextSiblingNamed:@"value"
                          searchFromElement:value];
          }
          
          if ( itemValues.count )
            [itemDictionary setObject:itemValues forKey:@"value"];
          
          [singleGroupArray addObject:itemDictionary];
        }
        
        groupItem = groupItem->nextSibling;
        
      }// end of groupItem iterator
      
      [groupsArray addObject:singleGroupArray];
      groupElement = [TBXML nextSiblingNamed:@"group"
                           searchFromElement:groupElement];
      
    }/// end groupElement iterator
    
      // save elenents array to dictionary
    if ( groupsArray.count )
      [formDictionary setObject:groupsArray
                         forKey:@"groups"];
    
    [contentArray addObject:formDictionary];
    
    formItemElement = [TBXML nextSiblingNamed:@"form"
                            searchFromElement:formItemElement];
    
  }// end formItemElement iterator
  
  [params_ setObject:contentArray forKey:@"data"];
  
  if (colorSkin.count)
    [params_ setObject:colorSkin forKey:@"colorskin"];
  
}

- (void)setParams:(NSMutableDictionary *)inputParams
{
  NSMutableArray *data = [inputParams objectForKey:@"data"];
  NSRange range = NSMakeRange( 1, [data count] - 1 );
  
  elements = [[NSMutableArray alloc] initWithArray:[data objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:range]] copyItems:true];
  
  if ([inputParams objectForKey:@"colorskin"])
  {
    self.mCFColorOfBackground = [[[inputParams objectForKey:@"colorskin"] objectForKey:@"color1"] asColor];
    self.mCFColorOfHeader     = [[[inputParams objectForKey:@"colorskin"] objectForKey:@"color2"] asColor];
    self.color3spec           = [[[inputParams objectForKey:@"colorskin"] objectForKey:@"color3"] asColor];
    self.mCFColorOfText       = [[[inputParams objectForKey:@"colorskin"] objectForKey:@"color4"] asColor];
    self.color5spec           = [[[inputParams objectForKey:@"colorskin"] objectForKey:@"color5"] asColor];
  }
  
  self.title    = [inputParams objectForKey:@"title"];
  self.showLink = [[inputParams objectForKey:@"showLink"] isEqual:@"1"];
}


#pragma mark - init and creating elements

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if ( self )
  {
    self.tableView    = nil;
    self.elementIndex = nil;
    self.showLink     = NO;
    
    self.mCFColorOfBackground = [UIColor colorWithRed:94.0f / 255.0f green:104.0f / 255.0f blue:112.0f / 255.0f alpha:1.0f];
    self.mCFColorOfHeader     = [UIColor whiteColor];
    self.mCFColorOfText       = [UIColor colorWithRed:255.0f/255.0f green:190.0f/255.0f blue:106.0f/255.0f alpha:1.0f];
    
    chRB = -1;
  }
  
  return self;
}

- (void)createElements
{
  NSArray *groupsTmp = [[elements objectAtIndex:0] objectForKey:@"groups"];
  
  rbCount = 0;
  
  groupTitles = [[NSMutableArray alloc] init];
  groups = [[NSMutableArray alloc] init];
  NSMutableArray *groupElements;
  NSMutableDictionary *object;
  
  for (NSArray *singleGroup in groupsTmp)
  {
    NSString *title = [[singleGroup objectAtIndex:0] objectForKey:@"title"];
    
    if (title)
      [groupTitles addObject:title];
    else
      [groupTitles addObject:@""];
    
    int i = 0;
    
    groupElements = [[NSMutableArray alloc] init];
    
    for(NSDictionary *elementOfGroup in singleGroup)
    {
      NSString        *type = [elementOfGroup objectForKey:@"type"];
      NSString   *labelText = [elementOfGroup objectForKey:@"label"];
      NSMutableArray *value = [elementOfGroup objectForKey:@"value"];
      NSString      *format = [elementOfGroup objectForKey:@"format"];
      
      if (type)
      {
        object = [[NSMutableDictionary alloc] init];
        if (rbCount > 0 && ![type isEqualToString:@"radiobutton"])
        {
          [self createRadioButtons:object];
          [groupElements addObject:object];
          object = [[NSMutableDictionary alloc] init];
        }
        
        if (labelText && ![type isEqualToString:@"radiobutton"])
          [object setObject:labelText forKey:@"label"];
        
        if ([type isEqualToString:@"textarea"])
        {
          GCPlaceholderTextView *textView = [[GCPlaceholderTextView alloc] initWithFrame:CGRectMake(10, labelText?30:10, self.fieldWidth, 90)];
          textView.backgroundColor = [UIColor whiteColor];
          textView.textColor       = [[UIColor blackColor] colorWithAlphaComponent:0.9f];
          textView.placeholderColor= [@"#8c8c8c" asColor];
          textView.delegate        = self;
          textView.font            = [UIFont systemFontOfSize:19.0f];
          textView.layer.borderColor = [[UIColor blackColor] colorWithAlphaComponent:0.4f].CGColor;
          textView.layer.borderWidth = 1.0f;

          textView.placeholder = value && [value count] && ![[value objectAtIndex:0] isEqualToString:@""] ? [value objectAtIndex:0] : @" ";
          
          CGSize textsize=[textView.text sizeForFont:[UIFont systemFontOfSize:15.0f]
                                           limitSize:CGSizeMake(self.fieldWidth, 2000.0)
                                     nslineBreakMode:NSLineBreakByWordWrapping];
          
          if (labelText)
          {
            CGSize labelsize=[labelText sizeForFont:[UIFont systemFontOfSize:17.0f]
                                          limitSize:CGSizeMake(self.fieldWidth, 2000.0)
                                    nslineBreakMode:NSLineBreakByWordWrapping];
            
            textView.frame = CGRectMake(10, labelsize.height + 10, self.fieldWidth, MIN(MAX(textsize.height,textView.frame.size.height),120));
          }
          else
            textView.frame = CGRectMake(10, 0, self.fieldWidth, MIN(MAX(textsize.height,textView.frame.size.height),120));
          
          [object setObject:textView forKey:@"object"];
          [object setObject:type forKey:@"type"];
        }
        else if ([type isEqualToString:@"entryfield"])
        {
          TExtendedTextField *textView = [[TExtendedTextField alloc] initWithFrame:CGRectMake(10, labelText?30:10, self.fieldWidth, kTextFieldHeight)];
          textView.backgroundColor = [UIColor whiteColor];
          textView.textColor       = [[UIColor blackColor] colorWithAlphaComponent:0.9f];
          textView.delegate        = self;
          textView.font            = [UIFont systemFontOfSize:19.0f];
          textView.contentInset    = UIEdgeInsetsMake(0.f, 7.f, 0.f, 7.f);
          textView.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
          textView.layer.borderColor = [[UIColor blackColor] colorWithAlphaComponent:0.4f].CGColor;
          textView.layer.borderWidth = 1.0f;
          
          if (value&&[value count])
          {
            NSAttributedString *str = [[NSAttributedString alloc] initWithString:[value objectAtIndex:0] attributes:@{ NSForegroundColorAttributeName : [@"#8c8c8c" asColor] }];
            textView.attributedPlaceholder = str;
          }
          
          if (labelText)
          {
            CGSize labelsize=[labelText sizeForFont:[UIFont systemFontOfSize:17.0f]
                                          limitSize:CGSizeMake(self.fieldWidth, 2000.0)
                                    nslineBreakMode:NSLineBreakByWordWrapping];
            
            textView.frame = CGRectMake(10, labelsize.height + 10, self.fieldWidth, kTextFieldHeight);
          }
          else
            textView.frame = CGRectMake(10, 0, self.fieldWidth, kTextFieldHeight);
          
          if ([format isEqualToString:@"number"])
            textView.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
          
          [object setObject:textView forKey:@"object"];
          [object setObject:type forKey:@"type"];
        }
        else if ([type isEqualToString:@"datepicker"])
        {
          UIDatePicker *datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0, 152, 10, 10)];
          datePicker.datePickerMode = UIDatePickerModeDate;
          datePicker.autoresizingMask = UIViewAutoresizingFlexibleWidth;
          
          if (value && [value count])
          {
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:NSBundleLocalizedString(@"mCF_date_format", @"xx/yy/zz")];
            NSDate *date = [dateFormat dateFromString:[value objectAtIndex:0]];
            if ( date )
            {
              datePicker.date = date;
            }
            else
            {
              //datePicker.date = [NSDate date];
              [value replaceObjectAtIndex:0
                               withObject:NSBundleLocalizedString(@"mCF_date_placeholder", @"MM/DD/YYYY")];
            }
            [object setObject:[value objectAtIndex:0] forKey:@"date"];
          }
          [object setObject:datePicker forKey:@"object"];
          [object setObject:@"datepicker" forKey:@"type"];
        }
        else if ([type isEqualToString:@"dropdown"])
        {
          if (!ddArray)
            ddArray = [[NSMutableArray alloc] init];
          
          if (!ddValues)
            ddValues = [[NSMutableArray alloc] init];
          
          if (value&&[value count])
          {
            UIPickerView *pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 152, 0, 0)];
            pickerView.delegate = self;
            pickerView.dataSource = self;
            pickerView.showsSelectionIndicator = YES;
            
            [ddArray addObject:pickerView];
            
            [object setObject:pickerView forKey:@"object"];
            [object setObject:@"dropdown" forKey:@"type"];
            [object setObject:value forKey:@"value"];
            
            [ddValues addObject:value];
          }
        }
        else if ([type isEqualToString:@"checkbox"])
        {
          mCFCheckBox *checkbox = [[mCFCheckBox alloc] init];
          checkbox.frame = CGRectMake(kCheckboxMarginLeft, 0, kCheckboxWidth, kCheckboxWidth);
          
          if (value&&[value count]&&[[value objectAtIndex:0] isEqualToString:@"checked"])
            checkbox.checked = YES;
          
          [object setObject:@"checkbox" forKey:@"type"];
          [object setObject:checkbox forKey:@"object"];
        }
        else if ([type isEqualToString:@"radiobutton"])
        {
          if (!rbElements) rbElements = [[NSMutableArray alloc] init];
          
          rbCount++;
          
          if (labelText)
            [rbElements addObject:labelText];
          else
            [rbElements addObject:@""];
          
          if (value&&[value count]&&[[value objectAtIndex:0] isEqualToString:@"checked"])
            chRB = rbCount-1;
          
        }
        
        if (rbCount>0&&i==[singleGroup count]-2)
        {
          [self createRadioButtons:object];
        }
        i++;
        
        if ([object count]>0)
          [groupElements addObject:object];
      }
    }
    
    [groups addObject:groupElements];
  }
  
  groupElements = [[NSMutableArray alloc] init];
  
  NSString *sendTitle = [[[elements objectAtIndex:0] objectForKey:@"email"] objectForKey:@"label"];
  

  UIButton *btnSend = [UIButton buttonWithType:UIButtonTypeCustom];
  btnSend.titleLabel.font = [UIFont systemFontOfSize:22.0f];
  //CGSize btnSize = [sendTitle ? sendTitle:NSBundleLocalizedString(@"mCF_sendButton", @"Send") sizeWithFont:btnSend.titleLabel.font];
  //float btnWidth = MAX(160, btnSize.width + 10);
  btnSend.frame = CGRectMake(10, 0.0f, self.fieldWidth, kTextFieldHeight);
  btnSend.layer.masksToBounds = YES;
  btnSend.backgroundColor = self.color5spec;
  [btnSend addTarget:self action:@selector(sendEmail) forControlEvents:UIControlEventTouchUpInside];
  [btnSend setContentHorizontalAlignment: UIControlContentHorizontalAlignmentCenter];
  [btnSend setTitle:sendTitle?sendTitle:NSBundleLocalizedString(@"mCF_sendButton", @"Send") forState:UIControlStateNormal];
  [btnSend setTitleColor:self.mCFColorOfBackground forState:UIControlStateNormal];
  
  object = [[NSMutableDictionary alloc] init];
  
  [object setObject:btnSend forKey:@"object"];
  [object setObject:@"btnSend" forKey:@"type"];
  
  [groupElements addObject:object];
  
  [groups addObject:groupElements];
  
  [groupTitles addObject:@""];
}

- (void) createRadioButtons:(NSMutableDictionary *)obj
{
  NSArray *options =[[NSArray alloc] initWithArray:rbElements];
  MIRadioButtonGroup *RBgroup =[[MIRadioButtonGroup alloc] initWithFrame:CGRectMake(10, 0, self.fieldWidth, rbCount * 50) andOptions:options andColumns:1 andTextColor:self.color3spec];
  [RBgroup setSelected:chRB];
  [obj setObject:RBgroup forKey:@"object"];
  [obj setObject:@"radiobutton" forKey:@"type"];
  [obj setObject:[NSNumber numberWithInt:rbCount] forKey:@"count"];
  
  rbCount = 0;
  chRB = -1;
  [rbElements removeAllObjects];
}



#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
  [self.navigationController setNavigationBarHidden:NO animated:YES];
  [self.navigationItem setHidesBackButton:NO animated:YES];
  [[self.tabBarController tabBar] setHidden:NO];
  
  self.tableView = [[TPKeyboardAvoidingTableView alloc] initWithFrame:self.view.bounds
                                                                 style:UITableViewStyleGrouped];
  self.tableView.autoresizesSubviews = YES;
  self.tableView.autoresizingMask    = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.separatorColor = [UIColor clearColor];
#ifdef __IPHONE_7_0
  
  if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)])
    [self.tableView setSeparatorInset:UIEdgeInsetsZero];
  
  if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)])
    [self.tableView setLayoutMargins:UIEdgeInsetsZero];
  
#endif
  self.tableView.contentMode = UIViewContentModeScaleToFill;
  self.tableView.autoresizesSubviews = YES;
  
    // on iOS7 grouped cells have drawn the entire width of the screen, so we change width of text fields:
  
#ifdef __IPHONE_7_0
  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    self.fieldWidth = 300;
#endif
  
  UIImageView *bgView = [[UIImageView alloc] initWithFrame:self.tableView.frame];
  bgView.backgroundColor = self.mCFColorOfBackground;
  
  self.tableView.backgroundView = bgView;
  
  [self.view addSubview:self.tableView];
  
  self.view.contentMode = UIViewContentModeScaleToFill;
  self.view.autoresizesSubviews = YES;
  
  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    self.fieldWidth = self.view.frame.size.width - 20;
  else
    self.fieldWidth = self.view.frame.size.width - 40;

  
  [self createElements];
}

- (void) viewWillDisappear:(BOOL)animated
{
  [[NSNotificationCenter defaultCenter]
   removeObserver:self];
  [super viewWillDisappear:animated];
}


#pragma mark -
#pragma mark Table delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [groups count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [[groups objectAtIndex:section] count];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSString *type = [[[groups objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"type"];
  
  if (![type isEqualToString:@"entryfield"] && ![type isEqualToString:@"textarea"] && [self.view viewWithTag:6] != nil)
  {
    [[self.view viewWithTag:6] removeFromSuperview];
    [Field resignFirstResponder];
  }
  
  if ([type isEqualToString:@"datepicker"]||[type isEqualToString:@"dropdown"] || [type isEqualToString:@"checkbox"])
    return indexPath;
  else
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView_ cellForRowAtIndexPath:(NSIndexPath *)indexPath_
{
  NSString *CellIdentifier = [NSString stringWithFormat:@"Cell%li%li" ,(long)indexPath_.section,(long)indexPath_.row];
  UITableViewCell *cell;
  cell = [tableView_ dequeueReusableCellWithIdentifier:CellIdentifier];
  
  if (cell == nil)
  {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = self.mCFColorOfBackground;
    
    NSDictionary *dcObj = [[groups objectAtIndex:indexPath_.section] objectAtIndex:indexPath_.row];
    
    NSString *type      = [dcObj objectForKey:@"type"];
    NSString *labelText = [dcObj objectForKey:@"label"];
    
    CGSize labelsize = CGSizeMake(0, 0);
    
    if (labelText&&![type isEqualToString:@"radiobutton"])
    {
      TExtendedLabel *label = nil;
      
      if ([type isEqualToString:@"checkbox"])
      {
        //Fix that sizeForFont: returns size smaller than needed to fit some strings
        labelsize=[labelText sizeForFont:[UIFont systemFontOfSize:17.f]
                               limitSize:CGSizeMake(self.fieldWidth - kCheckboxWidth - 10, 2000.0)
                         nslineBreakMode:NSLineBreakByWordWrapping];
        
        label = [[TExtendedLabel alloc] initWithFrame:CGRectMake(kCheckboxLabelOriginX, 7, kCheckboxLabelWidth, labelsize.height)];
      }
      else
      {
        labelsize=[labelText sizeForFont:[UIFont systemFontOfSize:17.f]
                               limitSize:CGSizeMake(self.fieldWidth, 2000.0)
                         nslineBreakMode:NSLineBreakByWordWrapping];
        
        
        label = [[TExtendedLabel alloc] initWithFrame:CGRectMake(10, 0, self.fieldWidth, labelsize.height)];
        
      }
      label.backgroundColor           = [UIColor clearColor];
      label.adjustsFontSizeToFitWidth = NO;
      label.font                      = [UIFont systemFontOfSize:17.f];
      label.textAlignment           = NSTextAlignmentLeft;
      label.lineBreakMode           = NSLineBreakByWordWrapping;
   
      label.textColor                 = self.color3spec;
      label.text                      = labelText;
      label.numberOfLines             = 0;
      
      [cell.contentView addSubview:label];
    }
    
    if ([type isEqualToString:@"datepicker"])
    {
      TExtendedLabel *labelDate = [[TExtendedLabel alloc] initWithFrame:CGRectMake(10, labelsize.height + 10, self.fieldWidth, kTextFieldHeight)];
      labelDate.backgroundColor           = [UIColor whiteColor];//Little workaround to remove ugly white corners on dropdown.
      labelDate.adjustsFontSizeToFitWidth = NO;
      labelDate.font                      = [UIFont systemFontOfSize:19.0f];
      labelDate.textAlignment             = NSTextAlignmentLeft;
      labelDate.textColor                 = [[UIColor blackColor] colorWithAlphaComponent:0.9f];
      labelDate.tag                       = 1;
      labelDate.contentInset              = UIEdgeInsetsMake(2.f, 7.f, 2.f, 7.f);
      [labelDate.layer setBorderColor: [[UIColor blackColor] colorWithAlphaComponent:0.4f].CGColor];
      [labelDate.layer setBorderWidth: 1.0];
      
      UIImage *imgDown = [UIImage imageNamed:resourceFromBundle(@"mCF_arrow_list.png")];
      UIImageView *imgView = [[UIImageView alloc] init];
      imgView.contentMode  = UIViewContentModeCenter;
      imgView.image = imgDown;
      imgView.frame = CGRectMake(labelDate.frame.size.width - imgDown.size.width - 10.0f, (labelDate.frame.size.height / 2) - (imgDown.size.height / 2), imgDown.size.width, imgDown.size.height);
      [labelDate addSubview:imgView];
      
      NSString *d = [[[groups objectAtIndex:indexPath_.section] objectAtIndex:indexPath_.row] objectForKey:@"date"];
      
      if (d)
        labelDate.text = d;
      
      UIView *dropDownBackgroundView = [labelDate generateBackroundWithColor:[UIColor whiteColor]];
      [cell.contentView addSubview:dropDownBackgroundView];
      
      [cell.contentView addSubview:labelDate];

    }
    else if ([type isEqualToString:@"dropdown"] )
    {//drawing dropdown
      TExtendedLabel *labelDate = [[TExtendedLabel alloc] initWithFrame:CGRectMake( 10, labelsize.height + 10, self.fieldWidth, kTextFieldHeight )];
      labelDate.backgroundColor           = [UIColor whiteColor];
      labelDate.adjustsFontSizeToFitWidth = NO;
      labelDate.font                      = [UIFont systemFontOfSize:19.0f];
      labelDate.textAlignment             = NSTextAlignmentLeft;
      labelDate.textColor                 = [[UIColor blackColor] colorWithAlphaComponent:0.9f];
      labelDate.contentInset              = UIEdgeInsetsMake(2.f, 7.f, 2.f, 7.f);
      [labelDate.layer setBorderColor: [[UIColor blackColor] colorWithAlphaComponent:0.4f].CGColor];
      [labelDate.layer setBorderWidth: 1.0];
      
      NSArray *vals = [dcObj objectForKey:@"value"];
      
      if ( [vals count] )
      {
        NSString *text = [vals objectAtIndex:0];
        labelDate.text = [text length] > 22 ? [NSString stringWithFormat:@"%@...", [text substringToIndex:22]] : text;
      }
      
      labelDate.tag = 1;
      
      UIImage *imgDown = [UIImage imageNamed:resourceFromBundle(@"mCF_arrow_list.png")];
      UIImageView *imgView = [[UIImageView alloc] init];
      imgView.contentMode  = UIViewContentModeCenter;
      imgView.image = imgDown;
      imgView.frame = CGRectMake(labelDate.frame.size.width - imgDown.size.width - 10.0f, (labelDate.frame.size.height / 2) - (imgDown.size.height / 2), imgDown.size.width, imgDown.size.height);
      [labelDate addSubview:imgView];
      
      [cell.contentView addSubview:labelDate];
    }
    else
      [cell.contentView addSubview:[[[groups objectAtIndex:indexPath_.section] objectAtIndex:indexPath_.row] objectForKey:@"object"]];
  }
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSString *labelText = [[[groups objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"label"];
  
  id object = [[[groups objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"object"];
  
  if ([object isKindOfClass:[UITextView class]] ||
      [object isKindOfClass:[UITextField class]])
  {
    CGSize labelsize=[labelText sizeForFont:[UIFont systemFontOfSize:17.f]
                                  limitSize:CGSizeMake(self.fieldWidth, 2000.0)
                            nslineBreakMode:NSLineBreakByWordWrapping];
    
    UITextView *obj = object;
    return labelsize.height+obj.frame.size.height + 30;
    
  }else if ([object isKindOfClass:[UIPickerView class]] ||
            [object isKindOfClass:[UIDatePicker class]])
  {
    CGSize labelsize=[labelText sizeForFont:[UIFont systemFontOfSize:17.f]
                                  limitSize:CGSizeMake(self.fieldWidth, 2000.0)
                            nslineBreakMode:NSLineBreakByWordWrapping];
    
    return labelsize.height+kTextFieldHeight + 30;
  }
  else if ([object isKindOfClass:[mCFCheckBox class]])
  {
    //Fix that sizeForFont: returns size smaller than needed to fit some strings
    CGSize labelsize=[labelText sizeForFont:[UIFont systemFontOfSize:17.f]
                           limitSize:CGSizeMake(self.fieldWidth - kCheckboxWidth - 10, 2000.0)
                     nslineBreakMode:NSLineBreakByWordWrapping];
    
    return (CGFloat)MAX(labelsize.height + 7 + 20, kCheckboxWidth + 20);
  }
  else if ([object isKindOfClass:[MIRadioButtonGroup class]])
  {
    MIRadioButtonGroup *radioButtons = object;
    return radioButtons.frame.size.height;
  }
  else
    return 60;
}


- (void)tableView:(UITableView *)tableView_ didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSString *type = [[[groups objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"type"];
  
  if ([type isEqualToString:@"checkbox"])
  {
    mCFCheckBox *cb = [[[groups objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"object"];
    cb.checked = !cb.checked;
    
    return;
  }
  
  self.elementIndex = [indexPath copy];
  [tableView_ deselectRowAtIndexPath:indexPath animated:NO];
  
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, tableView_.frame.size.height)];
  view.backgroundColor = [UIColor clearColor];
  view.autoresizesSubviews = NO;
  view.tag = 2;
  
  UIView *pickerBackground = [[UIView alloc] init];
  pickerBackground.frame = CGRectMake(0, self.tableView.frame.size.height - 260, self.tableView.frame.size.width, 260);
  
  pickerBackground.backgroundColor = [UIColor clearColor];
  
#ifdef __IPHONE_7_0
  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    pickerBackground.backgroundColor = [UIColor whiteColor];
#endif
  
  [view addSubview:pickerBackground];
  
  UIToolbar *pickerDateToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.tableView.frame.size.height - 260, self.tableView.frame.size.width, 44)];
  pickerDateToolbar.barStyle = UIBarStyleBlackOpaque;
  
  NSMutableArray *barItems = [[NSMutableArray alloc] init];
  
  UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(removeChildViews)];

  [barItems addObject:cancelBtn];
  
  UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
  [barItems addObject:flexSpace];
  
  if ([type isEqualToString:@"datepicker"])
  {
    UIDatePicker *obj = [[[groups objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"object"];
    obj.tag = 3;
    obj.frame = CGRectMake(0, self.tableView.frame.size.height-216, self.tableView.frame.size.width, 216);
    [view addSubview:obj];
    
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(saveDatePicker)];
    [barItems addObject:doneBtn];
  }
  else if ([type isEqualToString:@"dropdown"])
  {
    UIPickerView *obj = [[[groups objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectForKey:@"object"];
    obj.tag = 3;
    obj.frame = CGRectMake(0, self.tableView.frame.size.height-216, self.tableView.frame.size.width, 216);
    [view addSubview:obj];
    
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(saveDropdown)];
    [barItems addObject:doneBtn];
  }
  
  [pickerDateToolbar setItems:barItems animated:YES];
  pickerDateToolbar.tag = 4;
  
  [view addSubview:pickerDateToolbar];
  
  [self.view addSubview:view];
  [UIView beginAnimations:nil context:nil];
  [self.view bringSubviewToFront:view];
  [UIView commitAnimations];
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
  CGSize labelsize=[[groupTitles objectAtIndex:section] sizeForFont:FormHeaderFont
                                                          limitSize:CGSizeMake(300, 2000.0)
                                                    nslineBreakMode:NSLineBreakByWordWrapping];
  
  NSString *text = [groupTitles objectAtIndex:section];
  
  if (![text isEqualToString:@""])
    return (CGFloat)labelsize.height + 40;
  else
    return 20;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
  return 1;
}


  // coloring table sections headers
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
  UIView *hView = [[UIView alloc] initWithFrame:CGRectZero];
  hView.backgroundColor=[UIColor clearColor];
  
  CGFloat hLabelHeight = [self tableView:self.tableView heightForHeaderInSection:section];
  UILabel *hLabel=[[UILabel alloc] initWithFrame:CGRectMake(10.0f, 0.0f, 301.0f, hLabelHeight)]; //magic numbers detected!!!
  
  hLabel.backgroundColor=[UIColor clearColor];

  hLabel.textColor = self.color5spec;
  hLabel.font = [UIFont systemFontOfSize:19.0f];
  hLabel.text = [groupTitles objectAtIndex:section];
  hLabel.numberOfLines = 0;
  
  if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")){
    hLabel.lineBreakMode = NSLineBreakByWordWrapping;
  } else {
    hLabel.lineBreakMode = NSLineBreakByWordWrapping;
  }
  
  [hView addSubview:hLabel];
  
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 1)];
  view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.2f];
  [hView addSubview:view];
  
  return hView;
}

#pragma mark - TextView & TextField delegate
- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
  return YES;
}

- (UIToolbar *)createInputAccessoryView
{
  UIToolbar *toolbar = [[UIToolbar alloc] init];
  [toolbar setBarStyle:UIBarStyleBlackTranslucent];
  [toolbar sizeToFit];
  UIBarButtonItem *flexButton   = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
  UIBarButtonItem *doneButton   = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(textFieldFinished)];
  [toolbar setItems:[NSArray arrayWithObjects:flexButton, doneButton, nil]];
  return toolbar;
}

- (BOOL) textViewShouldBeginEditing:(UITextView*)textView
{
  Field = textView;
  [textView setInputAccessoryView:[self createInputAccessoryView]];
  return YES;
}

-(BOOL) textFieldShouldBeginEditing:(UITextField*)textField
{
  Field = (UITextView *)textField;
  textField.returnKeyType = UIReturnKeyDone;
  return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
  [self.tableView adjustOffsetToIdealIfNeeded];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
  [self.tableView adjustOffsetToIdealIfNeeded];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

- (BOOL)textViewShouldReturn:(UITextView *)textView
{
	[textView resignFirstResponder];
	return YES;
}

- (void)textFieldFinished
{
  [Field resignFirstResponder];
}


#pragma mark - PickerView delegate
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView
{
  return 1;
}

- (NSInteger)pickerView:(UIPickerView *)thePickerView numberOfRowsInComponent:(NSInteger)component
{
  int i=0;
  for(UIPickerView *pickerView in ddArray)
  {
    if (thePickerView==pickerView)
      return [[ddValues objectAtIndex:i] count];
    i++;
  }
  return 0;
}

- (NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
  int i=0;
  for(UIPickerView *pickerView in ddArray)
  {
    if (thePickerView==pickerView)
      return [[ddValues objectAtIndex:i] objectAtIndex:row];
    
    i++;
  }
  return 0;
}

#pragma mark - Other methods
- (void)saveDatePicker
{
  UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.elementIndex];
  UIDatePicker *picker = [[[groups objectAtIndex:self.elementIndex.section] objectAtIndex:self.elementIndex.row] objectForKey:@"object"];
  UILabel *lbl = (UILabel *)[cell viewWithTag:1];
  
  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat: NSBundleLocalizedString(@"mCF_date_format", @"xx/yy/zz")];
  
  NSString *stringFromDate = [formatter stringFromDate:picker.date];
  
  lbl.text = stringFromDate;
  [[[groups objectAtIndex:self.elementIndex.section] objectAtIndex:self.elementIndex.row] setObject:stringFromDate forKey:@"value"];
  self.elementIndex = nil;
  [self removeChildViews];
  
}

- (void)saveDropdown;
{
  UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.elementIndex];
  UIPickerView *picker = [[[groups objectAtIndex:self.elementIndex.section] objectAtIndex:self.elementIndex.row] objectForKey:@"object"];
  UILabel *lbl = (UILabel *)[cell viewWithTag:1];
  
  int i=0;
  for(UIPickerView *pickerView in ddArray)
  {
    if (picker==pickerView)
    {
      NSString *value = [[ddValues objectAtIndex:i] objectAtIndex:[picker selectedRowInComponent:0]];
      NSUInteger chars = [value length];
      lbl.text = chars > 22 ? [NSString stringWithFormat:@"%@...", [value substringToIndex:22]] : value;
      [[[groups objectAtIndex:self.elementIndex.section] objectAtIndex:self.elementIndex.row] setObject:value forKey:@"value"];
      break;
    }
    i++;
  }
  self.elementIndex = nil;
  [self removeChildViews];
}

- (void)removeChildViews
{
  [self.view sendSubviewToBack:[self.view viewWithTag:2]];
  [[[self.view viewWithTag:2] viewWithTag:3] removeFromSuperview];
  [[[self.view viewWithTag:2] viewWithTag:4] removeFromSuperview];
  [[self.view viewWithTag:2] removeFromSuperview];
}

- (void)sendEmail
{
  if (Field)
    [Field resignFirstResponder];
  
  NSMutableString *text = [[NSMutableString alloc] initWithCapacity:0];
  NSString *elem;
  
  [text appendString:@"<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"><style type=\"text/css\">BODY {font-family: Arial, sans-serif;font-size:12px;}</style></head><body>"];
  int i=0;
  
  for(NSString *title in groupTitles)
  {
    [text appendString:[NSString stringWithFormat:@"<style>a { text-decoration: none; color:#3399FF;}</style><span style='font-family:Helvetica; font-size:16px; font-weight:bold;'><p align=\"center\">%@</p></span>",title]];
    
    NSArray *singleGroup = [groups objectAtIndex:i];
    
    for(NSDictionary *groupElements in singleGroup)
    {
      NSString *label = [groupElements objectForKey:@"label"];
      if (!label)
        label = @"";
      
      elem = @"";
      
      if ([[groupElements objectForKey:@"object"] isKindOfClass:[UITextView class]])
      {
        UITextView *textView = [groupElements objectForKey:@"object"];
        elem = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
      }
      else if ([[groupElements objectForKey:@"object"] isKindOfClass:[UITextField class]])
      {
        UITextField *textView = [groupElements objectForKey:@"object"];
        elem = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
      }
      else if ([[groupElements objectForKey:@"object"] isKindOfClass:[UIPickerView class]])
      {
          // if the picker view value is not specified, then set an empty string
        id obj = [groupElements objectForKey:@"value"];
        
        if ( !obj )
          elem = @"";
        else if ( [obj isKindOfClass:[NSArray class]])
          elem = [obj count] ? [obj objectAtIndex:0] : @"";
        else
          elem = [groupElements objectForKey:@"value"];
        
      }
      else if ( [[groupElements objectForKey:@"object"] isKindOfClass:[UIDatePicker class]] )
      {
        elem = [groupElements objectForKey:@"value"];
        
          // set current date if date is not specified
        if ( !elem )
        { /// try to get value for key "date"
          elem = [groupElements objectForKey:@"date"];
          
          if ( !elem )
          { // form date and time with current timeZone, if it is not assigned anywhere
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat: NSBundleLocalizedString(@"mCF_date_format", @"xx/yy/zz")];
            
            NSDate      *sourceDate              = [NSDate date];
            NSTimeZone  *sourceTimeZone          = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
            NSTimeZone  *destinationTimeZone     = [NSTimeZone systemTimeZone];
            NSInteger    sourceGMTOffset         = [sourceTimeZone secondsFromGMTForDate:sourceDate];
            NSInteger       destinationGMTOffset = [destinationTimeZone secondsFromGMTForDate:sourceDate];
            NSTimeInterval  interval             = destinationGMTOffset - sourceGMTOffset;
            NSDate      *destinationDate         = [[NSDate alloc] initWithTimeInterval:interval
                                                                               sinceDate:sourceDate];
            elem = [dateFormatter stringFromDate:destinationDate ];
          }
        }
      }
      else if ([[groupElements objectForKey:@"object"] isKindOfClass:[mCFCheckBox class]])
      {
        mCFCheckBox *sw = [groupElements objectForKey:@"object"];
        elem = sw.checked ? NSBundleLocalizedString(@"mCF_switchOn", @"YES") : NSBundleLocalizedString(@"mCF_switchOff", @"NO");
      }
      else if ([[groupElements objectForKey:@"object"] isKindOfClass:[MIRadioButtonGroup class]])
      {
        MIRadioButtonGroup *rb = [groupElements objectForKey:@"object"];
        elem = rb.getSelected;
      }
      if (elem)
        [text appendString:[NSString stringWithFormat:@"%@ : %@ <br>",label,elem]];
    }
    
    i++;
    
    if ((i >= [groupTitles count] -1)  || (i >= [groups count] - 1))
      break;
    
  }
  
  [text appendString:@"</body></html>"];
  
  NSString *address = [[[elements objectAtIndex:0] objectForKey:@"email"] objectForKey:@"address"];
  NSString *subject = [[[elements objectAtIndex:0] objectForKey:@"email"] objectForKey:@"subject"];
  
  [functionLibrary  callMailComposerWithRecipients:[NSArray arrayWithObject:address]
                                        andSubject:subject
                                           andBody:text
                                            asHTML:YES
                                    withAttachment:nil
                                          mimeType:@""
                                          fileName:@""
                                    fromController:self
                                          showLink:_showLink];
}

#pragma mark - MFMailComposeViewControllerDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)composeResult
                        error:(NSError *)error
{
  [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Autorotate handlers
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (BOOL)shouldAutorotate
{
  return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
  return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
  return UIInterfaceOrientationPortrait;
}


@end
