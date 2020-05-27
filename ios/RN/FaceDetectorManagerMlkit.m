#import "FaceDetectorManagerMlkit.h"
#import <React/RCTConvert.h>
#import <React/RCTLog.h>
#if __has_include(<FirebaseMLVision/FirebaseMLVision.h>)

@interface FaceDetectorManagerMlkit ()
@property(nonatomic, strong) FIRVisionFaceDetector *faceRecognizer;
@property(nonatomic, strong) FIRVision *vision;
@property(nonatomic, strong) FIRVisionFaceDetectorOptions *options;
@property(nonatomic, assign) float scaleX;
@property(nonatomic, assign) float scaleY;
@end

@implementation FaceDetectorManagerMlkit

- (instancetype)init
{
  if (self = [super init]) {
    self.options = [[FIRVisionFaceDetectorOptions alloc] init];
    self.options.performanceMode = FIRVisionFaceDetectorPerformanceModeFast;
    self.options.landmarkMode = FIRVisionFaceDetectorLandmarkModeNone;
    self.options.classificationMode = FIRVisionFaceDetectorClassificationModeNone;
    self.options.contourMode = FIRVisionFaceDetectorContourModeNone;
    
    self.vision = [FIRVision vision];
    self.faceRecognizer = [_vision faceDetectorWithOptions:_options];
  }
  return self;
}

- (BOOL)isRealDetector
{
  return true;
}

+ (NSDictionary *)constants
{
    NSString *astring = @"!!!!!!!!!!!!!!!!!!!!!!";
    NSString *bstring = @"!!!!!!!!!!!!!!!!!!!!!!";
    RCTLogInfo(@"Pretending to create an event %@ at %@", astring, bstring);
    return @{
             @"Mode" : @{
                     @"fast" : @(RNFaceDetectionFastMode),
                     @"accurate" : @(RNFaceDetectionAccurateMode)
                     },
             @"Landmarks" : @{
                     @"all" : @(RNFaceDetectAllLandmarks),
                     @"none" : @(RNFaceDetectNoLandmarks)
                     },
             @"Classifications" : @{
                     @"all" : @(RNFaceRunAllClassifications),
                     @"none" : @(RNFaceRunNoClassifications)
                     },
             @"Contours" : @{
                     @"all" : @(RNFaceRunAllClassifications),
                     @"none" : @(RNFaceRunNoClassifications)
                     }
             };
}

- (void)setTracking:(id)json queue:(dispatch_queue_t)sessionQueue
{
  BOOL requestedValue = [RCTConvert BOOL:json];
  if (requestedValue != self.options.trackingEnabled) {
      if (sessionQueue) {
          dispatch_async(sessionQueue, ^{
              self.options.trackingEnabled = requestedValue;
              self.faceRecognizer =
              [self.vision faceDetectorWithOptions:self.options];
          });
      }
  }
}

- (void)setLandmarksMode:(id)json queue:(dispatch_queue_t)sessionQueue
{
    long requestedValue = [RCTConvert NSInteger:json];
    if (requestedValue != self.options.landmarkMode) {
        if (sessionQueue) {
            dispatch_async(sessionQueue, ^{
                self.options.landmarkMode = requestedValue;
                self.faceRecognizer =
                [self.vision faceDetectorWithOptions:self.options];
            });
        }
    }
}

- (void)setPerformanceMode:(id)json queue:(dispatch_queue_t)sessionQueue
{
    long requestedValue = [RCTConvert NSInteger:json];
    if (requestedValue != self.options.performanceMode) {
        if (sessionQueue) {
            dispatch_async(sessionQueue, ^{
                self.options.performanceMode = requestedValue;
                self.faceRecognizer =
                [self.vision faceDetectorWithOptions:self.options];
            });
        }
    }
}

- (void)setClassificationMode:(id)json queue:(dispatch_queue_t)sessionQueue
{
    long requestedValue = [RCTConvert NSInteger:json];
    if (requestedValue != self.options.classificationMode) {
        if (sessionQueue) {
            dispatch_async(sessionQueue, ^{
                self.options.classificationMode = requestedValue;
                self.faceRecognizer =
                [self.vision faceDetectorWithOptions:self.options];
            });
        }
    }
}

- (void)setContourMode:(id)json queue:(dispatch_queue_t)sessionQueue
{
    long requestedValue = [RCTConvert NSInteger:json];
    if (requestedValue != self.options.contourMode) {
        if (sessionQueue) {
            dispatch_async(sessionQueue, ^{
                self.options.contourMode = requestedValue;
                self.faceRecognizer =
                [self.vision faceDetectorWithOptions:self.options];
            });
        }
    }
}

