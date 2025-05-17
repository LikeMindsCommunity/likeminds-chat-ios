import Foundation
import LikeMindsChatData

/// A manager class responsible for handling configuration operations in the SDK.
public class LMConfigurationManager {
    
    /// A shared singleton instance of `LMConfigurationManager` to manage configurations globally.
    public static let shared = LMConfigurationManager()

    // Private initializer to enforce the singleton pattern.
    private init() {}

    /**
     Saves the provided configurations to persistent storage.
     
     This method encodes the configurations into JSON and saves them in the shared preferences. 
     It also extracts and saves the `REPLY_PRIVATELY` configuration separately for easy access.
     
     - Parameters:
        - configurations: An array of `Configuration` objects to be saved.
     
     - Note: The method specifically handles the `REPLY_PRIVATELY` configuration type and stores it separately.
     */
    static func saveConfigurations(_ configurations: [Configuration]) {
        // Encode and save the entire configurations array
        if let encodedData = try? JSONEncoder().encode(configurations) {
            LMSharedPreferences.setValue(
                encodedData,
                key: LMSharedPreferencesKeys.communityConfigurations.rawValue
            )
        }

        // Extract and save the reply_privately configuration separately
        if let replyPrivatelyConfig = configurations.first(where: {
            $0.type == .replyPrivately
        }) {
            if let encodedConfig = try? JSONEncoder().encode(
                replyPrivatelyConfig)
            {
                LMSharedPreferences.setValue(
                    encodedConfig,
                    key: LMSharedPreferencesKeys.replyPrivatelyConfiguration
                        .rawValue
                )
            }
        }
    }

    /**
     Retrieves the "Reply Privately" configuration from persistent storage.
     
     This method fetches the stored reply privately configuration and decodes it from JSON.
     
     - Returns: The decoded `Configuration` object for the "Reply Privately" setting, or `nil` if it is not found.
     */
    static func getReplyPrivatelyConfiguration() -> Configuration? {
        guard
            // Retrieve stored data for the reply privately configuration
            let data = LMSharedPreferences.getData(
                forKey: .replyPrivatelyConfiguration),
            // Decode the data into a Configuration object
            let config = try? JSONDecoder().decode(
                Configuration.self, from: data)
        else {
            return nil
        }
        return config
    }
}
