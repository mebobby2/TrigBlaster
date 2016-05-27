#import "HelloWorldLayer.h"
#import "SimpleAudioEngine.h"

@implementation HelloWorldLayer
{
    CGSize _winSize;
    CCSprite *_playerSprite;
    
    UIAccelerationValue _accelerometerX;
    UIAccelerationValue _accerlerometerY;
}

+ (CCScene*)scene
{
    CCScene *scene = [CCScene node];
    HelloWorldLayer *layer = [HelloWorldLayer node];
    [scene addChild:layer];
    return scene;
}

-(id)init
{
    if (self = [super initWithColor:ccc4(94, 63, 107, 255)])
    {
        _winSize = [CCDirector sharedDirector].winSize;
        
        _playerSprite = [CCSprite spriteWithFile:@"Images/Player.png"];
        _playerSprite.position = ccp(_winSize.width - 50.0f, 50.0f);
        [self addChild:_playerSprite];
        
        self.accelerometerEnabled = YES;
    }
    return self;
}

-(void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration
{
//    An accelerometer records how much gravity currently pulls on it. Because the user is holding the iPhone in her
//    hands, and hands are never completely steady, there are a lot of tiny fluctuations in this gravity value. We are not
//    so much interested in these unsteady motions as in the larger changes in orientation that the user makes to the device.
//    By applying this simple low-pass filter, you retain this orientation information but filter out the less important
//    fluctuations.
    
    const double FilteringFactor = 0.75;
    
    _accelerometerX = acceleration.x * FilteringFactor + _accelerometerX * (1.0 - FilteringFactor);
    _accerlerometerY = acceleration.y * FilteringFactor + _accerlerometerY * (1.0 - FilteringFactor);
}

@end
