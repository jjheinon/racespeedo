//
//  GameViewController.m
//  RaceSpeedo
//
//  @author Janne Heinonen <jjh@iki.fi>
//  @brief RaceSpeedo - 24 May 2017
//  @license MIT

#import "GameViewController.h"
#import "Hud.h"

#import "Speedo.h"

@implementation GameViewController

const int NORMAL = 1;
const int ROTATED = 2;
const int FOLLOW_NEEDLE = 3;

const int SPEEDO_TYPE_OLDER_CAR = 1;
const int SPEEDO_TYPE_OTHER_CAR = 2;
const int SPEEDO_TYPE_GOLF_R = 3;

const int SPEEDO_PADDING = 150;

// How long (in seconds) to measure acceleration until cancel it as too slow:
#define MAX_ACCELERATION_TIME_UNTIL_CANCELLED 30.0

#define SPEED_MIN 0 // Do 0-N km/h measurement
#define SPEED_MAX 100 // Do 0-N km/h measurement

// How small movements to ignore (Gs) when detecting movement using sensors. Acceleration over this threshold will trigger 0-100 measurements, as well as increase the calculated speed when using movement sensors.
#define accelerationThreshold 0.20

// How many seconds to add to 0-100 acceleration time, when measuring the acceleration just using GPS.
// Sampling frequency with GPS is 1 Hz, so on the user started moving 0-1 seconds ago when we actually detect it.
// This is not used when using accelerometer to detect the actual starting time.
#define GPS_ACCELERATION_ADJUSTMENT 0.5

-(double)calculateNeedleAngle:(Speedo*)speedo
{
    if (speedo.speedoType == SPEEDO_TYPE_GOLF_R) {
        // Golf R spedometer:
        // 0 km/h = 0 deg
        // 100 = 128+0 deg
        // 120 = 128*1.2 deg
        // 200 = 128*1.2+52 deg
        // 320 = 128+130 deg
        if (self.speed <= 0) {
            return 0;
        }
        if (self.speed < 120) {
            return (128*1.2)*self.speed/120.0*M_PI/180;
        }
        if (self.speed <= 200) {
            return ((128*1.2)+(52*(self.speed-120)/80.0))*M_PI/180;
        }
        if (self.speed <= 350) {
            return ((128*1.2+52)+(52*(self.speed-200)/120.0))*M_PI/180;
        }
        if (self.speed > 350)
        {
            return ((128*1.2+52)+(52*(350-200)/120.0))*M_PI/180;
        }
    } else if (speedo.speedoType == SPEEDO_TYPE_OTHER_CAR) {
        if (self.speed <= 0) {
            return 0;
        }
        if (self.speed <= 240) {
            return (self.speed/220.0)*240.0*M_PI/180;
        }
        return 240.0/220*240*M_PI/180;
    } else if (speedo.speedoType == SPEEDO_TYPE_OLDER_CAR) {
        if (self.speed <= 0) {
            return 0;
        }
        int sp = self.speed;
        if (sp>140) {
            sp = 140;
        }
        return (sp/120.0)*239.0*M_PI/180;
        
    }
    return 0;
}

