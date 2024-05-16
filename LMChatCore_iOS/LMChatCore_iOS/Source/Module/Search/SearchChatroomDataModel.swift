//
//  SearchChatroomDataModel.swift
//  LMChatCore_iOS
//
//  Created by Devansh Mohata on 02/05/24.
//

public struct SearchChatroomDataModel {
    let id: String
    let chatroomTitle: String
    let chatroomImage: String?
    let isFollowed: Bool
    let title: String?
    let createdAt: Double
    let user: SearchListUserDataModel
    
    public init(id: String, chatroomTitle: String, chatroomImage: String?, isFollowed: Bool, title: String?, createdAt: Double, user: SearchListUserDataModel) {
        self.id = id
        self.chatroomTitle = chatroomTitle
        self.chatroomImage = chatroomImage
        self.isFollowed = isFollowed
        self.title = title
        self.createdAt = createdAt
        self.user = user
    }
}


public struct SearchConversationDataModel {
    let id: String
    let chatroomDetails: SearchChatroomDataModel
    let message: String
    let createdAt: Double
    
    public init(id: String, chatroomDetails: SearchChatroomDataModel, message: String, createdAt: Double) {
        self.id = id
        self.chatroomDetails = chatroomDetails
        self.message = message
        self.createdAt = createdAt
    }
}


public struct SearchListUserDataModel {
    public let uuid: String
    public let username: String
    public let imageURL: String?
    public let isGuest: Bool
    
    public init(uuid: String, username: String, imageURL: String?, isGuest: Bool) {
        self.uuid = uuid
        self.username = username
        self.imageURL = imageURL
        self.isGuest = isGuest
    }
    
    public var firstName: String {
        String(username.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ").first ?? "User")
    }
}