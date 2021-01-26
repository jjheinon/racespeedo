//
//  GameViewController.h
//  RaceSpeedo
//
//  @author Janne Heinonen <jjh@iki.fi>
//  @brief RaceSpeedo - 24 May 2017
//  @license MIT

#import <UIKit/UIKit.h>
#import <SceneKit/SceneKit.h>
#import <CoreMotion/CoreMotion.h>

@class Hud;
@import CoreLocation;

@interface GameViewController : UIViewController
<CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;

@property int speedoMode;

@property SCNScene* scene;

@property Hud* hud;

@property SCNText* speedDisplayNode;

@property int speed;
@property int prevSpeed;

@property int gyroSpeed;

@property (strong, nonatomic) CMMotionManager *motionManager;
@property NSOperationQueue* motionQueue;

@property bool isAccelerometerEnabled;

@property NSTimer* updateTimer;

@property SCNVector3 combinedAcceleration;
@property double oldGyroTimestamp;
@property double oldGPSTimestamp;

@property double startedAccelerationTimestamp; // for 0-100 km/h measurements
@property double endedAccelerationTimestamp; // for 0-100 km/h measurements

@property bool isMeasuring0to100;

@property double zeroTo100Time;

@property int oldAngle;

@property NSMutableArray* speedos;
@property int activeSpeedo;

@property SCNNode* cameraNode;

@end