-(Speedo*)createSpeedo:(int)type
{
    Speedo* speedo = [Speedo alloc];
    
    SCNNode* parentNode = [SCNNode node]; // create parent node to allow nice view switching
    parentNode.name = @"speedoParent";
    parentNode.rotation = SCNVector4Make(0, 1, 0, 0);
    parentNode.position = SCNVector3Make(self.speedos.count*SPEEDO_PADDING, 0, 0);
    speedo.pNode = parentNode;

    [self.scene.rootNode addChildNode:parentNode];
    
    speedo.speedoType = type;
    
    UIImage *img1;
    UIImage *img;
    UIImage *img2;
    
    speedo.width = 110.0;
    speedo.height = 114.0;
    
    speedo.speedoScale = 1.0;
    if (type == SPEEDO_TYPE_GOLF_R) {
        img1 = [UIImage imageNamed:@"speedo3"];
        img = [UIImage imageNamed:@"needle3"];
        img2 = [UIImage imageNamed:@"needle3_black"];
        speedo.width = 110.0;
        speedo.height = 114.0;
    } else if (type == SPEEDO_TYPE_OTHER_CAR) {
        img1 = [UIImage imageNamed:@"speedo2"];
        img = [UIImage imageNamed:@"needle2"];
        img2 = [UIImage imageNamed:@"needle2_black"];
        speedo.width = 110.0;
        speedo.height = 106.0;
        speedo.speedoScale = 0.75;
    } else if (type == SPEEDO_TYPE_OLDER_CAR) {
        img1 = [UIImage imageNamed:@"speedo1"];
        img = [UIImage imageNamed:@"needle1"];
        img2 = [UIImage imageNamed:@"needle1_black"];
        speedo.width = 110.0;
        speedo.height = 110.0;
        speedo.speedoScale = 0.7;
    }
    // Speedo
    SCNNode* p1 = [SCNNode node];
    p1.name = @"square";
    p1.geometry = [SCNBox boxWithWidth:speedo.width height: 1.0 length: speedo.height chamferRadius:0.0];
    p1.rotation = SCNVector4Make(1, 0, 0, M_PI/2);
    p1.position = SCNVector3Make(0, 0, -75);
    p1.scale = SCNVector3Make(speedo.speedoScale, speedo.speedoScale, speedo.speedoScale);
    NSData *data1 = UIImagePNGRepresentation(img1);
    
    SCNMaterial *material1 = [SCNMaterial material];
    material1.diffuse.contents = data1;
    material1.locksAmbientWithDiffuse = YES;
    
    p1.geometry.firstMaterial = material1;
    speedo.speedo = p1;
    
    [speedo.pNode addChildNode:speedo.speedo];
    
    // Needle
    SCNNode *p = [SCNNode node];
    p.geometry = [SCNBox boxWithWidth:speedo.width height: 1.0 length: speedo.height chamferRadius:0.0];
    p.rotation = SCNVector4Make(1, 0, 0, M_PI/2);
    p.position = SCNVector3Make(0, 0, -74.0);
    p.scale = SCNVector3Make(speedo.speedoScale, speedo.speedoScale, speedo.speedoScale);
    
    NSData *data = UIImagePNGRepresentation(img);
    
    SCNMaterial *material = [SCNMaterial material];
    material.diffuse.contents = data;
    material.locksAmbientWithDiffuse = YES;
    
    p.geometry.firstMaterial = material;
    
    // Shadow
    SCNNode *p2 = [SCNNode node];
    p2.geometry = [SCNBox boxWithWidth:speedo.width height: 1.0 length: speedo.height chamferRadius:0.0];
    p2.rotation = SCNVector4Make(1, 0, 0, M_PI/2);
    p2.position = SCNVector3Make(0.0, 0.0, -74.5);
    p2.scale = SCNVector3Make(speedo.speedoScale, speedo.speedoScale, speedo.speedoScale);
    
    NSData *data2 = UIImagePNGRepresentation(img2);
    
    SCNMaterial *material2 = [SCNMaterial material];
    material2.diffuse.contents = data2;
    material2.locksAmbientWithDiffuse = YES;
    p2.geometry.firstMaterial = material2;
    
    SCNNode *parent = [SCNNode node];
    speedo.needle = parent;
    SCNNode *shadowParent = [SCNNode node];
    speedo.needleShadow = shadowParent;
        
    [speedo.needle addChildNode:p];
    [speedo.needleShadow addChildNode:p2];

    [speedo.pNode addChildNode:speedo.needle];
    [speedo.pNode addChildNode:speedo.needleShadow];
    
    SCNVector3 v = speedo.needle.eulerAngles;
    speedo.needleOrigRotation = v;
    
    [self.speedos addObject:speedo];
    
    return speedo;
}

-(void)createEnv
{
    self.speedos = [NSMutableArray new];
    
    [self createSpeedo:SPEEDO_TYPE_GOLF_R];
    [self createSpeedo:SPEEDO_TYPE_OTHER_CAR];
    [self createSpeedo:SPEEDO_TYPE_OLDER_CAR];
    self.activeSpeedo = 0;
    
    [self makeSpeedoActive:self.activeSpeedo];
  //  [self.hud updateLabel:[NSString stringWithFormat:@"%d km/h", self.speed]];
    [self updateHud];
}

