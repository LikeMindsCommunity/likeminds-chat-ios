//
//  Conversation+Converter.swift
//  Pods
//
//  Created by Anurag Tyagi on 21/01/25.
//

import LikeMindsChatData
import LikeMindsChatUI

extension Conversation {
    /**
     Converts a `Conversation` instance into a `ConversationViewData` for UI representation.
     
     This method transforms the data model `Conversation` into a view-specific data model `ConversationViewData`.
     It handles all properties including basic conversation data, attachments, reactions, and poll information.
     
     - Parameters:
        - memberTitle: Optional title for the member (default: nil)
        - message: Optional message content (default: nil)
        - createdBy: Optional creator identifier (default: nil)
        - isIncoming: Optional flag indicating if message is incoming (default: nil)
        - messageType: Optional type of the message (default: nil)
        - messageStatus: Optional status of the message (default: nil)
        - hideLeftProfileImage: Optional flag to hide profile image (default: nil)
        - createdTime: Optional creation time string (default: nil)
        - replyConversation: Optional reply conversation view data (default: nil)
     
     - Returns: A `ConversationViewData` instance containing all the transformed data from this `Conversation`.
     The returned object will have the same content but in a format suitable for UI rendering.
     
     - Note: 
        - All optional parameters are used to override or set specific UI-related properties
        - Poll information is only included if poll-related data exists in the conversation
        - Nested objects (attachments, reactions, etc.) are converted using their respective toViewData methods
     */
    public func toViewData(memberTitle: String? = nil, message: String? = nil, createdBy: String? = nil, isIncoming: Bool? = nil, messageType: Int? = nil, messageStatus: LMMessageStatus? = nil, hideLeftProfileImage: Bool? = nil, createdTime: String? = nil, replyConversation: ConversationViewData? = nil) -> ConversationViewData {
        let viewData = ConversationViewData(
            answer: self.answer,
            state: self.state.toViewData(),  // Assuming `ConversationState` has `toViewData`
            widgetId: self.widgetId
        )
        viewData.id = self.id
        viewData.chatroomId = self.chatroomId
        viewData.communityId = self.communityId
        viewData.member = self.member?.toViewData()  // Assuming `Member` has `toViewData`
        viewData.createdAt = self.createdAt
        viewData.attachments = self.attachments?.compactMap { $0.toViewData() }  // Assuming `Attachment` has `toViewData`
        viewData.lastSeen = self.lastSeen
        viewData.ogTags = self.ogTags?.toViewData()  // Assuming `LinkOGTags` has `toViewData`
        viewData.date = self.date
        viewData.isEdited = self.isEdited
        viewData.memberId = self.memberId
        viewData.replyConversationId = self.replyConversationId
        viewData.deletedBy = self.deletedBy
        viewData.createdEpoch = self.createdEpoch
        viewData.attachmentCount = self.attachmentCount
        viewData.attachmentUploaded = self.attachmentUploaded
        viewData.uploadWorkerUUID = self.uploadWorkerUUID
        viewData.temporaryId = self.temporaryId
        viewData.localCreatedEpoch = self.localCreatedEpoch
        viewData.reactions = self.reactions?.compactMap { $0.toViewData() }  // Assuming `Reaction` has `toViewData`

        viewData.replyChatroomId = self.replyChatroomId
        viewData.deviceId = self.deviceId
        viewData.hasFiles = self.hasFiles
        viewData.hasReactions = self.hasReactions
        viewData.lastUpdated = self.lastUpdated
        viewData.deletedByMember = self.deletedByMember?.toViewData()  // Assuming `Member` has `toViewData`
        viewData.replyConversation = replyConversation ?? self.replyConversation?.toViewData()  // Assuming `Conversation` has `toViewData`
        viewData.conversationStatus = self.conversationStatus?.toViewData()  // Assuming `ConversationStatus` has `toViewData` // Assuming `Widget` has `toViewData`
        viewData.memberTitle = memberTitle
        viewData.message = message
        viewData.createdBy = createdBy
        viewData.isIncoming = isIncoming
        viewData.messageType = messageType
        viewData.messageStatus = messageStatus
        viewData.hideLeftProfileImage = hideLeftProfileImage
        viewData.createdTime = createdTime
        viewData.attachmentUploadedEpoch = attachmentUploadedEpoch
        
        // Create PollInfoData if any poll-related data exists
        if self.isAnonymous != nil || self.allowAddOption != nil || self.pollType != nil ||
           self.pollTypeText != nil || self.submitTypeText != nil || self.expiryTime != nil || 
           self.multipleSelectNum != nil || self.multipleSelectState != nil || self.polls != nil || 
           self.toShowResults != nil || self.pollAnswerText != nil {
            
            let pollInfoData = PollInfoData.Builder()
                .isAnonymous(self.isAnonymous)
                .allowAddOption(self.allowAddOption)
                .pollType(self.pollType)
                .pollTypeText(self.pollTypeText)
                .submitTypeText(self.submitTypeText)
                .expiryTime(self.expiryTime)
                .multipleSelectNum(self.multipleSelectNum)
                .multipleSelectState(self.multipleSelectState)
                .pollViewDataList(self.polls?.compactMap { $0.toViewData() })
                .pollAnswerText(self.pollAnswerText)
                .isPollSubmitted(false)
                .toShowResult(self.toShowResults)
                .build()
            
            viewData.pollInfoData = pollInfoData
            
            // The below function updated pollInfoData with
            // the neccessary data for Core implementation
            let pollInfoDataUpdated = convertPollData(viewData)
            
            viewData.pollInfoData = pollInfoDataUpdated
        }
        
        viewData.widget = self.widget?.toViewData() 
        
        return viewData
    }
    
