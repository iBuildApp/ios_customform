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
#import <MessageUI/MessageUI.h>

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
                                  @"photopicker",
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
        
        if (labelText && ![type isEqualToString:@"radiobutton"]){
          if (labelText.length > 0) {
            [object setObject:labelText forKey:@"label"];
          }
        }
        
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
          
          if (labelText && labelText.length > 0)
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
          
          if (labelText && labelText.length > 0)
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
        else if([type isEqualToString:@"photopicker"]){
          UIButton *btnPhotoPicker = [UIButton buttonWithType:UIButtonTypeCustom];
          NSString *photoPickerTitle = NSBundleLocalizedString(@"mCF_addImageButton", @"Add image button title");
          btnPhotoPicker.titleLabel.font = [UIFont systemFontOfSize:18.0f];
          [btnPhotoPicker setTitle:photoPickerTitle forState:UIControlStateNormal];
          btnPhotoPicker.frame = CGRectMake(10, 0.0f, photoPickerTitle.length * 10 + 30, kTextFieldHeight - 6);
          btnPhotoPicker.layer.masksToBounds = YES;
          btnPhotoPicker.backgroundColor = self.color5spec;
          [btnPhotoPicker addTarget:self action:@selector(pickPhoto) forControlEvents:UIControlEventTouchUpInside];
          [btnPhotoPicker setContentHorizontalAlignment: UIControlContentHorizontalAlignmentCenter];
          [btnPhotoPicker setTitleColor:self.mCFColorOfBackground forState:UIControlStateNormal];
          btnPhotoPicker.hidden = NO;
          
          object = [[NSMutableDictionary alloc] init];
          
          [object setObject:btnPhotoPicker forKey:@"object"];
          [object setObject:@"btnPicker" forKey:@"type"];
          
          
          [groupElements addObject:object];
          
          CGRect frame = CGRectMake(10, 0, self.fieldWidth, 1);
          imgPanel = [[UIView alloc] initWithFrame:frame];
          [imgPanel setBackgroundColor:[UIColor clearColor]];
          
          object = [[NSMutableDictionary alloc] init];
          
          [object setObject:imgPanel forKey:@"object"];
          [object setObject:@"imgPanel" forKey:@"type"];
          
          
          [groupElements addObject:object];
        }
        else if ([type isEqualToString:@"radiobutton"])
        {
          if (!rbElements) rbElements = [[NSMutableArray alloc] init];
          
          rbCount++;
          
          if (labelText && labelText > 0)
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
        
        if ([object count]>0 && ![type isEqualToString:@"photopicker"])
          [groupElements addObject:object];
      }
    }
    [groups addObject:groupElements];
  }
  
  groupElements = [[NSMutableArray alloc] init];
  
  NSString *sendTitle = [[[elements objectAtIndex:0] objectForKey:@"email"] objectForKey:@"label"];
  

  UIButton *btnSend = [UIButton buttonWithType:UIButtonTypeCustom];
  btnSend.titleLabel.font = [UIFont systemFontOfSize:22.0f];
  btnSend.frame = CGRectMake(10, -5.0f, self.fieldWidth, kTextFieldHeight);
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
  [[self.tabBarController tabBar] setHidden:YES];
  
  self.tableView = [[TPKeyboardAvoidingTableView alloc] initWithFrame:self.view.bounds
                                                                 style:UITableViewStyleGrouped];
  self.tableView.autoresizesSubviews = YES;
  self.tableView.autoresizingMask    = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
  self.tableView.separatorColor = [UIColor clearColor];
if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
  if ([self.tableView respondsToSelector:@selector(setSeparatorInset:)])
    [self.tableView setSeparatorInset:UIEdgeInsetsZero];
  
  if ([self.tableView respondsToSelector:@selector(setLayoutMargins:)])
    [self.tableView setLayoutMargins:UIEdgeInsetsZero];
}
  self.tableView.contentMode = UIViewContentModeScaleToFill;
  self.tableView.autoresizesSubviews = YES;
  imgCount = 0;
    // on iOS7 grouped cells have drawn the entire width of the screen, so we change width of text fields:
  
  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    self.fieldWidth = 300;
  
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
    
    if (labelText && labelText.length > 0 &&![type isEqualToString:@"radiobutton"])
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
  else if ([object isKindOfClass:[UIButton class]])
  {
    return 50;
  }
  else if ([object isKindOfClass:[UIView class]])
  {
    selectedRow = indexPath;
    imgPanel.hidden = NO;
    return 5 + imgPanel.frame.size.height;
  }
  else
    return 20;
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
  
  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    pickerBackground.backgroundColor = [UIColor whiteColor];
  
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

