import Foundation
import Security

@objc class Keychain : NSObject {
	func persistentRef(key: String) -> NSData? {
		let query: [NSObject: AnyObject] = [
			kSecClass: kSecClassGenericPassword,
			kSecAttrGeneric: key as AnyObject,
			kSecAttrAccount: key as AnyObject,
			kSecAttrAccessible: kSecAttrAccessibleAlways,
			kSecMatchLimit: kSecMatchLimitOne,
            kSecAttrService: Bundle.main.bundleIdentifier! as AnyObject,
			kSecReturnPersistentRef: kCFBooleanTrue
		]
		
		var secItem: AnyObject?
		let result = SecItemCopyMatching(query as CFDictionary, &secItem)
		if result != errSecSuccess {
			return nil
		}
		
		return secItem as? NSData
	}

	func set(key: String, value: String) {
		
		let query: [NSObject: AnyObject] = [
            kSecValueData: value.data(using: String.Encoding.utf8)! as AnyObject,
			kSecClass: kSecClassGenericPassword,
            kSecAttrGeneric: key as AnyObject,
            kSecAttrAccount: key as AnyObject,
			kSecAttrAccessible: kSecAttrAccessibleAlways,
            kSecAttrService: Bundle.main.bundleIdentifier! as AnyObject
		]

		clear(key: key)
		SecItemAdd(query as CFDictionary, nil)
	}

	func clear(key: String) {
		let query: [NSObject: AnyObject] = [
			kSecClass: kSecClassGenericPassword,
			kSecAttrAccount: key as AnyObject
		]
		SecItemDelete(query as CFDictionary)
	}
}