- (void)findFacesInFrame:(UIImage *)uiImage
                  scaleX:(float)scaleX
                  scaleY:(float)scaleY
               completed:(void (^)(NSArray *result))completed
{
    self.scaleX = scaleX;
    self.scaleY = scaleY;
    FIRVisionImage *image = [[FIRVisionImage alloc] initWithImage:uiImage];
    NSMutableArray *emptyResult = [[NSMutableArray alloc] init];
    [_faceRecognizer
     processImage:image
     completion:^(NSArray<FIRVisionFace *> *faces, NSError *error) {
         if (error != nil || faces == nil) {
             completed(emptyResult);
         } else {
             completed([self processFaces:faces]);
         }
     }];
}

- (NSArray *)processFaces:(NSArray *)faces
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    for (FIRVisionFace *face in faces) {
        NSMutableDictionary *resultDict =
        [[NSMutableDictionary alloc] initWithCapacity:20];
        // Boundaries of face in image
        NSDictionary *bounds = [self processBounds:face.frame];
        [resultDict setObject:bounds forKey:@"bounds"];
        // If face tracking was enabled:
        if (face.hasTrackingID) {
            NSInteger trackingID = face.trackingID;
            [resultDict setObject:@(trackingID) forKey:@"faceID"];
        }
        // Head is rotated to the right rotY degrees
        if (face.hasHeadEulerAngleY) {
            CGFloat rotY = face.headEulerAngleY;
            [resultDict setObject:@(rotY) forKey:@"yawAngle"];
        }
        // Head is tilted sideways rotZ degrees
        if (face.hasHeadEulerAngleZ) {
            CGFloat rotZ = -1 * face.headEulerAngleZ;
            [resultDict setObject:@(rotZ) forKey:@"rollAngle"];
        }
        
        // If landmark detection was enabled (mouth, ears, eyes, cheeks, and
        // nose available):
        /** Midpoint of the left ear tip and left ear lobe. */
        FIRVisionFaceLandmark *leftEar =
        [face landmarkOfType:FIRFaceLandmarkTypeLeftEar];
        if (leftEar != nil) {
            [resultDict setObject:[self processPoint:leftEar.position]
                           forKey:@"leftEarPosition"];
        }
        /** Midpoint of the right ear tip and right ear lobe. */
        FIRVisionFaceLandmark *rightEar =
        [face landmarkOfType:FIRFaceLandmarkTypeRightEar];
        if (rightEar != nil) {
            [resultDict setObject:[self processPoint:rightEar.position]
                           forKey:@"rightEarPosition"];
        }
        /** Center of the bottom lip. */
        FIRVisionFaceLandmark *mouthBottom =
        [face landmarkOfType:FIRFaceLandmarkTypeMouthBottom];
        if (mouthBottom != nil) {
            [resultDict setObject:[self processPoint:mouthBottom.position]
                           forKey:@"bottomMouthPosition"];
        }
        /** Right corner of the mouth */
        FIRVisionFaceLandmark *mouthRight =
        [face landmarkOfType:FIRFaceLandmarkTypeMouthRight];
        if (mouthRight != nil) {
            [resultDict setObject:[self processPoint:mouthRight.position]
                           forKey:@"rightMouthPosition"];
        }
        /** Left corner of the mouth */
        FIRVisionFaceLandmark *mouthLeft =
        [face landmarkOfType:FIRFaceLandmarkTypeMouthLeft];
        if (mouthLeft != nil) {
            [resultDict setObject:[self processPoint:mouthLeft.position]
                           forKey:@"leftMouthPosition"];
        }
        /** Left eye. */
        FIRVisionFaceLandmark *eyeLeft =
        [face landmarkOfType:FIRFaceLandmarkTypeLeftEye];
        if (eyeLeft != nil) {
            [resultDict setObject:[self processPoint:eyeLeft.position]
                           forKey:@"leftEyePosition"];
        }
        /** Right eye. */
        FIRVisionFaceLandmark *eyeRight =
        [face landmarkOfType:FIRFaceLandmarkTypeRightEye];
        if (eyeRight != nil) {
            [resultDict setObject:[self processPoint:eyeRight.position]
                           forKey:@"rightEyePosition"];
        }
        /** Left cheek. */
        FIRVisionFaceLandmark *cheekLeft =
        [face landmarkOfType:FIRFaceLandmarkTypeLeftCheek];
        if (cheekLeft != nil) {
            [resultDict setObject:[self processPoint:cheekLeft.position]
                           forKey:@"leftCheekPosition"];
        }
        /** Right cheek. */
        FIRVisionFaceLandmark *cheekRight =
        [face landmarkOfType:FIRFaceLandmarkTypeRightCheek];
        if (cheekRight != nil) {
            [resultDict setObject:[self processPoint:cheekRight.position]
                           forKey:@"rightCheekPosition"];
        }
        /** Midpoint between the nostrils where the nose meets the face. */
        FIRVisionFaceLandmark *noseBase =
        [face landmarkOfType:FIRFaceLandmarkTypeNoseBase];
        if (noseBase != nil) {
            [resultDict setObject:[self processPoint:noseBase.position]
                           forKey:@"noseBasePosition"];
        }
        // If contours has enabled!!!:
        FIRVisionFaceContour *allContour =
        [face contourOfType:FIRFaceContourTypeAll];
        if (allContour != nil) {
            RCTLogInfo(@"All Contours %@ ", allContour);
//            long int count = [allContour.points count];
//            for (int i = 0 ; i < count; i++) {
//                RCTLogInfo(@"1遍历allContour: %zi-->%@",i,[allContour.points objectAtIndex:i].x);
//            }
            NSArray *array = allContour.points;
            NSMutableArray *ans = [NSMutableArray array];
            for (int i = 0; i < array.count; i++) {
                FIRVisionPoint *f = array[i];
                ;
                [ans addObject:[self processPoint:f]];
            }
//            [resultDict setObject:ans
//                           forKey:@"allPoints"];
        }
        
        FIRVisionFaceContour *faceContour =
        [face contourOfType:FIRFaceContourTypeFace];
        if (faceContour !=nil) {
            [resultDict setObject:[self processPoints:faceContour.points]
                           forKey:@"face"];
        }
        
        FIRVisionFaceContour *leftEyebrowTopContour =
        [face contourOfType:FIRFaceContourTypeLeftEyebrowTop];
        if (leftEyebrowTopContour != nil ){
            [resultDict setObject:[self processPoints:leftEyebrowTopContour.points]
                           forKey:@"leftEyebrowTop"];
        }
        
        FIRVisionFaceContour *leftEyebrowBottomContour =
        [face contourOfType:FIRFaceContourTypeLeftEyebrowBottom];
        if (leftEyebrowBottomContour != nil ){
            [resultDict setObject:[self processPoints:leftEyebrowBottomContour.points]
                           forKey:@"leftEyebrowBottom"];
        }
        
        FIRVisionFaceContour *rightEyebrowTopContour =
        [face contourOfType:FIRFaceContourTypeRightEyebrowTop];
        if (rightEyebrowTopContour != nil ){
            [resultDict setObject:[self processPoints:rightEyebrowTopContour.points]
                           forKey:@"rightEyebrowTop"];
        }
        
        
        FIRVisionFaceContour *rightEyebrowBottomContour =
        [face contourOfType:FIRFaceContourTypeRightEyebrowBottom];
        if (rightEyebrowBottomContour != nil ){
            [resultDict setObject:[self processPoints:rightEyebrowBottomContour.points]
                           forKey:@"rightEyebrowBottom"];
        }
        
        
        FIRVisionFaceContour *leftEyeContour =
        [face contourOfType:FIRFaceContourTypeLeftEye];
        if (leftEyeContour != nil ){
            [resultDict setObject:[self processPoints:leftEyeContour.points]
                           forKey:@"leftEye"];
        }

        FIRVisionFaceContour *rightEyeContour =
        [face contourOfType:FIRFaceContourTypeRightEye];
        if (rightEyeContour != nil ){
            [resultDict setObject:[self processPoints:rightEyeContour.points]
                           forKey:@"rightEye"];
        }

        FIRVisionFaceContour *upperLipTopContour =
        [face contourOfType:FIRFaceContourTypeUpperLipTop];
        if (upperLipTopContour != nil ){
            [resultDict setObject:[self processPoints:upperLipTopContour.points]
                           forKey:@"upperLipTop"];
        }
        
        
        FIRVisionFaceContour *upperLipBottomContour =
        [face contourOfType:FIRFaceContourTypeUpperLipBottom];
        if (upperLipBottomContour != nil ){
            [resultDict setObject:[self processPoints:upperLipBottomContour.points]
                           forKey:@"upperLipBottom"];
        }
        
        FIRVisionFaceContour *lowerLipTopContour =
        [face contourOfType:FIRFaceContourTypeLowerLipTop];
        if (lowerLipTopContour != nil ){
            [resultDict setObject:[self processPoints:lowerLipTopContour.points]
                           forKey:@"lowerLipTop"];
        }
        
        FIRVisionFaceContour *lowerLipBottomContour =
        [face contourOfType:FIRFaceContourTypeLowerLipBottom];
        if (lowerLipBottomContour != nil ){
            [resultDict setObject:[self processPoints:lowerLipBottomContour.points]
                           forKey:@"lowerLipBottom"];
        }
        
        
        FIRVisionFaceContour *noseBridgeContour =
        [face contourOfType:FIRFaceContourTypeNoseBridge];
        if (noseBridgeContour != nil ){
            [resultDict setObject:[self processPoints:noseBridgeContour.points]
                           forKey:@"noseBridge"];
        }
        
        
        FIRVisionFaceContour *noseBottomContour =
        [face contourOfType:FIRFaceContourTypeNoseBottom];
        if (noseBottomContour != nil ){
            [resultDict setObject:[self processPoints:noseBottomContour.points]
                           forKey:@"noseBottom"];
        }
        
        
        // If classification was enabled:
        if (face.hasSmilingProbability) {
            CGFloat smileProb = face.smilingProbability;
            [resultDict setObject:@(smileProb) forKey:@"smilingProbability"];
        }
        if (face.hasRightEyeOpenProbability) {
            CGFloat rightEyeOpenProb = face.rightEyeOpenProbability;
            [resultDict setObject:@(rightEyeOpenProb)
                           forKey:@"rightEyeOpenProbability"];
        }
        if (face.hasLeftEyeOpenProbability) {
            CGFloat leftEyeOpenProb = face.leftEyeOpenProbability;
            [resultDict setObject:@(leftEyeOpenProb)
                           forKey:@"leftEyeOpenProbability"];
        }
        
        if (face.hasLeftEyeOpenProbability) {
            CGFloat leftEyeOpenProb = face.leftEyeOpenProbability;
            [resultDict setObject:@(leftEyeOpenProb)
                           forKey:@"leftEyeOpenProbability"];
        }
        [result addObject:resultDict];
    }
    return result;
}