- (void)pickPhoto
{
  [self.view endEditing:YES];
  if (imgCount > 7) {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:@"Reached the limit of photos"
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    return;
  }
  NSString *other1 = @"Take a picture";
  NSString *other2 = @"Choose from album";
  NSString *cancelTitle = @"Cancel";
  UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                initWithTitle:nil
                                delegate:self
                                cancelButtonTitle:cancelTitle
                                destructiveButtonTitle:nil
                                otherButtonTitles:other1, other2, nil];
  [actionSheet showInView:self.view];
}


- (IBAction)pickPhoto1 {
  UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:@"Select image from" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"From library",@"From camera", nil];
  
  [action showInView:self.view];
}

#pragma mark - ActionSheet delegates

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if( buttonIndex == 0 ) {
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
      UIImagePickerController *pickerView =[[UIImagePickerController alloc]init];
      pickerView.allowsEditing = NO;
      //pickerView.wantsFullScreenLayout = YES;
        pickerView.extendedLayoutIncludesOpaqueBars = YES;
        pickerView.edgesForExtendedLayout = YES;
      pickerView.delegate = self;
      pickerView.sourceType = UIImagePickerControllerSourceTypeCamera;

      [self presentViewController:pickerView animated:true completion:nil];
    }
    
  }else if( buttonIndex == 1 ) {
    
    UIImagePickerController *pickerView = [[UIImagePickerController alloc] init];
    pickerView.allowsEditing = NO;
      //pickerView.wantsFullScreenLayout = YES;
      pickerView.extendedLayoutIncludesOpaqueBars = YES;
      pickerView.edgesForExtendedLayout = YES;

    pickerView.delegate = self;
    [pickerView setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    [self presentViewController:pickerView animated:YES completion:nil];
    
  }
}

