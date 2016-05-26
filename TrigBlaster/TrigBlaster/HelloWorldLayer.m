#import "HelloWorldLayer.h"
#import "SimpleAudioEngine.h"

@implementation HelloWorldLayer

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
    }
    return self;
}

@end
