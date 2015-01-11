//
//  ViewController.m
//  CarLuck
//
//  Created by Sheng Wu on 1/10/15.
//

#import "ViewController.h"
#import "NSObject_CarState.h"
#import <AVFoundation/AVFoundation.h>
#import <RestKit/RestKit.h>
#import <Wit/Wit.h>

@interface ViewController ()

@end

@implementation ViewController

// Class members
// =============

// debugging
UILabel *labelView;
UITextView *entitiesView;
BOOL debug = TRUE;

// prod
UILabel *statusView;

// FUN HACKATHON GLOBAL STATE MEGACLASS
//TODO_TYPE currentOffer;
BOOL offerMade = FALSE;
// prevCarState;
// currCarState;
AVSpeechSynthesizer *synthesizer;



// Wit.ai callbacks
// ================

- (void)witDidGraspIntent:(NSArray *)outcomes messageId:(NSString *)messageId customData:(id) customData error:(NSError*)e {
    if (e) {
        NSLog(@"[Wit] error: %@", [e localizedDescription]);
        return;
    }
    NSDictionary *firstOutcome = [outcomes objectAtIndex:0];
    
    // Update debugging UI elements
    if (debug) {
        NSString *intent = firstOutcome[@"intent"];
        labelView.text = [NSString stringWithFormat:@"intent = %@", intent];
      
        NSData *json;
        NSError *error = nil;
        if ([NSJSONSerialization isValidJSONObject:outcomes])
        {
            entitiesView.textAlignment = NSTextAlignmentLeft;
            // Serialize the dictionary
            json = [NSJSONSerialization dataWithJSONObject:outcomes options:NSJSONWritingPrettyPrinted error:&error];
            
            // If no errors, let's view the JSON
            if (json != nil && error == nil)
            {
                NSString *jsonString = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
                
                NSLog(@"JSON: %@", jsonString);
                entitiesView.text = jsonString;
            }
        }
    }
    
    // Act in response to an intent, if after an offer
    
}



// API functions
// =============

// BMW Car API
NSString *carStateString = @"http://data.api.hackthedrive.com:80/v1/Vehicles/23ea9f81-028b-4137-b56b-741a57c65958";
NSURL *carStateUrl;
NSString *apiToken = @"50e32f0b-de91-456a-a066-72f9517d046d";

-(void)fetchCarState {
    //@"MojioAPIToken"
}

-(void)updateFromNewState {
    
}

// Offers APIs
-(void) getOffers {
    
}



// Text-to-speech
// ==============

- (void)say:(NSString *)phrase :(float)rate {
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:phrase];
    [utterance setRate:rate];
    [synthesizer speakUtterance:utterance];
}

- (void)say:(NSString *)phrase {
    [self say:phrase:.05f];
}

// Asks user if he/she wants to redeem an offer
- (void)sayOffer:(NSString *)offerTitle :(int)distMiles {
    NSString *isPlural = @"";
    if (distMiles > 1) {
        isPlural = @"s";
    }
    [self say:[NSString stringWithFormat:@"%@ in %d mile%@. Want to go?", offerTitle, distMiles, isPlural]:.12f];
}

-(void) stopListening {
    [[Wit sharedInstance] stop];
}

// called when ios is done speaking
-(void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    // CALLBACK: now listen for and act on user's response
    offerMade = TRUE;
    [[Wit sharedInstance] start];
    
    // give user a little time to respond yes or no
    NSTimer *userResponseTimer = [NSTimer timerWithTimeInterval:1
                                                      target:self
                                                    selector:@selector(stopListening)
                                                    userInfo:nil
                                                     repeats:FALSE];
    NSRunLoop *loop = [NSRunLoop currentRunLoop];
    [loop addTimer:userResponseTimer forMode:NSDefaultRunLoopMode];
}

- (void)testMakeOffer {
    // stop previous
    offerMade = FALSE;
    [[Wit sharedInstance] stop];

    // Tell user what's up
    [self sayOffer:@"Chipotle burritos 40% off":3];
}





// View class
// ==========

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // handle speech events using this class
    synthesizer = [[AVSpeechSynthesizer alloc]init];
    synthesizer.delegate = self;
    
    // make urls, set up restkit
    carStateUrl = [NSURL URLWithString:carStateString];
    [[[RKObjectManager sharedManager] HTTPClient] setDefaultHeader:@"MojioAPIToken" value:apiToken];
    
    // Welcome the user!
    [self say:@"Welcome to Drive Luck. Begin driving when you're ready."];
    
    // set the WitDelegate object
    [Wit sharedInstance].delegate = self;
    
    // create the WitAI button
    CGRect screen = [UIScreen mainScreen].bounds;
    CGFloat w = 100;
    CGRect rect = CGRectMake(screen.size.width/2 - w/2, 60, w, 100);
    
    WITMicButton* witButton = [[WITMicButton alloc] initWithFrame:rect];
    [self.view addSubview:witButton];
    [[Wit sharedInstance] stop];
    
    // set up debugging UI elements
    if (debug) {
        // create the label
        labelView = [[UILabel alloc] initWithFrame:CGRectMake(0, 200, screen.size.width, 50)];
        labelView.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:labelView];
        
        // and one for entities
        entitiesView = [[UITextView alloc] initWithFrame:CGRectMake(0, 250, screen.size.width, screen.size.height - 300)];
        [self.view addSubview:entitiesView];
        entitiesView.textAlignment = NSTextAlignmentCenter;
        entitiesView.text = @"Entities will show up here";
        entitiesView.editable = NO;
        entitiesView.font = [UIFont systemFontOfSize:17];
    } else {
        // display status
        statusView = [[UILabel alloc] initWithFrame:CGRectMake(0, 200, screen.size.width, 50)];
        statusView.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:statusView];
    }
    
    // Set up timers
    NSTimer *carUpdateTimer = [NSTimer timerWithTimeInterval:10.0
                                                      target:self
                                                    selector:@selector(testMakeOffer)
                                                    userInfo:nil
                                                     repeats:TRUE];
    
    // Add them to run loop
    NSRunLoop *loop = [NSRunLoop currentRunLoop];
    [loop addTimer:carUpdateTimer forMode:NSDefaultRunLoopMode];
    //[loop run];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