-(void)calcSpeed:(bool)moveImmediately
{
    for (int i=0; i<self.speedos.count; i++) {
        Speedo *sp = [self.speedos objectAtIndex:i];
    
        double angle = [self calculateNeedleAngle:sp];
    
        // GPS update frequency is by default 1 Hz
        double dur = 2.0;
        if (moveImmediately == true) {
            // move camera immediately
            dur = 1.0;
        }
        
        double z = sp.needleOrigRotation.z-angle;
        [sp.needle runAction:[SCNAction rotateToX:sp.needleOrigRotation.x y:sp.needleOrigRotation.y z:z duration:1.0] forKey:@"move"];
        [sp.needleShadow runAction:[SCNAction rotateToX:sp.needleOrigRotation.x y:sp.needleOrigRotation.y z:z duration:1.0] forKey:@"move"];

        if (self.activeSpeedo == i && self.speedoMode == FOLLOW_NEEDLE) {
 
            double ang = angle;
            self.oldAngle = ang;
            [SCNTransaction begin];
            [SCNTransaction setAnimationDuration:dur];
        
            SCNNode* node = self.cameraNode;
            node.position = SCNVector3Make(-25*cos(ang - M_PI*28/180), 30*sin(ang - M_PI*28/180), 0);
            
            [SCNTransaction commit];
        }
    }
    [self updateHud];
}

// Location Manager Delegate Methods
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *loc = [locations lastObject];
    self.speed = (int)([loc speed]*3.6);
    if (self.speed < 0) {
        self.speed = 0;
        [self cancelRecordingAcceleration];
    }
    if (self.prevSpeed == 0 && self.speed > 0 && self.speed < SPEED_MAX &&
        self.isMeasuring0to100 == false && self.oldGPSTimestamp > 0) {
        [self startRecordingAccelerationFromZero];
        self.startedAccelerationTimestamp = self.startedAccelerationTimestamp - GPS_ACCELERATION_ADJUSTMENT; // adjust start time, not accurate as we don't know the actual start time if not using accelerometer.
    }
    
    self.combinedAcceleration = SCNVector3Make(0, 0, 0); // reset gyro
    double currentTime = (NSTimeInterval)([[NSDate date] timeIntervalSince1970]);
    double timeDiff = (currentTime - self.oldGPSTimestamp);

    if (self.isMeasuring0to100 == true) {
        NSLog(@"GPS speed: %d", self.speed);
        NSLog(@"Gyro speed: %d", self.gyroSpeed);
        NSLog(@"timestamp: %f", (currentTime-self.startedAccelerationTimestamp));
    }
    
    if (self.isMeasuring0to100 == true && self.speed >= SPEED_MAX) {
        self.isMeasuring0to100 = false;
        if (self.updateTimer != nil) {
            [self.updateTimer invalidate];
            self.updateTimer = nil;
        }
        self.endedAccelerationTimestamp = currentTime;
        if (self.speed == SPEED_MAX) {
            self.zeroTo100Time = self.endedAccelerationTimestamp-self.startedAccelerationTimestamp;
        } else {
            // calculate how long ago we passed the threshold
            double speedDiff = self.speed - self.prevSpeed;
          //  double timeDiff = (currentTime-self.oldGPSTimestamp);
            
            if (speedDiff > 0) {
                double thresholdTimeAdjustment = (self.speed-SPEED_MAX)/speedDiff * timeDiff;
                
                NSLog(@"adjustment %fs", thresholdTimeAdjustment);
                // calculate adjusted time
                self.zeroTo100Time = self.endedAccelerationTimestamp-self.startedAccelerationTimestamp-thresholdTimeAdjustment;
            }
        }
    }
    
    self.gyroSpeed = 0;
    self.prevSpeed = self.speed;
    
    self.oldGPSTimestamp = currentTime;

