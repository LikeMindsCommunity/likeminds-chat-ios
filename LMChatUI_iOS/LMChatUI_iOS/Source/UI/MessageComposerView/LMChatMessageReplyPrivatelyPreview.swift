//
//  LMChatMessageReplyPrivatelyPreview.swift
//  Pods
//
//  Created by Anurag Tyagi on 23/04/25.
//

open class LMChatMessageReplyPrivatelyPreview: LMChatMessageReplyPreview{
    public struct ContentModel {
        public let replyPrivatelyExtra: LMChatReplyPrivatelyExtra
        
        public init(replyPrivatelyExtra: LMChatReplyPrivatelyExtra) {
            self.replyPrivatelyExtra = replyPrivatelyExtra
        }
    }
    
    open func setData(_ data: ContentModel) {
        let replyPrivatelyExtra = data.replyPrivatelyExtra

        let sourceConversation = replyPrivatelyExtra.sourceConversation
        
        let message =
            sourceConversation.isDeleted == true
            ? Constants.shared.strings.messageDeleteText
            : sourceConversation.answer

        let headingText =
            (sourceConversation.member?.name ?? "") + " • "
        + (replyPrivatelyExtra.sourceChatroomName)

        super.setData(
            .init(
                username: headingText,
                replyMessage: message,
                attachmentsUrls: sourceConversation.attachments?
                    .compactMap({
                        ($0.thumbnailUrl, $0.url, $0.type)
                    }),
                messageType: sourceConversation.messageType,
                isDeleted: sourceConversation.isDeleted
            )
        )
        self.onClickReplyPreview = { [weak self] in
            self?.delegate?.didTapOnReplyPrivatelyCell()
        }
    }
    
    
}
