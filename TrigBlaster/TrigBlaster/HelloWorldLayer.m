#import "HelloWorldLayer.h"
#import "SimpleAudioEngine.h"

//Note: Now why is there an f behind those numbers in the code: 0.4f, 0.1f, 0.0f, and so on? And why did you use atan2f() instead of just atan2()? When you write games, you want to work with floating point numbers as much as possible because, unlike integers, they allow for digits behind the decimal point. This allows you to be much more precise.
//There are two types of floating point numbers: floats and doubles (there is also a “long double”, but that’s the same as a double on the iPhone). Doubles are more precise than floats but they also take up more memory and are slower in practice. When you don’t put the f behind the number and just use 0.4, 0.1, 0.0, or when you use the version of a math function without the f suffix, you are working with doubles and not floats.
//It doesn’t really matter if you use a double here and there. For example, the time value that CACurrentMediaTime() returns is a double. However, if you’re doing hundreds of thousands of calculations every frame, you will notice the difference. I did a quick test on a couple of my devices and the same calculations using doubles were 1.5 to 2 times slower. So it’s a good habit to stick to regular floats where you can.

const float MaxPlayerAccel = 400.0f;
const float MaxPlaySpeed = 200.0f;
const float BorderCollisionDamping = 0.4f;

const int MaxHP = 100;
const float HealthBarWidth = 40.0f;
const float HealthBarHeight = 4.0f;

const float CannonCollisionRadius = 20.0f;
const float PlayerCollisionRadius = 10.0f;

const float CannonCollisionSpeed = 200.0f;

@implementation HelloWorldLayer
{
    CGSize _winSize;
    CCSprite *_playerSprite;
    CCSprite *_cannonSprite;
    CCSprite *_turretSprite;
    
    UIAccelerationValue _accelerometerX;
    UIAccelerationValue _accelerometerY;
    
    float _playerAccelX;
    float _playerAccelY;
    float _playerSpeedX;
    float _playerSpeedY;
    
    float _playerAngle;
    float _lastAngle;
    
    int _playerHP;
    int _cannonHP;
    CCDrawNode *_playerHealthBar;
    CCDrawNode *_cannonHealthBar;
    
    float _playerSpin;
    
    CCSprite *_playerMissileSprite;
    CGPoint _touchLocation;
    CFTimeInterval _touchTime;
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
        
        _cannonSprite = [CCSprite spriteWithFile:@"Images/Cannon.png"];
        _cannonSprite.position = ccp(_winSize.width/2.0f, _winSize.height/2.0f);
        [self addChild:_cannonSprite];
        
        _turretSprite = [CCSprite spriteWithFile:@"Images/Turret.png"];
        _turretSprite.position = ccp(_winSize.width/2.0f, _winSize.height/2.0f);
        [self addChild:_turretSprite];
        
        _playerSprite = [CCSprite spriteWithFile:@"Images/Player.png"];
        _playerSprite.position = ccp(_winSize.width - 50.0f, 50.0f);
        [self addChild:_playerSprite];
        
        self.accelerometerEnabled = YES;
        [self scheduleUpdate]; //Tells cocos2d to call our update method (60fps)
        
        
        _playerHealthBar = [[CCDrawNode alloc] init];
        _playerHealthBar.contentSize = CGSizeMake(HealthBarWidth, HealthBarHeight);
        [self addChild:_playerHealthBar];
        
        _cannonHealthBar = [[CCDrawNode alloc] init];
        _playerHealthBar.contentSize = CGSizeMake(HealthBarWidth, HealthBarHeight);
        [self addChild:_cannonHealthBar];

        _cannonHealthBar.position = ccp(_cannonSprite.position.x - HealthBarWidth/2.0f + 0.5f,
                                        _cannonSprite.position.y - _cannonSprite.contentSize.height/2.0f - 10.0f + 0.5f);
        
        _playerHP = MaxHP;
        _cannonHP = MaxHP;
        
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"Sounds/Collision.wav"];
        
        
        self.touchEnabled = YES;
        
        _playerMissileSprite = [CCSprite spriteWithFile:@"Images/PlayerMissile.png"];
        _playerMissileSprite.visible = NO;
        [self addChild:_playerMissileSprite];
    }
    return self;
}