//    NSLog(@"Gyro speed:");
 //   NSLog(@"%d", self.gyroSpeed);

    [self calcSpeed:false];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // create a new scene
    SCNScene *scene = [SCNScene scene];
    self.scene = scene;
    
    SCNView *scnView = (SCNView *)self.view;
    
    // set the scene to the view
    scnView.scene = scene;
    
    // allows the user to manipulate the camera
    scnView.allowsCameraControl = NO;
    
    // show statistics such as fps and timing information
    scnView.showsStatistics = NO;
    
    // configure the view
    scnView.backgroundColor = [UIColor blackColor];

    self.hud = [Hud alloc];
    
    scnView.overlaySKScene = [self.hud initWithSize:[UIScreen mainScreen].bounds.size];
    
    if (self.view.window) {
        [self becomeFirstResponder];
    }
    
    scene.physicsWorld.gravity = SCNVector3Make(0, 0, 0);

    self.speed = 0;
    self.prevSpeed = 0;
    
    self.oldGPSTimestamp = 0;
    
    self.isMeasuring0to100 = false;
    
    self.speedoMode = NORMAL;
    
    self.oldAngle = 0;
    
    // create and add a camera to the scene
    SCNNode *cameraNode = [SCNNode node];
    [scene.rootNode addChildNode:cameraNode];
    cameraNode.position = SCNVector3Make(0, 0, 0);
    
    // place the camera
    SCNNode *cameraChildNode = [SCNNode node];
    cameraChildNode.eulerAngles = SCNVector3Make(0/180.0*M_PI, 0, 0);
    cameraChildNode.position = SCNVector3Make(0, 22, 56 - self.cameraNode.position.z);
    
    cameraChildNode.camera = [SCNCamera camera];
    cameraChildNode.camera.zFar = 300;
    //cameraChildNode.camera.xFov = 33; // for old iOS 10
    cameraChildNode.camera.fieldOfView = 33;
    cameraChildNode.camera.projectionDirection = SCNCameraProjectionDirectionHorizontal;
    [cameraNode addChildNode:cameraChildNode];

    self.cameraNode = cameraNode;

    SCNNode *lightContainerNode = [SCNNode node];
    lightContainerNode.position = SCNVector3Make(0, 30, 200);
    lightContainerNode.rotation = SCNVector4Make(0, 0, -1, 0);
    [scene.rootNode addChildNode:lightContainerNode];
    
    // create and add a light to the scene
    SCNNode *lightNode = [SCNNode node];
    lightNode.light = [SCNLight light];
    lightNode.light.type = SCNLightTypeOmni;
    [lightContainerNode addChildNode:lightNode];
    
    // create and add an ambient light to the scene
    SCNNode *ambientLightNode = [SCNNode node];
    ambientLightNode.light = [SCNLight light];
    ambientLightNode.light.type = SCNLightTypeAmbient;
    ambientLightNode.light.color = [UIColor colorWithWhite:1.0 alpha:1.0];  //]darkGrayColor];
    [scene.rootNode addChildNode:ambientLightNode];
    
// temp
  /*  UIImage *env = [UIImage imageNamed: @"nature.jpg"];
    scene.lightingEnvironment.contents = env;
    scene.lightingEnvironment.intensity = 1.0;*/
// end of temp
    [self createEnv];
    
    [scnView prepareObjects:@[scene] withCompletionHandler:^(BOOL success) {
    }];
    
    /*   SCNLookAtConstraint* c = [SCNLookAtConstraint lookAtConstraintWithTarget:node];
    cameraNode.constraints = @[c];
   */

    // add a tap gesture recognizer
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapGesture.numberOfTapsRequired = 2;
    