#pragma mark - PickerDelegates

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
  
  [self dismissViewControllerAnimated:true completion:nil];
  if (imgCount == 0) {
    
    imgCount+=1;
    
    UIImage * img = [info valueForKey:UIImagePickerControllerOriginalImage];
    img1 = img;
    [images addObject:img];
    resultingImageData = UIImageJPEGRepresentation(img, 0.9);
    CGRect frame = CGRectMake(0, 10, 60, 60); // Replacing with your dimensions
    imgView1 = [[UIImageView alloc] initWithFrame:frame];
    [imgView1 setImage:img];
    imgView1.layer.borderColor = [UIColor whiteColor].CGColor;
    imgView1.layer.borderWidth = 1;
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected)];
    singleTap.numberOfTapsRequired = 1;
    [imgView1 setUserInteractionEnabled:YES];
    [imgView1 addGestureRecognizer:singleTap];
    
    
    CGRect frameX = CGRectMake(47, 0, 24, 24); // Replacing with your dimensions
    imgView1X = [[UIImageView alloc] initWithFrame:frameX];
    [imgView1X setImage:[UIImage imageNamed:resourceFromBundle(@"mCF_delete.png")]];
                                                                                    
    UITapGestureRecognizer *singleTapX = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetectedX)];
    singleTapX.numberOfTapsRequired = 1;
    [imgView1X setUserInteractionEnabled:YES];
    [imgView1X addGestureRecognizer:singleTapX];
    
    imgView1.hidden = NO;
    imgView1X.hidden = NO;
    
    imgPanel.frame = CGRectMake(imgPanel.frame.origin.x, imgPanel.frame.origin.y, imgPanel.frame.size.width, imgPanel.frame.size.height + 80);
    [imgPanel addSubview:imgView1];
    [imgPanel addSubview:imgView1X];
    
    imgPanel.hidden = NO;
    [self.tableView reloadData];
  } else if(imgCount == 1){
    
    imgCount +=1;
    UIImage * img = [info valueForKey:UIImagePickerControllerOriginalImage];
    img2 = img;
    [images addObject:img];
    resultingImageData = UIImageJPEGRepresentation(img2, 0.9);
    CGRect frame2 = CGRectMake(78, 10, 60, 60); // Replacing with your dimensions
    imgView2 = [[UIImageView alloc] initWithFrame:frame2];
    [imgView2 setImage:img2];
    imgView2.layer.borderColor = [UIColor whiteColor].CGColor;
    imgView2.layer.borderWidth = 1;
    
    UITapGestureRecognizer *singleTap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected2)];
    singleTap2.numberOfTapsRequired = 1;
    [imgView2 setUserInteractionEnabled:YES];
    [imgView2 addGestureRecognizer:singleTap2];
    
    
    CGRect frameX2 = CGRectMake(125, 0, 24, 24); // Replacing with your dimensions
    imgView2X = [[UIImageView alloc] initWithFrame:frameX2];
    [imgView2X setImage:[UIImage imageNamed:resourceFromBundle(@"mCF_delete.png")]];
    UITapGestureRecognizer *singleTapX2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetectedX2)];
    singleTapX2.numberOfTapsRequired = 1;
    [imgView2X setUserInteractionEnabled:YES];
    [imgView2X addGestureRecognizer:singleTapX2];
    
    imgView2.hidden = NO;
    imgView2X.hidden = NO;
    
    [imgPanel addSubview:imgView2];
    [imgPanel addSubview:imgView2X];
    
    
  } else if(imgCount == 2){
    
    imgCount +=1;
    UIImage * img = [info valueForKey:UIImagePickerControllerOriginalImage];
    img3 = img;
    [images addObject:img];
    resultingImageData = UIImageJPEGRepresentation(img3, 0.9);
    CGRect frame3 = CGRectMake(158, 10, 60, 60); // Replacing with your dimensions
    imgView3 = [[UIImageView alloc] initWithFrame:frame3];
    [imgView3 setImage:img3];
    imgView3.layer.borderColor = [UIColor whiteColor].CGColor;
    imgView3.layer.borderWidth = 1;
    
    UITapGestureRecognizer *singleTap3 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected3)];
    singleTap3.numberOfTapsRequired = 1;
    [imgView3 setUserInteractionEnabled:YES];
    [imgView3 addGestureRecognizer:singleTap3];
    
    
    CGRect frameX3 = CGRectMake(205, 0, 24, 24); // Replacing with your dimensions
    imgView3X = [[UIImageView alloc] initWithFrame:frameX3];
    [imgView3X setImage:[UIImage imageNamed:resourceFromBundle(@"mCF_delete.png")]];
    UITapGestureRecognizer *singleTapX3 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetectedX3)];
    singleTapX3.numberOfTapsRequired = 1;
    [imgView3X setUserInteractionEnabled:YES];
    [imgView3X addGestureRecognizer:singleTapX3];
    
    imgView3.hidden = NO;
    imgView3X.hidden = NO;
    
    [imgPanel addSubview:imgView3];
    [imgPanel addSubview:imgView3X];
  } else if(imgCount == 3){
    
    imgCount +=1;
    UIImage * img = [info valueForKey:UIImagePickerControllerOriginalImage];
    img4 = img;
    [images addObject:img];
    resultingImageData = UIImageJPEGRepresentation(img4, 0.9);
    CGRect frame4 = CGRectMake(238, 10, 60, 60); // Replacing with your dimensions
    imgView4 = [[UIImageView alloc] initWithFrame:frame4];
    [imgView4 setImage:img4];
    imgView4.layer.borderColor = [UIColor whiteColor].CGColor;
    imgView4.layer.borderWidth = 1;
    
    UITapGestureRecognizer *singleTap4 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected4)];
    singleTap4.numberOfTapsRequired = 1;
    [imgView4 setUserInteractionEnabled:YES];
    [imgView4 addGestureRecognizer:singleTap4];
    
    
    CGRect frameX4 = CGRectMake(285, 0, 24, 24); // Replacing with your dimensions
    imgView4X = [[UIImageView alloc] initWithFrame:frameX4];
    [imgView4X setImage:[UIImage imageNamed:resourceFromBundle(@"mCF_delete.png")]];
    UITapGestureRecognizer *singleTapX4 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetectedX4)];
    singleTapX4.numberOfTapsRequired = 1;
    [imgView4X setUserInteractionEnabled:YES];
    [imgView4X addGestureRecognizer:singleTapX4];
    
    imgView4.hidden = NO;
    imgView4X.hidden = NO;
    
    [imgPanel addSubview:imgView4];
    [imgPanel addSubview:imgView4X];
  } else if (imgCount == 4) {
    
    imgCount+=1;
    
    UIImage * img = [info valueForKey:UIImagePickerControllerOriginalImage];
    img5 = img;
    [images addObject:img];
    resultingImageData = UIImageJPEGRepresentation(img5, 0.9);
    CGRect frame5 = CGRectMake(0, 95, 60, 60); // Replacing with your dimensions
    imgView5 = [[UIImageView alloc] initWithFrame:frame5];
    [imgView5 setImage:img];
    imgView5.layer.borderColor = [UIColor whiteColor].CGColor;
    imgView5.layer.borderWidth = 1;
    
    UITapGestureRecognizer *singleTap5 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected5)];
    singleTap5.numberOfTapsRequired = 1;
    [imgView5 setUserInteractionEnabled:YES];
    [imgView5 addGestureRecognizer:singleTap5];
    
    
    CGRect frameX5 = CGRectMake(47, 85, 24, 24); // Replacing with your dimensions
    imgView5X = [[UIImageView alloc] initWithFrame:frameX5];
    [imgView5X setImage:[UIImage imageNamed:resourceFromBundle(@"mCF_delete.png")]];
    UITapGestureRecognizer *singleTapX5 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetectedX5)];
    singleTapX5.numberOfTapsRequired = 1;
    [imgView5X setUserInteractionEnabled:YES];
    [imgView5X addGestureRecognizer:singleTapX5];
    
    imgView5.hidden = NO;
    imgView5X.hidden = NO;
    
    imgPanel.frame = CGRectMake(imgPanel.frame.origin.x, imgPanel.frame.origin.y, imgPanel.frame.size.width, imgPanel.frame.size.height + 80);
    imgPanel.hidden = NO;
    [imgPanel addSubview:imgView5];
    [imgPanel addSubview:imgView5X];
    
    [self.tableView reloadData];
  } else if(imgCount == 5){
    
    imgCount +=1;
    UIImage * img = [info valueForKey:UIImagePickerControllerOriginalImage];
    img6 = img;
    [images addObject:img];
    resultingImageData = UIImageJPEGRepresentation(img6, 0.9);
    CGRect frame6 = CGRectMake(78, 95, 60, 60); // Replacing with your dimensions
    imgView6 = [[UIImageView alloc] initWithFrame:frame6];
    [imgView6 setImage:img6];
    imgView6.layer.borderColor = [UIColor whiteColor].CGColor;
    imgView6.layer.borderWidth = 1;
    
    UITapGestureRecognizer *singleTap6 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected6)];
    singleTap6.numberOfTapsRequired = 1;
    [imgView6 setUserInteractionEnabled:YES];
    [imgView6 addGestureRecognizer:singleTap6];
    
    
    CGRect frameX6 = CGRectMake(125, 85, 24, 24); // Replacing with your dimensions
    imgView6X = [[UIImageView alloc] initWithFrame:frameX6];
    [imgView6X setImage:[UIImage imageNamed:resourceFromBundle(@"mCF_delete.png")]];
    UITapGestureRecognizer *singleTapX6 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetectedX6)];
    singleTapX6.numberOfTapsRequired = 1;
    [imgView6X setUserInteractionEnabled:YES];
    [imgView6X addGestureRecognizer:singleTapX6];
    
    imgView6.hidden = NO;
    imgView6X.hidden = NO;
    
    [imgPanel addSubview:imgView6];
    [imgPanel addSubview:imgView6X];
    
    
  } else if(imgCount == 6){
    
    imgCount +=1;
    UIImage * img = [info valueForKey:UIImagePickerControllerOriginalImage];
    img7 = img;
    [images addObject:img];
    resultingImageData = UIImageJPEGRepresentation(img7, 0.9);
    CGRect frame7 = CGRectMake(158, 95, 60, 60); // Replacing with your dimensions
    imgView7 = [[UIImageView alloc] initWithFrame:frame7];
    [imgView7 setImage:img7];
    imgView7.layer.borderColor = [UIColor whiteColor].CGColor;
    imgView7.layer.borderWidth = 1;
    
    UITapGestureRecognizer *singleTap7 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected7)];
    singleTap7.numberOfTapsRequired = 1;
    [imgView7 setUserInteractionEnabled:YES];
    [imgView7 addGestureRecognizer:singleTap7];
    
    
    CGRect frameX7 = CGRectMake(205, 85, 24, 24); // Replacing with your dimensions
    imgView7X = [[UIImageView alloc] initWithFrame:frameX7];
    [imgView7X setImage:[UIImage imageNamed:resourceFromBundle(@"mCF_delete.png")]];
    UITapGestureRecognizer *singleTapX7 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetectedX7)];
    singleTapX7.numberOfTapsRequired = 1;
    [imgView7X setUserInteractionEnabled:YES];
    [imgView7X addGestureRecognizer:singleTapX7];
    
    imgView7.hidden = NO;
    imgView7X.hidden = NO;
    
    [imgPanel addSubview:imgView7];
    [imgPanel addSubview:imgView7X];
  } else if(imgCount == 7){
    
    imgCount +=1;
    UIImage * img = [info valueForKey:UIImagePickerControllerOriginalImage];
    img8 = img;
    [images addObject:img];
    resultingImageData = UIImageJPEGRepresentation(img8, 0.9);
    CGRect frame8 = CGRectMake(238, 95, 60, 60); // Replacing with your dimensions
    imgView8 = [[UIImageView alloc] initWithFrame:frame8];
    [imgView8 setImage:img8];
    imgView8.layer.borderColor = [UIColor whiteColor].CGColor;
    imgView8.layer.borderWidth = 1;
    
    UITapGestureRecognizer *singleTap8 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetected8)];
    singleTap8.numberOfTapsRequired = 1;
    [imgView8 setUserInteractionEnabled:YES];
    [imgView8 addGestureRecognizer:singleTap8];
    
    
    CGRect frameX8 = CGRectMake(285, 85, 24, 24); // Replacing with your dimensions
    imgView8X = [[UIImageView alloc] initWithFrame:frameX8];
    [imgView8X setImage:[UIImage imageNamed:resourceFromBundle(@"mCF_delete.png")]];
    UITapGestureRecognizer *singleTapX8 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapDetectedX8)];
    singleTapX8.numberOfTapsRequired = 1;
    [imgView8X setUserInteractionEnabled:YES];
    [imgView8X addGestureRecognizer:singleTapX8];
    
    imgView4.hidden = NO;
    imgView4X.hidden = NO;
    
    [imgPanel addSubview:imgView8];
    [imgPanel addSubview:imgView8X];
  }
  imgPanel.hidden = NO;
}

