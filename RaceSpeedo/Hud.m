//  @author Janne Heinonen <jjh@iki.fi>
//  @brief RaceSpeedo - 24 May 2017
//  @license MIT

#import "Hud.h"

@implementation Hud

- (id)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size]) {
        
        self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1];
        
        self.hudInfoLabel = [Hud labelWithText:@"" andSize:55];
        [self addChild:self.hudInfoLabel];
        self.hudInfoLabel.position = CGPointMake(self.frame.size.width/2, self.frame.size.height-25 -80);

        self.hudInfoLabel2 = [Hud labelWithText:@"" andSize:35];
     //   [self addChild:self.hudInfoLabel2];
     //   self.hudInfoLabel2.position = CGPointMake(self.frame.size.width/2, self.frame.size.height-25 -120);

        self.hudInfoLabel3 = [Hud labelWithText:@"" andSize:35];
        [self addChild:self.hudInfoLabel3];
        self.hudInfoLabel3.position = CGPointMake(self.frame.size.width/2, self.frame.size.height-25 -120);
    }

    return self;
}

-(void)updateLabel:(NSString*)text
{
    self.hudInfoLabel.text = text;
}

-(void)updateLabel2:(NSString*)text
{
    self.hudInfoLabel2.text = text;
}

-(void)updateLabel3:(NSString*)text
{
    self.hudInfoLabel3.text = text;
}

+ (SKLabelNode *)labelWithText:(NSString *)text andSize:(CGFloat)textSize
{
    NSString *fontName = @"Optima"; //@"Copperplate-Light";
    SKLabelNode *myLabel = [SKLabelNode labelNodeWithFontNamed:fontName];
    
    myLabel.text = text;
    myLabel.fontSize = textSize;
    myLabel.fontColor = [SKColor yellowColor];
    
    return myLabel;
}

@end