    /**
     Converts poll data from a conversation view data into a PollInfoData object.
     
     This method processes poll-related information from a conversation and creates a structured PollInfoData object.
     It handles various poll properties including options, expiry time, and voting states.
     
     - Parameter conversation: The ConversationViewData containing poll information to convert
     
     - Returns: An optional `PollInfoData` instance containing the processed poll information.
     Returns nil if the conversation state is not .microPoll.
     
     - Note: This method is specifically designed for handling micro-poll conversations and their associated data.
     */
    public func convertPollData(_ conversation: ConversationViewData) -> PollInfoData? {
        guard conversation.state == .microPoll else { return nil }
        var pollInfoDataBuilder : PollInfoData.Builder? = conversation.pollInfoData?
            .toBuilder()

        // Update the builder with values from the conversation by calling the builder methods.
        pollInfoDataBuilder =
            pollInfoDataBuilder?
            .chatroomId(conversation.chatroomId ?? "")
            .messageId(conversation.id ?? "")
            .question(conversation.answer)
            .pollAnswerText(conversation.pollInfoData?.pollAnswerText ?? "")
            .options(
                getPollOptions(conversation.pollInfoData?.pollViewDataList, conversation: conversation)
            )
            .expiryDate(
                Date(milliseconds: Double(conversation.pollInfoData?.expiryTime ?? 0))
            )
            .optionState(
                LMChatPollSelectState(
                    rawValue: (conversation.pollInfoData?.multipleSelectState ?? 0))?
                    .description ?? ""
            )
            .optionCount(conversation.pollInfoData?.multipleSelectNum ?? 0)
            .isAnonymous(conversation.pollInfoData?.isAnonymous)
            .isInstantPoll(conversation.pollInfoData?.pollType == 0)
            .isShowSubmitButton(isShowSubmitButton(conversation))
            .isShowEditVote(isShowEditToVoteAgain(conversation))
            .submitTypeText(conversation.pollInfoData?.submitTypeText)
            .pollTypeText(conversation.pollInfoData?.pollTypeText)
            .allowAddOption(isAllowAddOption(conversation))

        return pollInfoDataBuilder?.build()
    }