-(void)tapDetected{
  [self pickPhoto2];
}

-(void)tapDetectedX{
  if (imgView2.image && imgView2.hidden == NO) {
    [imgView1 setImage:imgView2.image];
  } else {
    imgView1.hidden = YES;
    imgView1X.hidden = YES;
    img1 = nil;
  }
  
  if (imgView3.image && imgView3.hidden == NO) {
    [imgView2 setImage:imgView3.image];
  } else {
    imgView2.hidden = YES;
    imgView2X.hidden = YES;
  }
  
  if (imgView4.image && imgView4.hidden == NO) {
    [imgView3 setImage:imgView4.image];
  } else {
    imgView3.hidden = YES;
    imgView3X.hidden = YES;
  }
  
  if (imgView5.image && imgView5.hidden == NO) {
    [imgView4 setImage:imgView5.image];
  } else {
    imgView4.hidden = YES;
    imgView4X.hidden = YES;
  }
  
  if (imgView6.image && imgView6.hidden == NO) {
    [imgView5 setImage:imgView6.image];
  } else {
    imgView5.hidden = YES;
    imgView5X.hidden = YES;
    imgPanel.frame = CGRectMake(imgPanel.frame.origin.x, imgPanel.frame.origin.y, imgPanel.frame.size.width, 80);
    [self.tableView reloadData];
  }
  
  if (imgView7.image && imgView7.hidden == NO) {
    [imgView6 setImage:imgView7.image];
  } else {
    imgView6.hidden = YES;
    imgView6X.hidden = YES;
  }
  
  if (imgView8.image && imgView8.hidden == NO) {
    [imgView7 setImage:imgView8.image];
    imgView8.hidden = YES;
    imgView8X.hidden = YES;
  } else {
    imgView7.hidden = YES;
    imgView7X.hidden = YES;
  }
  
  imgCount -=1;

  if (imgCount == 0) {
    imgPanel.frame = CGRectMake(imgPanel.frame.origin.x, imgPanel.frame.origin.y, imgPanel.frame.size.width, 0);
  }
}

