//
//  EventTableViewCell.h
//  iAmuse
//
//  Created by apple on 24/10/16.
//  Copyright © 2016 iAmuse Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EventTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *lblEvent;
@property (weak, nonatomic) IBOutlet UIButton *downloadBtn;

@end