    /**
     Determines if adding new options to a poll is allowed.
     
     This method checks various conditions to determine if users can add new options to an existing poll.
     
     - Parameter conversation: The ConversationViewData containing poll information
     
     - Returns: A Boolean indicating whether adding new options is allowed.
     Returns true only if:
     - The poll has not expired
     - No vote has been cast yet
     - The poll is configured to allow adding options
     */
    public func isAllowAddOption(_ conversation: ConversationViewData) -> Bool {
        let isExpired =
        (conversation.pollInfoData?.expiryTime ?? 0) < Int(Date().millisecondsSince1970)
        let isAlreadyVoted =
        conversation.pollInfoData?.pollViewDataList?.contains(where: { $0.isSelected == true })
            ?? false
        return !isExpired && !isAlreadyVoted
        && (conversation.pollInfoData?.allowAddOption ?? false)
    }

    /**
     Determines if users should be shown the option to edit their vote.
     
     This method evaluates conditions to determine if users should be allowed to modify their existing vote.
     
     - Parameter conversation: The ConversationViewData containing poll information
     
     - Returns: A Boolean indicating whether the edit vote option should be shown.
     Returns true only if:
     - The poll has not expired
     - A vote has already been cast
     - The poll is a deferred type (pollType == 1)
     - The poll allows multiple selections
     */
    public func isShowEditToVoteAgain(_ conversation: ConversationViewData) -> Bool {
        let isDeffered = conversation.pollInfoData?.pollType == 1
        let isAlreadyVoted =
        conversation.pollInfoData?.pollViewDataList?.contains(where: { $0.isSelected == true })
            ?? false
        let isExpired =
        (conversation.pollInfoData?.expiryTime ?? 0) < Int(Date().millisecondsSince1970)
        let isMultipleState = (conversation.pollInfoData?.multipleSelectState != nil)
        return !isExpired && isAlreadyVoted && isDeffered && isMultipleState
    }

    /**
     Determines if the submit button should be shown for a poll.
     
     This method evaluates conditions to determine if users should see the submit button for voting.
     
     - Parameter conversation: The ConversationViewData containing poll information
     
     - Returns: A Boolean indicating whether the submit button should be shown.
     Returns true only if:
     - The poll has not expired
     - No vote has been cast yet
     - The poll has a multiple selection state defined
     */
    public func isShowSubmitButton(_ conversation: ConversationViewData) -> Bool {
        let isAlreadyVoted =
        conversation.pollInfoData?.pollViewDataList?.contains(where: { $0.isSelected == true })
            ?? false
        let isExpired =
        (conversation.pollInfoData?.expiryTime ?? 0) < Int(Date().millisecondsSince1970)
        return !isExpired && !isAlreadyVoted
        && (conversation.pollInfoData?.multipleSelectState != nil)
    }

    /**
     Processes and formats poll options for display.
     
     This method handles the conversion and formatting of poll options, including:
     - Removing duplicate options
     - Sorting options by ID
     - Adding UI-specific properties like vote counts and progress bars
     
     - Parameters:
        - polls: Optional array of PollViewData to process
        - conversation: The parent ConversationViewData containing poll information
     
     - Returns: An array of processed PollViewData objects ready for display.
     Returns an empty array if no polls are provided.
     
     - Note: The method handles duplicate removal and adds UI-specific properties based on poll settings.
     */
    public func getPollOptions(_ polls: [PollViewData]?, conversation: ConversationViewData) -> [PollViewData] {
        guard var polls else { return [] }
        let isAllowAddOption = conversation.pollInfoData?.allowAddOption ?? false
        polls = polls.reduce([]) { result, element in
            result.contains(where: { $0.id == element.id })
                ? result : result + [element]
        }
        let pollOptions = polls.sorted(by: { ($0.id ?? "0") < ($1.id ?? "0") })
        let options = pollOptions.map { poll in

            let pollViewData = PollViewData.init(
                id: poll.id ?? "", text: poll.text,
                isSelected: poll.isSelected ?? false,
                percentage: Double(poll.percentage ?? 0),
                subText: poll.subText, noVotes: poll.noVotes,
                member: poll.member, userId: poll.userId,
                conversationId: poll.conversationId,
                showVoteCount: conversation.pollInfoData?.toShowResult ?? false,
                showProgressBar: conversation.pollInfoData?.toShowResult ?? false,
                showTickButton: poll.isSelected ?? false,
                addedBy: (isAllowAddOption ? (poll.member?.name ?? "") : ""))

            return pollViewData
        }
        return options
    }
}