-(void)img2mv{
  [imgView2 setImage:imgView3.image];
  [imgView2 setFrame:imgView3.frame];
  imgView2.hidden = NO;
  imgView3.hidden = YES;
}

-(void)tapDetected2{
  [self pickPhoto22];
}

-(void)tapDetectedX2{
  imgCount-=1;
  
    //second
  if (imgView3.image && imgView3.hidden == NO) {
    [imgView2 setImage:imgView3.image];
  } else {
    imgView2.hidden = YES;
    imgView2X.hidden = YES;
  }
  
  if (imgView4.image && imgView4.hidden == NO) {
    [imgView3 setImage:imgView4.image];
  } else {
    imgView3.hidden = YES;
    imgView3X.hidden = YES;
  }
  
  if (imgView5.image && imgView5.hidden == NO) {
    [imgView4 setImage:imgView5.image];
  } else {
    imgView4.hidden = YES;
    imgView4X.hidden = YES;
  }
  
  if (imgView6.image && imgView6.hidden == NO) {
    [imgView5 setImage:imgView6.image];
  } else {
    imgView5.hidden = YES;
    imgView5X.hidden = YES;
    imgPanel.frame = CGRectMake(imgPanel.frame.origin.x, imgPanel.frame.origin.y, imgPanel.frame.size.width, 80);
    [self.tableView reloadData];
  }
  
  if (imgView7.image && imgView7.hidden == NO) {
    [imgView6 setImage:imgView7.image];
  } else {
    imgView6.hidden = YES;
    imgView6X.hidden = YES;
  }
  
  if (imgView8.image && imgView8.hidden == NO) {
    [imgView7 setImage:imgView8.image];
    imgView8.hidden = YES;
    imgView8X.hidden = YES;
  } else {
    imgView7.hidden = YES;
    imgView7X.hidden = YES;
  }
}

