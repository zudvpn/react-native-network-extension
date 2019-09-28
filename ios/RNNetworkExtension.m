
#import "RNNetworkExtension.h"

#import <NetworkExtension/NEVPNManager.h>
#import <NetworkExtension/NEVPNConnection.h>
#import <NetworkExtension/NEVPNProtocolIKEv2.h>
#import <React/RCTBridgeModule.h>

@interface RNNetworkExtension()

@property (strong, nonatomic, nonnull) NEVPNManager *vpnManager;

@end

@implementation RNNetworkExtension
{
    bool hasListeners;
}

RCT_EXPORT_MODULE()

-(dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

+(id)sharedManager {
    static RNNetworkExtension *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });

    return sharedManager;
}

-(id)init
{
    if (self = [super init]) {
        [self bootstrap];
    }

    return self;
}

-(void)bootstrap
{
    self.vpnManager = [NEVPNManager sharedManager];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    [nc removeObserver:self
                  name:NEVPNStatusDidChangeNotification
                object:nil];

    [nc addObserver:self
           selector:@selector(vpnStatusDidChange:)
               name:NEVPNStatusDidChangeNotification
             object:nil];
    
    NSLog(@"RNNetworkExtension bootstrapped");
}

-(void)startObserving
{
    hasListeners = YES;
}

-(void)stopObserving
{
    hasListeners = NO;
}

-(NSArray<NSString *> *)supportedEvents
{
  return @[@"VPNStatus", @"VPNStartFail"];
}

RCT_EXPORT_METHOD(connect:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"connect triggered");

    [_vpnManager loadFromPreferencesWithCompletionHandler:^(NSError *error) {
        if (error) {
            NSLog(@"vpn load error: %@", error.localizedDescription);

            reject(@"vpn_load_error", @"VPN Manager load error", error);
            
            return;
        }

        [self startConnecting:resolve rejecter:reject];
    }];
}

RCT_EXPORT_METHOD(disconnect)
{
    [_vpnManager.connection stopVPNTunnel];
}

RCT_EXPORT_METHOD(remove:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSLog(@"removing vpn profile");

    [_vpnManager removeFromPreferencesWithCompletionHandler:^(NSError *error) {
        if (error) {
            NSLog(@"vpn remove error: %@", error.localizedDescription);

            reject(@"vpn_remove_error", @"VPN Manager remove error", error);

            return;
        }

        resolve(@YES);
    }];
}

RCT_EXPORT_METHOD(configure:(NSDictionary *)args resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(vpnConfigDidChange:)
               name:NEVPNConfigurationChangeNotification
             object:nil];

    NSLog(@"install triggered");
    [self installProfile:args resolver:resolve rejecter:reject];
}