- (NSDictionary *)processBounds:(CGRect)bounds
{
    float width = bounds.size.width * _scaleX;
    float height = bounds.size.height * _scaleY;
    float originX = bounds.origin.x * _scaleX;
    float originY = bounds.origin.y * _scaleY;
    NSDictionary *boundsDict = @{
                                 @"size" : @{@"width" : @(width), @"height" : @(height)},
                                 @"origin" : @{@"x" : @(originX), @"y" : @(originY)}
                                 };
    return boundsDict;
}

- (NSMutableArray *)processPoints:(NSArray<FIRVisionPoint *> *)points
{
    NSMutableArray *ans = [NSMutableArray array];
    for (int i = 0; i < points.count; i++) {
        FIRVisionPoint *f = points[i];
        ;
        [ans addObject:[self processPoint:f]];
    }
    return ans;
}

- (NSDictionary *)processPoint:(FIRVisionPoint *)point
{
    float originX = [point.x floatValue] * _scaleX;
    float originY = [point.y floatValue] * _scaleY;
    NSDictionary *pointDict = @{
                                
                                @"x" : @(originX),
                                @"y" : @(originY)
                                };
    return pointDict;
}


@end
#else

@interface FaceDetectorManagerMlkit ()
@end

@implementation FaceDetectorManagerMlkit

- (instancetype)init {
    self = [super init];
    return self;
}

- (BOOL)isRealDetector {
    return false;
}

- (NSArray *)findFacesInFrame:(UIImage *)image
                       scaleX:(float)scaleX
                       scaleY:(float)scaleY
                       completed:(void (^)(NSArray *result))completed;
{
    NSLog(@"FaceDetector not installed, stub used!");
    NSArray *features = @[ @"Error, Face Detector not installed" ];
    return features;
}

- (void)setTracking:(id)json:(dispatch_queue_t)sessionQueue
{
    return;
}
- (void)setLandmarksMode:(id)json:(dispatch_queue_t)sessionQueue
{
    return;
}

- (void)setPerformanceMode:(id)json:(dispatch_queue_t)sessionQueue
{
    return;
}

- (void)setClassificationMode:(id)json:(dispatch_queue_t)sessionQueue
{
    return;
}

- (void)setContourMode:(id)json:(dispatch_queue_t)sessionQueue
{
    return;
}

+ (NSDictionary *)constantsToExport
{
    return @{
             @"Mode" : @{},
             @"Landmarks" : @{},
             @"Classifications" : @{}
             };
}

@end
#endif
