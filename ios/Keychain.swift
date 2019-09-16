import Foundation
import Security

@objc class Keychain {
	@objc func persistentRef(key: String) -> NSData? {
		let query: [NSObject: AnyObject] = [
			kSecClass: kSecClassGenericPassword,
			kSecAttrGeneric: key,
			kSecAttrAccount: key,
			kSecAttrAccessible: kSecAttrAccessibleAlways,
			kSecMatchLimit: kSecMatchLimitOne,
			kSecAttrService: NSBundle.mainBundle().bundleIdentifier!,
			kSecReturnPersistentRef: kCFBooleanTrue
		]
		
		var secItem: AnyObject?
		let result = SecItemCopyMatching(query, &secItem)
		if result != errSecSuccess {
			return nil
		}
		
		return secItem as? NSData
	}

	@objc func set(key: String, value: String) {
		
		let query: [NSObject: AnyObject] = [
			kSecValueData: value.dataUsingEncoding(NSUTF8StringEncoding)!,
			kSecClass: kSecClassGenericPassword,
			kSecAttrGeneric: key,
			kSecAttrAccount: key,
			kSecAttrAccessible: kSecAttrAccessibleAlways,
			kSecAttrService: NSBundle.mainBundle().bundleIdentifier!
		]

		clear(key)
		SecItemAdd(query as CFDictionaryRef, nil)
	}

	@objc func clear(key: String) {
		let query: [NSObject: AnyObject] = [
			kSecClass: kSecClassGenericPassword,
			kSecAttrAccount: key
		]
		SecItemDelete(query as CFDictionaryRef)
	}
}