//
//  Speedo.h
//  RaceSpeedo
//
//  @author Janne Heinonen <jjh@iki.fi>
//  @brief RaceSpeedo - 24 May 2017
//  @license MIT

#ifndef Speedo_h
#define Speedo_h

#import <SceneKit/SceneKit.h>

#define WIDTH 5
#define HEIGHT 5

@interface Speedo : SCNNode

@property int speedoType; // SPEEDO_TYPE_*

@property double speedoScale; // how much to scale the speedo bounding box, so it fits the screen without moving the camera

@property SCNVector3 needleOrigRotation; // original rotation vector of the needle, before turning the needle

@property double width;
@property double height;

@property SCNNode *pNode;

@property SCNNode *speedo;
@property SCNNode *needle;
@property SCNNode *needleShadow;

@property SCNAction *cameraAction; // vibra etc.

@end


#endif /* Speedo_h */
