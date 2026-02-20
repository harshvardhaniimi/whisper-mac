import Foundation

enum AppBrand {
    static var displayName: String {
        if let value = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
           !value.isEmpty {
            return value
        }

        if let value = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String,
           !value.isEmpty {
            return value
        }

        return "Kalam"
    }

    static var appSupportDirectoryName: String {
        if let bundleName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String,
           !bundleName.isEmpty {
            return bundleName.replacingOccurrences(of: "/", with: "-")
        }

        if let bundleID = Bundle.main.bundleIdentifier, !bundleID.isEmpty {
            return bundleID.replacingOccurrences(of: "/", with: "-")
        }

        // Keep this filesystem-safe enough for common names.
        return displayName.replacingOccurrences(of: "/", with: "-")
    }
}
