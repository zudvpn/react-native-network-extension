
#import "RNNetworkExtension.h"

#import <NetworkExtension/NEVPNManager.h>
#import <NetworkExtension/NEVPNConnection.h>
#import <NetworkExtension/NEVPNProtocolIKEv2.h>

@interface RNNetworkExtension()

@property (strong, nonatomic) NEVPNManager *vpnManager;

@end

@implementation RNNetworkExtension
{
    bool hasListeners;
}

RCT_EXPORT_MODULE()

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

+ (void)bootstrap
{
    NEVPNManager *vpnManager = [NEVPNManager sharedManager];

    [[RNNetworkExtension sharedInstance] setVpnManager:vpnManager];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(vpnStatusDidChange:)
               name:NEVPNStatusDidChangeNotification
             object:nil];
}

+ (instancetype)sharedInstance
{
    static RNNetworkExtension *instance = nil;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        if (instance == nil) {
            instance = [[RNNetworkExtension alloc] init];
        }
    });

    return instance;
}

+ (void)setVpnManager:(NEVPNManager *)vpnManager
{
    self.vpnManager = vpnManager;
}

- (void)startObserving
{
    hasListeners = YES;
}

- (void)stopObserving
{
    hasListeners = NO;
}

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"VPNStatus", @"VPNStartFail"];
}

RCT_EXPORT_METHOD(networkExtensionConnect:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    [self installProfile:resolve rejecter:reject];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(vpnConfigDidChange:)
               name:NEVPNConfigurationChangeNotification
             object:nil];
}

RCT_EXPORT_METHOD(networkExtensionDisconnect)
{
    [_vpnManager.connection stopVPNTunnel];
}

-(void)installProfile:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject
{
    self.vpnManager = [NEVPNManager sharedManager];

    [_vpnManager loadFromPreferencesWithCompletionHandler:^(NSError *error) {
        if (error) {
            reject(@"vpn_load_error", @"VPN Manager load error", error);
            return;
        }

        NEVPNProtocolIKEv2 *p = (NEVPNProtocolIKEv2 *)_vpnManager.protocolConfiguration;

        if (p) {

        } else {
            p = [[NEVPNProtocolIKEv2 alloc] init];
        }

        p.useExtendedAuthentication = YES;
        p.disconnectOnSleep = NO;

        _vpnManager.protocolConfiguration = p;
        _vpnManager.localizedDescription = @"AnyVPN";
        _vpnManager.enabled = YES;

        [_vpnManager saveToPreferencesWithCompletionHandler:^(NSError *error) {
            if (error) {
                reject(@"vpn_save_error", @"VPN Manager save error", error);
                return;
            }
        }];
    }];

    resolve(@YES);
}

- (void)vpnConfigDidChange:(NSNotification *)notification
{
    // TODO: Save configuration failed
    [self startConnecting];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NEVPNConfigurationChangeNotification
                                                  object:nil];
}

- (void)startConnecting
{
    NSError *startError;
    [_vpnManager.connection startVPNTunnelAndReturnError:&startError];
    if (startError) {
        if (hasListeners) {
            [self sendEventWithName:@"VPNStartFail" body:startError.localizedDescription];
        }
        
        NSLog(@"Start VPN failed: [%@]", startError.localizedDescription);
    }
}

- (void)vpnStatusDidChange:(NSNotification *)notification
{
    NEVPNStatus status = _vpnManager.connection.status;
    NSString *statusDescription = nil;

    switch (status) {
        case NEVPNStatusConnected:
            statusDescription = @"Connected";
            break;
        case NEVPNStatusInvalid:
        case NEVPNStatusDisconnected:
            statusDescription = @"Disconnected";
            break;
        case NEVPNStatusConnecting:
        case NEVPNStatusReasserting:
            statusDescription = @"Connecting";
            break;
        case NEVPNStatusDisconnecting:
            statusDescription = @"Disconnecting";
            break;
        default:
            break;
    }

    if (hasListeners) {
        [self sendEventWithName:@"VPNStatus" body:statusDescription];
    }
}

@end
  