//    UILongPressGestureRecognizer *pressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlePress:)];
    UISwipeGestureRecognizer *swipeRightGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeRight:)];
    [swipeRightGesture setDirection:UISwipeGestureRecognizerDirectionRight];
    UISwipeGestureRecognizer *swipeLeftGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeLeft:)];
    [swipeLeftGesture setDirection:UISwipeGestureRecognizerDirectionLeft];

    NSMutableArray *gestureRecognizers = [NSMutableArray array];
    [gestureRecognizers addObject:tapGesture];
    //[gestureRecognizers addObject:pressGesture];
    [gestureRecognizers addObject:swipeRightGesture];
    [gestureRecognizers addObject:swipeLeftGesture];
    [gestureRecognizers addObjectsFromArray:scnView.gestureRecognizers];
    scnView.gestureRecognizers = gestureRecognizers;

    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBestForNavigation];
    [self.locationManager startUpdatingLocation];
    
    self.motionManager = [[CMMotionManager alloc] init];
    
    self.isAccelerometerEnabled = false;
    
    if ([self.motionManager isAccelerometerAvailable]) {
        self.isAccelerometerEnabled = true;
        
        self.motionManager.accelerometerUpdateInterval = 0.01; //100Hz
       // self.motionManager.gyroUpdateInterval = 0.01;
        self.motionQueue = [[NSOperationQueue alloc] init];
        [self.motionQueue setMaxConcurrentOperationCount:1]; // Serial operation queue
        
        CMAttitudeReferenceFrame frame = CMAttitudeReferenceFrameXArbitraryCorrectedZVertical;
        [self.motionManager setDeviceMotionUpdateInterval:0.01];
        [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:frame
                                                            toQueue:self.motionQueue
                                                           withHandler:
         ^(CMDeviceMotion* motion, NSError* error) {
             if (error) {
                NSLog(@"%@", error);
             }
             [self outputAccelerationData:motion];
         }];
        
    } else {
        NSLog(@"Accelerometer is not available!\n");
    }
    
    self.combinedAcceleration = SCNVector3Make(0,0,0);

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appMovedToBackground:) name:UIApplicationWillResignActiveNotification object:nil];

    
    [self showNotification];
}

-(void)appMovedToBackground:(NSNotification *)note
{
    [self cancelRecordingAcceleration];
}

-(void)outputAccelerationData:(CMDeviceMotion*)motion
{
    if (self.oldGyroTimestamp == 0) {
        double currentTime = (NSTimeInterval)([[NSDate date] timeIntervalSince1970]);
        self.oldGyroTimestamp = currentTime;
        self.gyroSpeed = 0;
        return;
    }
    double currentTime = (NSTimeInterval)([[NSDate date] timeIntervalSince1970]);

    if (fabs(motion.userAcceleration.x) < accelerationThreshold
        && fabs(motion.userAcceleration.y) < accelerationThreshold
        && fabs(motion.userAcceleration.z) < accelerationThreshold)
    {
        return; // ignore slight movements
    }
    
    if (self.speed == 0) { // we're standing still, but moving again
        [self startRecordingAccelerationFromZero];
    }
    
    double x = self.combinedAcceleration.x + motion.userAcceleration.x;
    double y = self.combinedAcceleration.y + motion.userAcceleration.y;
    double z = self.combinedAcceleration.z + motion.userAcceleration.z;
    self.combinedAcceleration = SCNVector3Make(x, y, z);
 
    double timediff = (currentTime - self.oldGyroTimestamp);
    self.oldGyroTimestamp = currentTime;
    
    double xx = (self.combinedAcceleration.x * self.combinedAcceleration.x) +
    (self.combinedAcceleration.y * self.combinedAcceleration.y) +
    (self.combinedAcceleration.z * self.combinedAcceleration.z);
    if (xx != 0) {
        self.gyroSpeed = self.speed +
        sqrtf(xx) * 9.81 * 3.6 *
        timediff;
    }

    NSLog(@"gyro updateInterval: %f %f,%f,%f", timediff,motion.userAcceleration.x, motion.userAcceleration.y, motion.userAcceleration.z);
    [self updateHud];
}

-(void)startRecordingAccelerationFromZero
{
    self.startedAccelerationTimestamp = (NSTimeInterval)([[NSDate date] timeIntervalSince1970]);
    self.isMeasuring0to100 = true;

    if (self.updateTimer != nil) {
        [self.updateTimer invalidate];
        self.updateTimer = nil;
    }
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block: ^(NSTimer *timer) {
        [self updateCounter];
    }];
}

-(void)cancelRecordingAcceleration
{
    self.isMeasuring0to100 = false;
    if (self.updateTimer != nil) {
        [self.updateTimer invalidate];
        self.updateTimer = nil;
    }
    [self.hud updateLabel3:@""];
}

-(void)updateCounter
{
    double currentTime = (NSTimeInterval)([[NSDate date] timeIntervalSince1970]);
    double diff = currentTime - self.startedAccelerationTimestamp;
    [self.hud updateLabel3:[NSString stringWithFormat:@"%.1f s", diff]];
    
    if (self.isMeasuring0to100 == true &&
        diff >= MAX_ACCELERATION_TIME_UNTIL_CANCELLED) { // takes too long, cancel it
        [self cancelRecordingAcceleration];
    }
}