-(void)tapDetected3{
  [self pickPhoto23];
}

-(void)tapDetectedX3{
  if (imgView4.image && imgView4.hidden == NO) {
    [imgView3 setImage:imgView4.image];
  } else {
    imgView3.hidden = YES;
    imgView3X.hidden = YES;
  }
  
  if (imgView5.image && imgView5.hidden == NO) {
    [imgView4 setImage:imgView5.image];
  } else {
    imgView4.hidden = YES;
    imgView4X.hidden = YES;
  }
  
  if (imgView6.image && imgView6.hidden == NO) {
    [imgView5 setImage:imgView6.image];
  } else {
    imgView5.hidden = YES;
    imgView5X.hidden = YES;
    imgPanel.frame = CGRectMake(imgPanel.frame.origin.x, imgPanel.frame.origin.y, imgPanel.frame.size.width, 80);
    [self.tableView reloadData];
  }
  
  if (imgView7.image && imgView7.hidden == NO) {
    [imgView6 setImage:imgView7.image];
  } else {
    imgView6.hidden = YES;
    imgView6X.hidden = YES;
  }
  
  if (imgView8.image && imgView8.hidden == NO) {
    [imgView7 setImage:imgView8.image];
    imgView8.hidden = YES;
    imgView8X.hidden = YES;
  } else {
    imgView7.hidden = YES;
    imgView7X.hidden = YES;
  }
  
  imgCount-=1;
}

-(void)tapDetected4{
  [self pickPhoto24];
}

