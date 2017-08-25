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
                                                          UIActionSheetDelegate,
                                                          UITableViewDelegate,
                                                          UITableViewDataSource,
                                                          MFMailComposeViewControllerDelegate,
                                                          UIImagePickerControllerDelegate,
                                                          UINavigationControllerDelegate>
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
  NSMutableArray *images;
  NSData *resultingImageData;
  UIView *imgPanel;
  UIImage *img1;
  UIImage *img2;
  UIImage *img3;
  UIImage *img4;
  UIImage *img5;
  UIImage *img6;
  UIImage *img7;
  UIImage *img8;
  UIImageView *imgView1;
  UIImageView *imgView2;
    UIImageView *imgView3;
    UIImageView *imgView4;
    UIImageView *imgView5;
    UIImageView *imgView6;
  UIImageView *imgView7;
  UIImageView *imgView8;
  UIImageView *imgView1X;
  UIImageView *imgView2X;
  UIImageView *imgView3X;
  UIImageView *imgView4X;
  UIImageView *imgView5X;
  UIImageView *imgView6X;
  UIImageView *imgView7X;
  UIImageView *imgView8X;
  
  NSIndexPath *selectedRow;
  NSArray *jpgArray;
  int imgCount;
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