-(void)updateHud
{
    double currentTime = (NSTimeInterval)([[NSDate date] timeIntervalSince1970]);
    NSString *accelerationText = @"";
    if (self.zeroTo100Time >0 &&
        self.isMeasuring0to100 == false &&
        currentTime - self.endedAccelerationTimestamp < 30.0) { // show 30 seconds
        accelerationText = [NSString stringWithFormat:@"%d-%d km/h : %.1f s", SPEED_MIN, SPEED_MAX, self.zeroTo100Time];
    }
    [self.hud updateLabel:[NSString stringWithFormat:@"%d km/h", self.speed]];
    [self.hud updateLabel2:[NSString stringWithFormat:@"%d km/h", self.gyroSpeed]];
    if (accelerationText.length > 0) {
        [self.hud updateLabel3:[NSString stringWithFormat:@"%@", accelerationText]];
    }
}

-(void)outputRotationData:(CMRotationRate)rotation
{
    
}

-(void)showNotification
{
    UIWindow* topWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    topWindow.rootViewController = [UIViewController new];
    topWindow.windowLevel = UIWindowLevelAlert + 1;

    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Info" message:@"Double tap to change mode, swipe left/right to change the dashboard." preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",@"confirm") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    // continue your work
    
    // important to hide the window after work completed.
    // this also keeps a reference to the window until the action is invoked.
        topWindow.hidden = YES;
    }]];

    [topWindow makeKeyAndVisible];
    [topWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}

-(void)handleTap:(UIGestureRecognizer*)gestureRecognize
{
    Speedo *sp = self.speedos[self.activeSpeedo];
    if (self.speedoMode == ROTATED) {
        self.speedoMode = FOLLOW_NEEDLE;
        self.oldAngle = [self calculateNeedleAngle:sp];

//        SCNLookAtConstraint* c = [SCNLookAtConstraint lookAtConstraintWithTarget:node];
 //       cameraNode.constraints = @[c];

        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:0.8];
        SCNNode* node = self.cameraNode.childNodes.firstObject;
        node.eulerAngles = SCNVector3Make(45/180.0*M_PI, 0, 0);
        node.position = SCNVector3Make(0, -40, -30 - self.cameraNode.position.z);
        
        double angle = [self calculateNeedleAngle:sp];
        SCNVector3 vec = SCNVector3Make(-25*cos(angle - M_PI*28/180), 30*sin(angle - M_PI*28/180), 0);
        self.cameraNode.position = vec;
        
        [SCNTransaction commit];
        
    } else if (self.speedoMode == NORMAL) {
        self.speedoMode = ROTATED;
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:0.8];
        SCNNode* node = self.cameraNode.childNodes.firstObject;
        node.eulerAngles = SCNVector3Make(45/180.0*M_PI, 0, 0);
        node.position = SCNVector3Make(0, -80, 36 - self.cameraNode.position.z);
        [SCNTransaction commit];
    } else if (self.speedoMode == FOLLOW_NEEDLE) {
        self.speedoMode = NORMAL;
        
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:0.8];
        SCNNode* node = self.cameraNode.childNodes.firstObject;
        node.eulerAngles = SCNVector3Make(0/180.0*M_PI, 0, 0);
        node.position = SCNVector3Make(0, 22, 56 - self.cameraNode.position.z);
        
        SCNVector3 vec = SCNVector3Make(0,0,0);
        self.cameraNode.position = vec;
        [SCNTransaction commit];
    }
}

    
-(void)handleSwipeRight:(UIGestureRecognizer*)gestureRecognize
{
    if (self.activeSpeedo > 0 ) {
        
        [SCNTransaction begin];
/*        [SCNTransaction setCompletionBlock:^{
            [self makeSpeedoActive:self.activeSpeedo-1];
        }];*/
        [SCNTransaction setAnimationDuration:1.0];
        
        for (int i=0; i<self.speedos.count; i++) {
            Speedo *sp = [self.speedos objectAtIndex:i];
            sp.pNode.position = SCNVector3Make(sp.pNode.position.x + SPEEDO_PADDING, sp.pNode.position.y, sp.pNode.position.z);
        }
        [SCNTransaction commit];
        [self makeSpeedoActive:self.activeSpeedo-1];
    }/* else {
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:1.0];
        
        for (int i=0; i<self.speedos.count; i++) {
            Speedo *sp = [self.speedos objectAtIndex:i];
            sp.pNode.position = SCNVector3Make((i-(self.speedos.count-1))*SPEEDO_PADDING, sp.pNode.position.y, sp.pNode.position.z);
        }
        [SCNTransaction commit];
        [self makeSpeedoActive:(int)self.speedos.count-1];
    }*/
}

