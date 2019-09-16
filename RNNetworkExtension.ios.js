'use strict';
import { 
    NativeModules,
    NativeEventEmitter    
 } from 'react-native';

const NativeRNNetworkExtension = NativeModules.RNNetworkExtension;
const eventEmitter = new NativeEventEmitter(NativeRNNetworkExtension);

export default {
    connect(options) {
        return NativeRNNetworkExtension.connect(options);
    },

    disconnect() {
        return NativeRNNetworkExtension.disconnect();
    },

    addEventListener(event, listener) {
        console.log('adding event: ', event)

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
        console.log('removing event: ', event)

        if (event === 'status') {
            return eventEmitter.removeListener('VPNStatus', listener);
        } else if (event === 'fail') {
            return eventEmitter.removeListener('VPNStartFail', listener);
        }
    }
};
