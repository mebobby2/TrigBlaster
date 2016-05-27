#import "HelloWorldLayer.h"
#import "SimpleAudioEngine.h"

const float MaxPlayerAccel = 400.0f;
const float MaxPlaySpeed = 200.0f;

@implementation HelloWorldLayer
{
    CGSize _winSize;
    CCSprite *_playerSprite;
    
    UIAccelerationValue _accelerometerX;
    UIAccelerationValue _accelerometerY;
    
    float _playerAccelX;
    float _playerAccelY;
    float _playerSpeedX;
    float _playerSpeedY;
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
        [self scheduleUpdate]; //Tells cocos2d to call our update method (60fps)
    }
    return self;
}

-(void)update:(ccTime)delta
{
    [self updatePlayer:delta];
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
    _accelerometerY = acceleration.y * FilteringFactor + _accelerometerY * (1.0 - FilteringFactor);

    // We use accelerometer's Y for the x direction because this game is played in landscape, not portrait.
    if (_accelerometerY > 0.05) {
        _playerAccelX = -MaxPlayerAccel;
    }
    else if (_accelerometerY < -0.05)
    {
        _playerAccelX = MaxPlayerAccel;
    }
    
    if (_accelerometerX < -0.05) {
        _playerAccelY = -MaxPlayerAccel;
    }
    else if (_accelerometerX > 0.05)
    {
        _playerAccelY = MaxPlayerAccel;
    }
}

-(void)updatePlayer:(ccTime) dt
{
    //    Movement in games often works like this:
    //    Set the acceleration based on some form of user input, in this case from the accelerometer values.
    //    Add the new acceleration to the spaceship’s current speed. This makes the object speed up or slow down, depending on the direction of the acceleration.
    //    Add the new speed to the spaceship’s position to make it move.
    
    //    Formula: acceleration = speed / time
    
    // The acceleration is expressed in points per second (actually, per second squared, but don’t worry about that) but update: is performed a lot more often than once per second. To compensate for this difference, you multiply the acceleration by the elapsed or “delta” time, dt. Without this, the spaceship would move about sixty times faster than it should!
    _playerSpeedX += _playerAccelX * dt;
    _playerSpeedY += _playerAccelY * dt;
    
    _playerSpeedX = fmaxf(fminf(_playerSpeedX, MaxPlaySpeed), -MaxPlaySpeed);
    _playerSpeedY = fmaxf(fminf(_playerSpeedY, MaxPlaySpeed), -MaxPlaySpeed);
    
//    Add the current speed to the sprite’s position. Again, speed is measured in points per second, so you need to multiply it by the delta time to make it work correctly
    
    // Formula: speed = distance / time
    // So _playerSpeedX*dt gives us the distance travelled, and we just add that distance to the player's current x.
    // In SpaceWars (using SFML) we use vector to represent the player's velocity and SFML positions the player's
    // sprite using this vector (then renders it). However, in this case, we set the player's x and y coordinates
    // directly and cocos2d renders it as is.
    float newX = _playerSprite.position.x + _playerSpeedX*dt;
    float newY = _playerSprite.position.y + _playerSpeedY*dt;
    
    newX = MIN(_winSize.width, MAX(newX, 0));
    newY = MIN(_winSize.height, MAX(newY, 0));
    
    _playerSprite.position = ccp(newX, newY);
}

@end
