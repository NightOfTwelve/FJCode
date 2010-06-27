//
//  TwitterEngineController.m
//  socialpass
//
//  Created by Corey Floyd on 6/26/10.
//  Copyright 2010 Flying Jalapeño Software. All rights reserved.
//

#import "TwitterEngineController.h"
#import "MGTwitterEngine.h"

@interface TwitterEngineController()

@property (nonatomic, retain) MGTwitterEngine *twitterEngine;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, retain) NSString *XAuthFetchID;


@end


@implementation TwitterEngineController

@synthesize twitterEngine;
@synthesize XAuthFetchID;
@synthesize username;
@synthesize password;
@synthesize delegate;

SYNTHESIZE_SINGLETON_FOR_CLASS(TwitterEngineController);



- (void) dealloc
{
    
    delegate = nil;
    
    [username release];
    username = nil;
    
    [password release];
    password = nil;
    
    [XAuthFetchID release];
    XAuthFetchID = nil;
    
    [twitterEngine release];
    twitterEngine = nil;
    
    [super dealloc];
}




- (id) init
{
    self = [super init];
    if (self != nil) {
        
        self.twitterEngine = [MGTwitterEngine twitterEngineWithDelegate:self];
        [self.twitterEngine setConsumerKey:kTwitterOAuthConsumerKey secret:kTwitterOAuthConsumerSecret];
        
        self.username = [[NSUserDefaults standardUserDefaults] objectForKey:kTwitterNameKey];
        
        OAToken* token = [[OAToken alloc] initWithUserDefaultsUsingServiceProviderName:kTwitterProvider prefix:kTwitterPrefix];
        
        [self.twitterEngine setAccessToken:token];
        
        [token release];
        
    }
    return self;
}

- (BOOL)loggedIn{
    
    if([self.twitterEngine accessToken] != nil)
        return YES;
    
    return NO;
}

- (BOOL)loginWithUserName:(NSString*)name password:(NSString*)pwd{
    
    if(name == nil || pwd == nil)
        return NO;
    
    self.username = name;
    self.password = pwd;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject: nil forKey:kTwitterNameKey];
    [OAToken removeFromUserDefaultsWithServiceProviderName:kTwitterProvider prefix:kTwitterPrefix];
    
    [defaults synchronize];
        
    self.XAuthFetchID = [self.twitterEngine getXAuthAccessTokenForUsername:self.username password:self.password];
    
    if(self.XAuthFetchID != nil)
        return YES;
    
    return NO;
    
}


- (BOOL)getFollowers{
    
    if(self.loggedIn == NO)
        return NO;
    
    if([self.twitterEngine getFollowerIDsFor:self.username startingFromCursor:-1])
        return YES;
    
    return NO;
    
    
}
- (BOOL)getFollowing{
    
    if(self.loggedIn == NO)
        return NO;
    
    if([self.twitterEngine getFriendIDsFor:self.username startingFromCursor:-1])
        return YES;
    
    return NO;
    
}


#pragma mark -
#pragma mark MGTwitterEngineDelegate

- (void)accessTokenReceived:(OAToken *)aToken forRequest:(NSString *)connectionIdentifier{
    
    self.XAuthFetchID = nil;
    
    [aToken storeInUserDefaultsWithServiceProviderName:kTwitterProvider prefix:kTwitterPrefix];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults setObject:username forKey:kTwitterNameKey];
	
	[defaults synchronize];
    
    if([delegate respondsToSelector:@selector(twitterEngineController:didLogin:error:)])
        [delegate twitterEngineController:self didLogin:YES error:nil];

    
    
}


- (void)requestSucceeded:(NSString *)connectionIdentifier{
    
    NSLog(@"yeah!");
    
	//TODO: display results!
}


- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error{
	
    NSLog(@"neah!");
    
    if(connectionIdentifier == self.XAuthFetchID){
        
        self.XAuthFetchID = nil;
                
        
        if([delegate respondsToSelector:@selector(twitterEngineController:didLogin:error:)])
            [delegate twitterEngineController:self didLogin:NO error:error];
    
        //TODO: display we are fucked!
        //[error presentAlertViewWithDelegate:nil];	
        
    }else{
        

        if([delegate respondsToSelector:@selector(twitterEngineController:didFetchFollowing:error:)])
            [delegate twitterEngineController:self didFetchFollowing:nil error:error];

        
    }
}

- (void)socialGraphInfoReceived:(NSArray *)socialGraphInfo forRequest:(NSString *)connectionIdentifier{
    
    NSLog(@"super yeah! %@", [socialGraphInfo description]);
    
    if([delegate respondsToSelector:@selector(twitterEngineController:didFetchFollowing:error:)])
       [delegate twitterEngineController:self didFetchFollowing:socialGraphInfo error:nil];
    
}



@end