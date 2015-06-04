//
//  MCCReachability.h
//  Tealeaves
//
//  Created by Scott Little on 04/06/15.
//  Copyright (c) 2015 Little Known Software. All rights reserved.
//

#import "MCCCommonHeader.h"


#pragma mark - Readability Mappings

//	From Reachability.h
#define	kReachabilityChangedNotification	MCC_PREFIXED_CONSTANT(ReachabilityChangedNotification)
#define	NotReachable						MCC_PREFIXED_NAME(NotReachable)
#define	ReachableViaWiFi					MCC_PREFIXED_NAME(ReachableViaWiFi)
#define	ReachableViaWWAN					MCC_PREFIXED_NAME(ReachableViaWWAN)
#define	NetworkStatus						MCC_PREFIXED_NAME(NetworkStatus)

#define	NetworkReachable					MCC_PREFIXED_NAME(NetworkReachable)
#define	NetworkUnreachable					MCC_PREFIXED_NAME(NetworkUnreachable)
#define	Reachability						MCC_PREFIXED_NAME(Reachability)

//	From Reachability.m (static methods)
#define	reachabilityFlags					MCC_PREFIXED_NAME(reachabilityFlags)
#define	TMReachabilityCallback				MCC_PREFIXED_NAME(TMReachabilityCallback)