extension ConversationViewData {
    /**
     Converts a `ConversationViewData` instance back into a `Conversation` data model.
     
     This method performs the reverse transformation from the UI representation back to the data model.
     It handles all properties including basic conversation data, attachments, reactions, and poll information.
     
     - Returns: A `Conversation` instance created using the Builder pattern, containing all the data
     from this `ConversationViewData` transformed into the data model format.
     
     - Note: 
        - Nested objects (attachments, reactions, etc.) are converted using their respective toXXX methods
        - Poll information is only included if pollInfoData exists in the view data
        - All optional values are handled appropriately in the builder pattern
     */
    public func toConversation() -> Conversation {
        var builder = Conversation.Builder()
            .id(self.id)
            .chatroomId(self.chatroomId)
            .communityId(self.communityId)
            .member(self.member?.toMember())  // Assuming `MemberViewData` has `toMember`
            .answer(self.answer)
            .createdAt(self.createdAt)
            .state(self.state.toConversationState().rawValue)  // Assuming `ConversationStateViewData` has `toConversationState`
            .attachments(self.attachments?.compactMap { $0.toAttachment() })  // Assuming `AttachmentViewData` has `toAttachment`
            .lastSeen(self.lastSeen)
            .ogTags(self.ogTags?.toLinkOGTags())  // Assuming `LinkOGTagsViewData` has `toLinkOGTags`
            .date(self.date)
            .isEdited(self.isEdited)
            .memberId(self.memberId)
            .replyConversationId(self.replyConversationId)
            .deletedBy(self.deletedBy)
            .createdEpoch(self.createdEpoch)
            .attachmentCount(self.attachmentCount)
            .attachmentUploaded(self.attachmentUploaded)
            .uploadWorkerUUID(self.uploadWorkerUUID)
            .temporaryId(self.temporaryId)
            .localCreatedEpoch(self.localCreatedEpoch)
            .reactions(self.reactions?.compactMap { $0.toReaction() } ?? [])  // Assuming `ReactionViewData` has `toReaction`
            .replyChatroomId(self.replyChatroomId)
            .deviceId(self.deviceId)
            .hasFiles(self.hasFiles)
            .hasReactions(self.hasReactions)
            .lastUpdated(self.lastUpdated)
            .deletedByMember(self.deletedByMember?.toMember())  // Assuming `MemberViewData` has `toMember`
            .replyConversation(self.replyConversation?.toConversation())  // Assuming `ConversationViewData` has `toConversation`
            .conversationStatus(self.conversationStatus?.toConversationStatus())  // Assuming `ConversationStatusViewData` has `toConversationStatus`
            .widgetId(self.widgetId)
            .widget(self.widget?.toWidget())  // Assuming `WidgetViewData` has `toWidget`
            .attachmentUploadedEpoch(self.attachmentUploadedEpoch)
        
        // Add poll-related data from PollInfoData if it exists
        if let pollInfoData = self.pollInfoData {
            builder = builder
                .isAnonymous(pollInfoData.isAnonymous)
                .allowAddOption(pollInfoData.allowAddOption)
                .pollType(pollInfoData.pollType)
                .pollTypeText(pollInfoData.pollTypeText)
                .submitTypeText(pollInfoData.submitTypeText)
                .expiryTime(pollInfoData.expiryTime)
                .multipleSelectNum(pollInfoData.multipleSelectNum)
                .multipleSelectState(pollInfoData.multipleSelectState)
                .polls(pollInfoData.pollViewDataList?.compactMap { $0.toPoll() })
                .toShowResults(pollInfoData.toShowResult)
                .pollAnswerText(pollInfoData.pollAnswerTextUpdated())
        }
        
        return builder.build()
    }
}
