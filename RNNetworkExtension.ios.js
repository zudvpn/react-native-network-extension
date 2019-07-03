'use strict';
import { 
    NativeModules,
    NativeEventEmitter    
 } from 'react-native';

const { RNNetworkExtension } = NativeModules;
const eventEmitter = new NativeEventEmitter(RNNetworkExtension);

export default {
    connect() {
        return RNNetworkExtension.networkExtensionConnect();
    },

    disconnect() {
        return RNNetworkExtension.networkExtensionDisconnect();
    },

    addEventListener(event, listener) {
        if (event === 'status') {
            return eventEmitter.addListener('VPNStatus', listener);
        } else if (event === 'fail') {
            return eventEmitter.addListener('VPNStartFail', listener);
        } else {
            console.warn(`Trying to subscribe to an unknown event: ${event}`);
            return {
                remove: () => {}
            };
        }
    },

    removeEventListener(event, listener) {
        if (event === 'status') {
            return eventEmitter.removeListener('VPNStatus', listener);
        } else if (event === 'fail') {
            return eventEmitter.removeListener('VPNStartFail', listener);
        }
    }
};