-(void)handleSwipeLeft:(UIGestureRecognizer*)gestureRecognize
{
    if (self.activeSpeedo < self.speedos.count-1 ) {

        [SCNTransaction begin];
  /*      [SCNTransaction setCompletionBlock:^{
            [self makeSpeedoActive:self.activeSpeedo+1];
        }];
*/        [SCNTransaction setAnimationDuration:1.0];
        
        for (int i=0; i<self.speedos.count; i++) {
            Speedo *sp = [self.speedos objectAtIndex:i];
            sp.pNode.position = SCNVector3Make(sp.pNode.position.x - SPEEDO_PADDING, sp.pNode.position.y, sp.pNode.position.z);
        }
        [SCNTransaction commit];
        [self makeSpeedoActive:self.activeSpeedo+1];
    }/* else {
        [SCNTransaction begin];
        [SCNTransaction setAnimationDuration:1.0];
        
        for (int i=0; i<self.speedos.count; i++) {
            Speedo *sp = [self.speedos objectAtIndex:i];
            sp.pNode.position = SCNVector3Make(i*SPEEDO_PADDING, sp.pNode.position.y, sp.pNode.position.z);
        }
        [SCNTransaction commit];
        [self makeSpeedoActive:0];
    }*/
}

-(void)makeSpeedoActive:(int)speedoIndex
{
    if (self.activeSpeedo != speedoIndex) {
        Speedo* oldsp = [self.speedos objectAtIndex:self.activeSpeedo];
        if (oldsp.speedoType == SPEEDO_TYPE_OLDER_CAR) {
            [oldsp.needle removeActionForKey:@"vibra"];
            [oldsp.needleShadow removeActionForKey:@"vibra"];
            [self.cameraNode removeActionForKey:@"vibra"];
        }
    }
    
    self.activeSpeedo = speedoIndex;
    if (self.activeSpeedo >= self.speedos.count) {
        self.activeSpeedo = (int)self.speedos.count-1;
    }
    if (self.activeSpeedo<0) {
        self.activeSpeedo = 0;
    }
    Speedo* speedo = self.speedos[self.activeSpeedo];
    if (speedo.speedoType == SPEEDO_TYPE_OLDER_CAR) {
        SCNAction *act1 = [SCNAction moveByX:0.1 y:0.1 z:0 duration:0.02];
        SCNAction *act2 = [SCNAction moveByX:-0.1 y:-0.1 z:0 duration:0.02];
        SCNAction *vibrateSequence = [SCNAction sequence:@[act1,act2]];
        SCNAction *vibrateLoop = [SCNAction repeatActionForever:vibrateSequence];

        [speedo.needle runAction:[SCNAction repeatActionForever:vibrateLoop] forKey:@"vibra"];
        [speedo.needleShadow runAction:[SCNAction repeatActionForever:vibrateLoop] forKey:@"vibra"];
        
        // vibrate camera
        SCNAction *cact1 = [SCNAction moveByX:0.1 y:0.1 z:0.05 duration:0.02];
        SCNAction *cact2 = [SCNAction moveByX:-0.1 y:-0.1 z:-0.05 duration:0.02];
        SCNAction *cvibrateSequence = [SCNAction sequence:@[cact1,cact2]];
        SCNAction *cvibrateLoop = [SCNAction repeatActionForever:cvibrateSequence];
        
        speedo.cameraAction = [SCNAction repeatActionForever:cvibrateLoop];
        [self.cameraNode runAction:speedo.cameraAction forKey:@"vibra"];
    }
    [self calcSpeed:true];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}


- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    if (motion == UIEventSubtypeMotionShake)
    {
    }
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}
@end