-(void)tapDetectedX4{
  if (imgView5.image && imgView5.hidden == NO) {
    [imgView4 setImage:imgView5.image];
  } else {
    imgView4.hidden = YES;
    imgView4X.hidden = YES;
  }
  
  if (imgView6.image && imgView6.hidden == NO) {
    [imgView5 setImage:imgView6.image];
  } else {
    imgView5.hidden = YES;
    imgView5X.hidden = YES;
    imgPanel.frame = CGRectMake(imgPanel.frame.origin.x, imgPanel.frame.origin.y, imgPanel.frame.size.width, 80);
    [self.tableView reloadData];
  }
  
  if (imgView7.image && imgView7.hidden == NO) {
    [imgView6 setImage:imgView7.image];
  } else {
    imgView6.hidden = YES;
    imgView6X.hidden = YES;
  }
  
  if (imgView8.image && imgView8.hidden == NO) {
    [imgView7 setImage:imgView8.image];
    imgView8.hidden = YES;
    imgView8X.hidden = YES;
  } else {
    imgView7.hidden = YES;
    imgView7X.hidden = YES;
  }
  
  imgCount-=1;
}

-(void)tapDetected5{
  [self pickPhoto25];
}

-(void)tapDetected6{
  [self pickPhoto26];
}

-(void)tapDetected7{
  [self pickPhoto27];
}

-(void)tapDetected8{
  [self pickPhoto28];
}

-(void)tapDetectedX5{
  if (imgView6.image && imgView6.hidden == NO) {
    [imgView5 setImage:imgView6.image];
  } else {
    imgView5.hidden = YES;
    imgView5X.hidden = YES;
    imgPanel.frame = CGRectMake(imgPanel.frame.origin.x, imgPanel.frame.origin.y, imgPanel.frame.size.width, 80);
    [self.tableView reloadData];
  }
  
  if (imgView7.image && imgView7.hidden == NO) {
    [imgView6 setImage:imgView7.image];
  } else {
    imgView6.hidden = YES;
    imgView6X.hidden = YES;
  }
  
  if (imgView8.image && imgView8.hidden == NO) {
    [imgView7 setImage:imgView8.image];
    imgView8.hidden = YES;
    imgView8X.hidden = YES;
  } else {
    imgView7.hidden = YES;
    imgView7X.hidden = YES;
  }
  
  imgCount-=1;
}

-(void)tapDetectedX6{
  if (imgView7.image && imgView7.hidden == NO) {
    [imgView6 setImage:imgView7.image];
  } else {
    imgView6.hidden = YES;
    imgView6X.hidden = YES;
  }
  
  if (imgView8.image && imgView8.hidden == NO) {
    [imgView7 setImage:imgView8.image];
    imgView8.hidden = YES;
    imgView8X.hidden = YES;
  } else {
    imgView7.hidden = YES;
    imgView7X.hidden = YES;
  }
  
  imgCount-=1;
}

-(void)tapDetectedX7{
  if (imgView8.image && imgView8.hidden == NO) {
    [imgView7 setImage:imgView8.image];
    imgView8.hidden = YES;
    imgView8X.hidden = YES;
  } else {
    imgView7.hidden = YES;
    imgView7X.hidden = YES;
  }
  
  imgCount-=1;
}

-(void)tapDetectedX8{
    imgView8.hidden = YES;
    imgView8X.hidden = YES;
  imgCount-=1;
}

- (void)pickPhoto2
{
  UIViewController *controller = [[UIViewController alloc] init];
  UIImage *img = imgView1.image;
  UIImageView *view = [[UIImageView alloc] initWithImage:img];
  view.contentMode = UIViewContentModeScaleAspectFit;
  view.clipsToBounds = YES;
  [view setBackgroundColor:[UIColor blackColor]];
  controller.view = view;
  
  [self.navigationController pushViewController:controller animated:YES];
}

- (void)pickPhoto22
{
  UIViewController *controller = [[UIViewController alloc] init];
  UIImage *img = imgView2.image;
  UIImageView *view = [[UIImageView alloc] initWithImage:img];
  view.contentMode = UIViewContentModeScaleAspectFit;
  view.clipsToBounds = YES;
  [view setBackgroundColor:[UIColor blackColor]];
  controller.view = view;
  
  [self.navigationController pushViewController:controller animated:YES];
}

