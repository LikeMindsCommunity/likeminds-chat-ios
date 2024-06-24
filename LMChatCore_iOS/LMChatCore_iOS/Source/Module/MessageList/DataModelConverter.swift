//
//  DataModelConverter.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 12/04/24.
//

import Foundation
import LikeMindsChat

class DataModelConverter {
    
    static let shared = DataModelConverter()
    
    func convertPostConversation(uuid: String, communityId: String, request: PostConversationRequest, fileUrls: [LMChatAttachmentMediaData]?) -> Conversation {
        let miliseconds = Int(Date().millisecondsSince1970)
        let member = LMChatClient.shared.getCurrentMember()?.data?.member
        return Conversation.Builder()
            .id(request.temporaryId)
            .chatroomId(request.chatroomId)
            .communityId(communityId)
            .answer(request.text)
            .state(ConversationState.normal.rawValue)
            .createdEpoch(miliseconds)
            .memberId(uuid)
            .member(member)
            .createdAt(LMCoreTimeUtils.generateCreateAtDate(miliseconds: Double(miliseconds), format: "HH:mm"))
            .attachments(convertAttachments(fileUrls, tempConvId: request.temporaryId))
            .lastSeen(true)
            .ogTags(request.ogTags)
            .date(LMCoreTimeUtils.generateCreateAtDate(miliseconds: Double(miliseconds)))
            .replyConversationId(request.repliedConversationId)
            .attachmentCount(request.attachmentCount)
            .localCreatedEpoch(miliseconds)
            .temporaryId(request.temporaryId)
            .isEdited(false)
            .replyChatroomId(request.repliedChatroomId)
            .attachmentUploaded(false)
            .conversationStatus(.sending)
            .build()
    }
    
    func convertAttachments(_ fileUrls: [LMChatAttachmentMediaData]?, tempConvId: String?) -> [Attachment]? {
        var i = 0
        return fileUrls?.map({ media in
            i += 1
            return convertAttachment(mediaData: media, index: i, tempConvId: tempConvId)
        })
    }
    
    func convertAttachment(mediaData: LMChatAttachmentMediaData, index: Int, tempConvId: String?) -> Attachment {
        let tempId = "\(tempConvId ?? "")-\(index)"
        return Attachment.builder()
            .id(tempId)
            .name(mediaData.mediaName)
            .url(mediaData.url?.absoluteString ?? "")
            .type(mediaData.fileType.rawValue)
            .index(index)
            .width(mediaData.width)
            .height(mediaData.height)
            .localFilePath(mediaData.url?.absoluteString ?? "")
            .thumbnailUrl(mediaData.thumbnailurl?.absoluteString)
            .thumbnailLocalFilePath(mediaData.thumbnailurl?.absoluteString)
            .awsFolderPath(mediaData.awsFolderPath)
            .thumbnailAWSFolderPath(mediaData.thumbnailAwsPath)
            .meta(
                AttachmentMeta.builder()
                    .numberOfPage(mediaData.pdfPageCount)
                    .duration(mediaData.duration)
                    .size(Int(mediaData.size ?? 0))
                    .build()
            )
            .build()
    }
    
}