-(void)update:(ccTime)delta
{
    [self updatePlayer:delta];
    [self updateTurret:delta];
    
    [self checkCollisionOfPlayerWithCannon];
    
    [self drawHealthBar:_playerHealthBar hp:_playerHP];
    [self drawHealthBar:_cannonHealthBar hp:_cannonHP];
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
    
//    newX = MIN(_winSize.width, MAX(newX, 0));
//    newY = MIN(_winSize.height, MAX(newY, 0));
    
    BOOL collideWithVerticalBorder = NO;
    BOOL collideWithHorizontalBorder = NO;
    
    if (newX < 0.0f)
    {
        newX = 0.0f;
        collideWithVerticalBorder = YES;
    }
    else if (newX > _winSize.width)
    {
        newX = _winSize.width;
        collideWithVerticalBorder = YES;
    }
    
    if (newY < 0.0f) {
        newY = 0.0f;
        collideWithHorizontalBorder = YES;
    }
    else if (newY > _winSize.height)
    {
        newY = _winSize.height;
        collideWithHorizontalBorder = YES;
    }
    
    if (collideWithVerticalBorder) {
        _playerAccelX = -_playerAccelX * BorderCollisionDamping;
        _playerSpeedX = -_playerSpeedX * BorderCollisionDamping;
        _playerAccelY = _playerAccelY * BorderCollisionDamping;
        _playerSpeedY = _playerSpeedY * BorderCollisionDamping;
    }
    
    if (collideWithHorizontalBorder) {
        _playerAccelX = _playerAccelX * BorderCollisionDamping;
        _playerSpeedX = _playerSpeedX * BorderCollisionDamping;
        _playerAccelY = -_playerAccelY * BorderCollisionDamping;
        _playerSpeedY = -_playerSpeedY * BorderCollisionDamping;
    }
    
    
    _playerSprite.position = ccp(newX, newY);
    
    
    float speed = sqrtf(_playerSpeedX*_playerSpeedX + _playerSpeedY*_playerSpeedY);
    if (speed > 40.0f)
    {
        float angle = atan2(_playerSpeedY, _playerSpeedX);
        
        // Did the angle flip from +Pi to -Pi, or -Pi to +Pi?
        // there is something you should know about atan2f(). It does not return an angle in the convenient range of 0 to 360 degrees, but a value between +π and –π radians, or between +180 and -180 degrees to us non-mathematicians.
        // That means if you’re turning counterclockwise, at some point the angle will jump from +180 degrees to -180 degrees; or the other way around if you’re turning clockwise. And that’s where the weird spinning effect happens.
        // The problem is that when the new angle jumps from 180 degrees to -180 degrees, _playerAngle is still positive because it is trailing behind a bit. When you blend these two together, the spaceship actually starts turning the other way around. It took me a while to figure out what was causing this!
        // To fix it, you need to recognize when the angle makes that jump and adjust _playerAngle accordingly.
        if (_lastAngle < -3.0f && angle > 3.0f) {
            _playerAngle += M_PI * 2.0f;
        }
        else if (_lastAngle > 3.0f && angle < -3.0f)
        {
            _playerAngle -= M_PI * 2.0f;
        }
        _lastAngle = angle;
        
        // We blend the player's rotation so we do not get any sharp rotation clitches.
        // The _playerAngle variable combines the new angle and its own previous value by multiplying them with a blend factor. In human-speak, this means the new angle only counts for 20% towards the actual rotation that you set on the spaceship. Of course, over time more and more of the new angle gets added so that eventually the spaceship does point in the proper direction.
        const float RotationBlendFactor = 0.2f;
        _playerAngle = angle * RotationBlendFactor + _playerAngle * (1.0f - RotationBlendFactor);
    }
    
    //the sprite for the spaceship points straight up, which corresponds to the default rotation value of 0 degrees. But in mathematics, an angle of 0 degrees (or radians) doesn’t point upward, but to the right.
    //And that’s not the only problem: in Cocos2D, rotation happens in a clockwise direction, but in mathematics it goes counterclockwise.
    //This adds 90 degrees to make the sprite point to the right at an angle of 0 degrees, so that it lines up with the way atan2f() does things. Then it adds the negative angle – in other words, subtracts the angle – in order to rotate the proper way around.
    _playerSprite.rotation = 90.0f - CC_RADIANS_TO_DEGREES(_playerAngle);
    
    
    _playerHealthBar.position = ccp(_playerSprite.position.x - HealthBarWidth/2.0f + 0.5f,
                                    _playerSprite.position.y - _playerSprite.contentSize.height/2.0f - 15.0f + 0.5f);
    
    _playerSprite.rotation += _playerSpin;
    if (_playerSpin > 0.0f)
    {
        _playerSpin -= 2.0f * 360.0f * dt;
        if (_playerSpin < 0.0f)
        {
            _playerSpin = 0.0f;
        }
    }
}

