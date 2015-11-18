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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

/**
 *  Main module class for widget CustomForm. Module entry point.
 */
@interface mCustomFormViewController : UIViewController < UITextViewDelegate,
                                                          UITextFieldDelegate,
                                                          UIPickerViewDelegate,
                                                          UIPickerViewDataSource,
                                                          UITableViewDelegate,
                                                          UITableViewDataSource,
                                                          MFMailComposeViewControllerDelegate>
{
  NSMutableArray *elements;
  NSMutableArray *groups;
  NSMutableArray *groupTitles;
  int rbCount;
  int chRB;
  NSMutableArray *ddValues; //dropdown values
  NSMutableArray *ddArray;  //pickerviews array
  NSMutableArray *rbElements;//tmp array for RadioButton elements
  UITextView *Field;
}

/**
 *  Background color
 */
@property (nonatomic, retain) UIColor *mCFColorOfBackground;

/**
 *  Header text color
 */
@property (nonatomic, retain) UIColor *mCFColorOfHeader;

/**
 *  Text color
 */
@property (nonatomic, retain) UIColor *mCFColorOfText;

@end
