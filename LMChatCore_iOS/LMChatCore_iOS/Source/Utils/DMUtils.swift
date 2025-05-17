//
//  DMUtils.swift
//  Pods
//
//  Created by Anurag Tyagi on 14/04/25.
//
import LikeMindsChatData

/// A utility class that handles Direct Message (DM) chatroom operations.
public class LMDMChatUtil {

    /// Creates a new direct message (DM) chatroom with a given user, or returns an existing one if it already exists.
    ///
    /// This function performs the following steps:
    /// 1. Checks if a DM chatroom with the given user already exists in the local database.
    /// 2. If it does not exist, it checks whether the user is eligible to create a new DM (based on DM limits set by the backend).
    /// 3. If allowed, it initiates the creation of a new DM chatroom.
    ///
    /// The function always returns either a valid `chatroomId` (as a `String`) or an `errorMessage`, via the provided completion handler.
    ///
    /// - Parameters:
    ///   - userUUID: The UUID of the user to initiate or retrieve the DM chatroom with.
    ///   - completion: A closure that returns a tuple:
    ///     - `chatroomId`: A `String?` representing the chatroom ID if found or created successfully.
    ///     - `errorMessage`: A `String?` providing an error description if the operation fails.
    ///
    /// - Note:
    ///   - If a chatroom already exists, it will be returned without hitting the server.
    ///   - If DM creation is limited or denied, the `errorMessage` will describe the reason.
    static func createOrGetExistingDMChatroom(
        userUUID: String,
        completion: @escaping (String?, String?) -> Void
    ) {
        let lmChatClient = LMChatClient.shared

        // Step 1: Check if a DM chatroom already exists locally
        let getExistingChatroomRequest = GetExistingDMChatroomRequest.builder()
            .userUUID(userUUID)
            .build()

        let getExistingDMChatroomResponse = lmChatClient.getExistingDMChatroom(
            getExisingDMChatroomRequest: getExistingChatroomRequest
        )

        if getExistingDMChatroomResponse.success {
            completion(getExistingDMChatroomResponse.data?.id, nil)
            return
        }

        // Step 2: Check if the user is within DM creation limits
        let checkDMLimitRequest = CheckDMLimitRequest.builder()
            .uuid(userUUID)
            .build()

        lmChatClient.checkDMLimit(request: checkDMLimitRequest) {
            checkDMLimitResponse in
            guard checkDMLimitResponse.success,
                let dmLimitData = checkDMLimitResponse.data
            else {
                completion(nil, checkDMLimitResponse.errorMessage)
                return
            }

            let chatroomId = dmLimitData.chatroomId
            let isRequestDMLimitExceeded = dmLimitData.isRequestDMLimitExceeded

            if let chatroomId = chatroomId {
                // Step 2a: A chatroom was returned from the server (previously created)
                completion("\(chatroomId)", nil)
            } else if isRequestDMLimitExceeded == false {
                // Step 3: User is allowed to create a new DM chatroom
                let createDMChatroomRequest = CreateDMChatroomRequest.builder()
                    .uuid(userUUID)
                    .build()

                lmChatClient.createDMChatroom(request: createDMChatroomRequest)
                { createDMChatroomResponse in
                    if createDMChatroomResponse.success {
                        completion(
                            createDMChatroomResponse.data?.chatroomData?.id, nil
                        )
                    } else {
                        completion(nil, createDMChatroomResponse.errorMessage)
                    }
                }
            } else {
                // Step 4: DM creation is not allowed due to exceeded limit
                completion(nil, "DM Limit Exceeded")
            }
        }
    }

    /// Updates the DM request settings in shared preferences.
    /// This method is typically called when community settings are fetched or updated.
    ///
    /// - Parameter isEnabled: A boolean value indicating whether DM requests are enabled.
    ///                       If true, users can send DM requests without requiring a connection.
    ///                       If false, connection requests are required before sending DMs.
    public static func updateDMRequestSettings(isEnabled: Bool) {
        LMSharedPreferences.setValue(
            isEnabled,
            key: LMSharedPreferencesKeys.isDMWithRequestEnabled.rawValue
        )
    }

    /// Retrieves the current DM request settings from shared preferences.
    ///
    /// - Returns: A boolean value indicating whether DM requests are enabled.
    ///           Returns false if the setting is not found.
    public static func isDMRequestEnabled() -> Bool {
        return LMSharedPreferences.bool(
            forKey: LMSharedPreferencesKeys.isDMWithRequestEnabled.rawValue
        ) ?? false
    }
}
