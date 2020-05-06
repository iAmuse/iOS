//
//  CTGetReadyViewController.h
//  Jurassic
//
//  Created by Roland Hordos on 2013-06-02.
//  Copyright (c) 2013 iAmuse Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AMTakingPicturesViewController.h"

@interface CTGetReadyViewController : UIViewController <TakingPicturesCompleteDelegate1> {
    NSString *_workflow;
}
@property (strong, nonatomic) AMTakingPicturesViewController *takePicturesVC;
@property (strong, nonatomic) IBOutlet UIImageView *header;
@property (strong, nonatomic) IBOutlet UIImageView *footer;
@property (strong, nonatomic) IBOutlet UIImageView *selectedLayoutView;
@property (weak, nonatomic) IBOutlet UIButton *takePicturesButton;
@property(nonatomic, assign) int indexValue;

@end

@protocol GetReadyCompleteDelegate <NSObject>
@required
- (void)getReadyViewController:(CTGetReadyViewController *)getReadyViewController
         didFinishWithWorkflow:(NSString *)workflow;
@end