-(void)installProfile:(NSDictionary *)args resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject
{
    NSLog(@"install profile");
    
    [_vpnManager loadFromPreferencesWithCompletionHandler:^(NSError *error) {
        if (error) {
            reject(@"vpn_load_error", @"VPN Manager load error", error);
            
            NSLog(@"vpn load error: %@", error.localizedDescription);
            
            return;
        }

        NEVPNProtocolIKEv2 *p = (NEVPNProtocolIKEv2 *)_vpnManager.protocolConfiguration;

        if (!p) {
            p = [[NEVPNProtocolIKEv2 alloc] init];
        }

        [self addToKeychain:args[@"username"] withPassword:args[@"password"]];

        NSString *passwordReference = [self readFromKeychain:args[@"username"]];

        NSLog(@"Password Referenced %@", passwordReference);

        p.serverAddress = args[@"domain"];
        p.authenticationMethod = NEVPNIKEAuthenticationMethodNone;
        p.username = args[@"username"];
        p.passwordReference = passwordReference;
        // p.identityData = [[NSData alloc] initWithBase64EncodedString:args[@"clientCert"] options:0];
        // p.identityDataPassword = args[@"clientCertKey"];

        p.childSecurityAssociationParameters.diffieHellmanGroup = NEVPNIKEv2DiffieHellmanGroup19;
        p.childSecurityAssociationParameters.encryptionAlgorithm = NEVPNIKEv2EncryptionAlgorithmAES128GCM;
        p.childSecurityAssociationParameters.integrityAlgorithm = NEVPNIKEv2IntegrityAlgorithmSHA512;
        p.childSecurityAssociationParameters.lifetimeMinutes = 20;

        p.IKESecurityAssociationParameters.diffieHellmanGroup = NEVPNIKEv2DiffieHellmanGroup19;
        p.IKESecurityAssociationParameters.encryptionAlgorithm = NEVPNIKEv2EncryptionAlgorithmAES128GCM;
        p.IKESecurityAssociationParameters.integrityAlgorithm = NEVPNIKEv2IntegrityAlgorithmSHA512;
        p.IKESecurityAssociationParameters.lifetimeMinutes = 20;
        
        p.disableMOBIKE = NO;
        p.disableRedirect = YES;
        p.enableRevocationCheck = NO;
        p.enablePFS = YES;
        p.useConfigurationAttributeInternalIPSubnet = NO;
        // p.certificateType = NEVPNIKEv2CertificateTypeECDSA256;
        // p.serverCertificateCommonName = args[@"domain"];
        // p.serverCertificateIssuerCommonName = args[@"domain"];

        p.localIdentifier = args[@"domain"];
        p.remoteIdentifier = args[@"domain"];

        p.useExtendedAuthentication = YES;
        p.disconnectOnSleep = NO;

        _vpnManager.protocolConfiguration = p;
        _vpnManager.localizedDescription = args[@"domain"];
        _vpnManager.enabled = YES;

        [_vpnManager saveToPreferencesWithCompletionHandler:^(NSError *error) {
            if (error) {
                reject(@"vpn_save_error", @"VPN Manager save error", error);
                
                NSLog(@"vpn save error: %@", error.localizedDescription);
                
                return;
            }

            resolve(@YES);
        }];
    }];
}

-(NSMutableDictionary *)keychainQueryForKey:(NSString *)key {
    return [@{(__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
              (__bridge id)kSecAttrGeneric: key,
              (__bridge id)kSecAttrService: key,
              (__bridge id)kSecAttrAccount: key,
              (__bridge id)kSecAttrAccessible: (__bridge id)kSecAttrAccessibleAlways
              } mutableCopy];
}

-(void)addToKeychain:(NSString*)username withPassword:(NSString*)password
{
    OSStatus sts = SecItemDelete((__bridge CFDictionaryRef)[self keychainQueryForKey:username]);
    NSLog(@"SecItemDelete Error Code: %d", (int)sts);

    NSMutableDictionary *keychainQuery = [self keychainQueryForKey:username];

    [keychainQuery setObject:[password dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];

    sts = SecItemAdd((__bridge CFDictionaryRef)keychainQuery, nil);
    NSLog(@"SecItemAdd Error Code: %d", (int)sts);
}

-(NSData*)readFromKeychain:(NSString*)username
{
    NSMutableDictionary *keychainQuery = [self keychainQueryForKey:username];
    [keychainQuery setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnPersistentRef];
    [keychainQuery setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];

    CFTypeRef keyData = NULL;

    OSStatus sts = SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, &keyData);

    NSLog(@"SecItemCopyMatching Error Code: %d", (int)sts);

    return (__bridge NSData *)keyData;
}

-(void)vpnConfigDidChange:(NSNotification *)notification
{
    // TODO: Save configuration failed
    [self startConnecting:nil rejecter:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NEVPNConfigurationChangeNotification
                                                  object:nil];
}

-(void)startConnecting:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject
{
    NSLog(@"start connecting");
    
    NSError *error;
    [_vpnManager.connection startVPNTunnelAndReturnError:&error];

    if (error) {
        if (hasListeners) {
            [self sendEventWithName:@"VPNStartFail" body:error.localizedDescription];
        }
        
        NSLog(@"Start VPN failed: [%@]", error.localizedDescription);

        if (reject) {
            reject(@"vpn_start_error", @"VPN Manager start error", error);
        }

        return;
    }

    if (resolve) {
        resolve(@YES);
    }
}

-(void)vpnStatusDidChange:(NSNotification *)notification
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
    
    NSLog(@"VPN status changed %@", statusDescription);

    if (hasListeners) {
        [self sendEventWithName:@"VPNStatus" body:statusDescription];
    }
}

@end
  