- (void)pickPhoto23
{
  UIViewController *controller = [[UIViewController alloc] init];
  UIImage *img = imgView3.image;
  UIImageView *view = [[UIImageView alloc] initWithImage:img];
  view.contentMode = UIViewContentModeScaleAspectFit;
  view.clipsToBounds = YES;
  [view setBackgroundColor:[UIColor blackColor]];
  controller.view = view;
  
  [self.navigationController pushViewController:controller animated:YES];
}

- (void)pickPhoto24
{
  UIViewController *controller = [[UIViewController alloc] init];
  UIImage *img = imgView4.image;
  UIImageView *view = [[UIImageView alloc] initWithImage:img];
  view.contentMode = UIViewContentModeScaleAspectFit;
  view.clipsToBounds = YES;
  [view setBackgroundColor:[UIColor blackColor]];
  controller.view = view;
  
  [self.navigationController pushViewController:controller animated:YES];
}

- (void)pickPhoto25
{
  UIViewController *controller = [[UIViewController alloc] init];
  UIImage *img = imgView5.image;
  UIImageView *view = [[UIImageView alloc] initWithImage:img];
  view.contentMode = UIViewContentModeScaleAspectFit;
  view.clipsToBounds = YES;
  [view setBackgroundColor:[UIColor blackColor]];
  controller.view = view;
  
  [self.navigationController pushViewController:controller animated:YES];
}

- (void)pickPhoto26
{
  UIViewController *controller = [[UIViewController alloc] init];
  UIImage *img = imgView6.image;
  UIImageView *view = [[UIImageView alloc] initWithImage:img];
  view.contentMode = UIViewContentModeScaleAspectFit;
  view.clipsToBounds = YES;
  [view setBackgroundColor:[UIColor blackColor]];
  controller.view = view;
  
  [self.navigationController pushViewController:controller animated:YES];
}

- (void)pickPhoto27
{
  UIViewController *controller = [[UIViewController alloc] init];
  UIImage *img = imgView7.image;
  UIImageView *view = [[UIImageView alloc] initWithImage:img];
  view.contentMode = UIViewContentModeScaleAspectFit;
  view.clipsToBounds = YES;
  [view setBackgroundColor:[UIColor blackColor]];
  controller.view = view;
  
  [self.navigationController pushViewController:controller animated:YES];
}

- (void)pickPhoto28
{
  UIViewController *controller = [[UIViewController alloc] init];
  UIImage *img = imgView8.image;
  UIImageView *view = [[UIImageView alloc] initWithImage:img];
  view.contentMode = UIViewContentModeScaleAspectFit;
  view.clipsToBounds = YES;
  [view setBackgroundColor:[UIColor blackColor]];
  controller.view = view;
  
  [self.navigationController pushViewController:controller animated:YES];
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


  
  UIImage *simg1 = imgView1.hidden?nil:imgView1.image;
   UIImage *simg2 = imgView2.hidden?nil:imgView2.image;
    UIImage *simg3 = imgView3.hidden?nil:imgView3.image;
    UIImage *simg4 = imgView4.hidden?nil:imgView4.image;
    UIImage *simg5 = imgView5.hidden?nil:imgView5.image;
    UIImage *simg6 = imgView6.hidden?nil:imgView6.image;
    UIImage *simg7 = imgView7.hidden?nil:imgView7.image;
    UIImage *simg8 = imgView8.hidden?nil:imgView8.image;
  
  
  jpgArray = [[NSArray alloc] init];
  jpgArray = [NSArray arrayWithObjects:UIImageJPEGRepresentation(simg1, 0.9), UIImageJPEGRepresentation(simg2, 0.9),UIImageJPEGRepresentation(simg3, 0.9), UIImageJPEGRepresentation(simg4, 0.9), UIImageJPEGRepresentation(simg5, 0.9), UIImageJPEGRepresentation(simg6, 0.9), UIImageJPEGRepresentation(simg7, 0.9), UIImageJPEGRepresentation(simg8, 0.9), nil];

    [functionLibrary  callMailComposerWithRecipientsMultipleAttach:[NSArray arrayWithObject:address]
                                                        andSubject:subject
                                                           andBody:text
                                                            asHTML:YES
                                                    withAttachment:jpgArray
                                                          mimeType:@"image/jpeg"
                                                          fileName:@"test.jpg"
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

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
  return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
  return UIInterfaceOrientationPortrait;
}


@end
