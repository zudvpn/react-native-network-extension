'use strict';

export default {
    connect() {
        return Promise.reject(new Error('RNNetworkExtension is unavailable on Android'));
    },

    disconnect() {
        return Promise.reject(new Error('RNNetworkExtension is unavailable on Android'));
    },

    addEventListener(event, listener) {
        return Promise.reject(new Error('RNNetworkExtension is unavailable on Android'));
    },

    removeEventListener(event, listener) {
        return Promise.reject(new Error('RNNetworkExtension is unavailable on Android'));
    }
};