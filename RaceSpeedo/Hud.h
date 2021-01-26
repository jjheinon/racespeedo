//  @author Janne Heinonen <jjh@iki.fi>
//  @brief RaceSpeedo - 24 May 2017
//  @license MIT

#import <SpriteKit/SpriteKit.h>

@class SKLabelNode;

@interface Hud : SKScene

- (id)initWithSize:(CGSize)size;

-(void)updateLabel:(NSString*)text;
-(void)updateLabel2:(NSString*)text;
-(void)updateLabel3:(NSString*)text;

@property SKLabelNode* hudInfoLabel;
@property SKLabelNode* hudInfoLabel2;
@property SKLabelNode* hudInfoLabel3;

@end
