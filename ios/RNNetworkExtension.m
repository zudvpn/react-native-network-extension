
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

RCT_EXPORT_METHOD(connect)
{
    NSLog(@"connect triggered");

    [_vpnManager loadFromPreferencesWithCompletionHandler:^(NSError *error) {
        if (error) {
            NSLog(@"vpn load error: %@", error.localizedDescription);
            
            return;
        }

        [self startConnecting];
    }];
}

RCT_EXPORT_METHOD(disconnect)
{
    [_vpnManager.connection stopVPNTunnel];
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

        NSString *passwordReference = [self addVPNCredentialsToKeychain:args[@"username"] withPassword:args[@"password"]];

        NSLog(@"Password Referenced %@", passwordReference);

        p.serverAddress = args[@"domain"];
        p.authenticationMethod = NEVPNIKEAuthenticationMethodCertificate;
        p.username = args[@"username"];
        p.passwordReference = passwordReference;
        // p.identityData = [[NSData alloc] initWithBase64EncodedString:args[@"clientCert"] options:0];
        // p.identityDataPassword = args[@"clientCertKey"];

        // p.childSecurityAssociationParameters.diffieHellmanGroup = NEVPNIKEv2DiffieHellmanGroup19;
        // p.childSecurityAssociationParameters.encryptionAlgorithm = NEVPNIKEv2EncryptionAlgorithmAES128GCM;
        // p.childSecurityAssociationParameters.integrityAlgorithm = NEVPNIKEv2IntegrityAlgorithmSHA512;
        // p.childSecurityAssociationParameters.lifetimeMinutes = 20;

        // p.IKESecurityAssociationParameters.diffieHellmanGroup = NEVPNIKEv2DiffieHellmanGroup19;
        // p.IKESecurityAssociationParameters.encryptionAlgorithm = NEVPNIKEv2EncryptionAlgorithmAES128GCM;
        // p.IKESecurityAssociationParameters.integrityAlgorithm = NEVPNIKEv2IntegrityAlgorithmSHA512;
        // p.IKESecurityAssociationParameters.lifetimeMinutes = 20;
        
        p.disableMOBIKE = NO;
        p.disableRedirect = YES;
        p.enableRevocationCheck = NO;
        p.enablePFS = YES;
        p.useConfigurationAttributeInternalIPSubnet = NO;
        // p.certificateType = NEVPNIKEv2CertificateTypeECDSA256;
        // p.serverCertificateCommonName = args[@"IPAddress"];
        // p.serverCertificateIssuerCommonName = args[@"IPAddress"];

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

-(NSData*)addVPNCredentialsToKeychain:(NSString*)username withPassword:(NSString*)password
{
    NSMutableDictionary *keychainItem = [NSMutableDictionary dictionary];

    NSData *encodedIdentifier = [username dataUsingEncoding:NSUTF8StringEncoding];

    keychainItem[(__bridge id)kSecClass] = (__bridge id)kSecClassGenericPassword;
    keychainItem[(__bridge id)kSecAttrDescription] = @"A password used to authenticate on a ZudVPN server";
    keychainItem[(__bridge id)kSecAttrGeneric] = encodedIdentifier;
    keychainItem[(__bridge id)kSecAttrAccount] = encodedIdentifier;
    keychainItem[(__bridge id)kSecAttrService] = [[NSBundle mainBundle] bundleIdentifier];
    keychainItem[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    keychainItem[(__bridge id)kSecReturnPersistentRef] = @YES;

    CFTypeRef typeResult = nil;

    OSStatus sts = SecItemCopyMatching((__bridge CFDictionaryRef)keychainItem, &typeResult);

    NSLog(@"SetItemCopyMatching Error Code: %d", (int)sts);

    if (sts == noErr) {
        NSData *theReference = (__bridge NSData *)typeResult;
        return theReference;
    } else {
        keychainItem[(__bridge id)kSecValueData] = [password dataUsingEncoding:NSUTF8StringEncoding];

        OSStatus sts = SecItemAdd((__bridge CFDictionaryRef)keychainItem, &typeResult);
        NSLog(@"SecItemAdd Error Code: %d", (int)sts);

        NSData *theReference = (__bridge NSData *)(typeResult);
        return theReference;
    }

    return nil;
}

-(void)vpnConfigDidChange:(NSNotification *)notification
{
    // TODO: Save configuration failed
    [self startConnecting];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NEVPNConfigurationChangeNotification
                                                  object:nil];
}

-(void)startConnecting
{
    NSLog(@"start connecting");
    
    NSError *error;
    [_vpnManager.connection startVPNTunnelAndReturnError:&error];

    if (error) {
        if (hasListeners) {
            [self sendEventWithName:@"VPNStartFail" body:error.localizedDescription];
        }
        
        NSLog(@"Start VPN failed: [%@]", error.localizedDescription);
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
  
