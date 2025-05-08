//
//  LMChatMessageReplyPrivatelyPreview.swift
//  Pods
//
//  Created by Anurag Tyagi on 23/04/25.
//

class LMChatMessageReplyPrivatelyPreview: LMChatMessageReplyPreview{
    public struct ContentModel {
        public let replyPrivatelyExtra: LMChatReplyPrivatelyExtra
        
        public init(replyPrivatelyExtra: LMChatReplyPrivatelyExtra) {
            self.replyPrivatelyExtra = replyPrivatelyExtra
        }
    }
}