-(void)updateTurret:(ccTime)dt
{
    // We are using pythagaras to calculate the rotation, therefore we need to operate on
    // the X and Y components directly. If we used vectors, like in SpaceWars, we do not need to
    // operate on the X and Y components, just using vectors.
    float deltaX = _playerSprite.position.x - _turretSprite.position.x;
    float deltaY = _playerSprite.position.y - _turretSprite.position.y;
    
    float angle = atan2f(deltaY, deltaX);
    _turretSprite.rotation = 90.0f - CC_RADIANS_TO_DEGREES(angle);
}

-(void)drawHealthBar:(CCDrawNode*)node hp:(int)hp
{
    [node clear];
    
    CGPoint verts[4];
    verts[0] = ccp(0.0f, 0.0f);
    verts[1] = ccp(0.0f, HealthBarHeight - 1.0f);
    verts[2] = ccp(HealthBarWidth - 1.0f, HealthBarHeight - 1.0f);
    verts[3] = ccp(HealthBarWidth - 1.0f, 0.0f);
    
    ccColor4F clearColor = ccc4f(0.0f, 0.0f, 0.0f, 0.0f);
    ccColor4F fillColor = ccc4f(113.0f/255.0f, 202.0f/255.0f, 53.0f/255.0f, 1.0f);
    ccColor4F borderColor = ccc4f(35.0f/255.0f, 28.0f/255.0f, 40.0f/255.0f, 1.0f);
    
    [node drawPolyWithVerts:verts count:4 fillColor:fillColor borderWidth:1.0f borderColor:borderColor];
    
    verts[0].x += 0.5f;
    verts[0].y += 0.5f;
    verts[1].x += 0.5f;
    verts[1].y -= 0.5f;
    verts[2].x = (HealthBarWidth - 2.0f)*hp/MaxHP + 0.5f;
    verts[2].y -= 0.5f;
    verts[3].x = verts[2].x;
    verts[3].y += 0.5f;
    
    [node drawPolyWithVerts:verts count:4 fillColor:fillColor borderWidth:0.0f borderColor:clearColor];
}

-(void)checkCollisionOfPlayerWithCannon
{
    float deltaX = _playerSprite.position.x - _turretSprite.position.x;
    float deltaY = _playerSprite.position.y - _turretSprite.position.y;
    
    float distance = sqrtf(deltaX*deltaX + deltaY*deltaY);
    
    if (distance <= CannonCollisionRadius + PlayerCollisionRadius)
    {
        [[SimpleAudioEngine sharedEngine] playEffect:@"Sounds/Collision.wav"];
        
        float angle = atan2(deltaY, deltaX);
        
        _playerSpeedX = cosf(angle) * CannonCollisionSpeed;
        _playerSpeedY = sinf(angle) * CannonCollisionSpeed;
        _playerAccelX = 0.0f;
        _playerAccelY = 0.0f;
        
        _playerHP = MAX(0, _playerHP - 20);
        _cannonHP = MAX(0, _cannonHP - 5);
        
        _playerSpin = 180.0f * 3.0f;
    }
}

@end
