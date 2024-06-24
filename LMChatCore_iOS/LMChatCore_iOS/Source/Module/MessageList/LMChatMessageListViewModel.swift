//
//  LMChatMessageListViewModel.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 18/03/24.
//

import Foundation
import LikeMindsChatUI
import LikeMindsChat

public protocol LMMessageListViewModelProtocol: LMBaseViewControllerProtocol {
    func reloadChatMessageList()
    func reloadData(at: ScrollDirection)
    func scrollToBottom(forceToBottom: Bool)
    func updateChatroomSubtitles()
    func updateTopicBar()
    func scrollToSpecificConversation(indexPath: IndexPath, isExistingIndex: Bool)
    func memberRightsCheck()
    func showToastMessage(message: String?)
    func insertLastMessageRow(section: String, conversationId: String)
}

public typealias ChatroomDetailsExtra = (chatroomId: String, conversationId: String?, reportedConversationId: String?)

public final class LMChatMessageListViewModel {
    
    weak var delegate: LMMessageListViewModelProtocol?
    var chatroomId: String
    var chatroomDetailsExtra: ChatroomDetailsExtra
    var chatMessages: [Conversation] = []
    var messagesList:[LMChatMessageListView.ContentModel] = []
    let conversationFetchLimit: Int = 100
    var chatroomViewData: Chatroom?
    var chatroomWasNotLoaded: Bool = true
    var chatroomActionData: GetChatroomActionsResponse?
    var memberState: GetMemberStateResponse?
    var contentDownloadSettings: [ContentDownloadSetting]?
    var currentDetectedOgTags: LinkOGTags?
    var replyChatMessage: Conversation?
    var replyChatroom: String?
    var editChatMessage: Conversation?
    var chatroomTopic: Conversation?
    var loggedInUserTagValue: String = ""
    var loggedInUserReplaceTagValue: String = ""
    var fetchingInitialBottomData: Bool = false
    var isConversationSyncCompleted: Bool = false
    var trackLastConversationExist: Bool = true
    
    init(delegate: LMMessageListViewModelProtocol?, chatroomExtra: ChatroomDetailsExtra) {
        self.delegate = delegate
        self.chatroomId = chatroomExtra.chatroomId
        self.chatroomDetailsExtra = chatroomExtra
    }
    
    
    public static func createModule(withChatroomId chatroomId: String, conversationId: String?) throws -> LMChatMessageListViewController {
        guard LMChatMain.isInitialized else { throw LMChatError.chatNotInitialized }
        
        let viewcontroller = LMCoreComponents.shared.messageListScreen.init()
        let viewmodel = Self.init(delegate: viewcontroller, chatroomExtra: (chatroomId, conversationId, nil))
        
        viewcontroller.viewModel = viewmodel
        viewcontroller.delegate = viewmodel
        return viewcontroller
    }
    
    @objc func conversationSyncCompleted(_ notification: Notification) {
        if chatroomViewData?.isConversationStored == false || chatroomViewData == nil {
            self.getInitialData()
        }
        self.isConversationSyncCompleted = true
        self.addObserveConversations()
    }
    
    func isAdmin() -> Bool {
        memberState?.state == MemberState.admin.rawValue
    }
    
    func checkMemberRight(_ rightState: MemberRightState) -> Bool {
        guard let right = memberState?.memberRights?.first(where:  {$0.state == rightState}) else { return  true }
        return right.isSelected ?? true
    }
    
    func loggedInUserTag() {
        guard let user = LMChatClient.shared.getLoggedInUser() else { return }
//        loggedInUserTagValue = "<<\(user.name ?? "")|route://user_profile/\(user.sdkClientInfo?.uuid ?? "")>>"
//        loggedInUserReplaceTagValue = "<<You|route://user_profile/\(user.sdkClientInfo?.uuid ?? "")>>"
        loggedInUserTagValue = "<<\(user.name ?? "")|route://member_profile/\(user.sdkClientInfo?.user ?? 0)?member_id=\(user.sdkClientInfo?.user ?? 0)&community_id=\(SDKPreferences.shared.getCommunityId() ?? "")>>"
        loggedInUserReplaceTagValue = "<<You|route://member_profile/\(user.sdkClientInfo?.user ?? 0)?member_id=\(user.sdkClientInfo?.user ?? 0)&community_id=\(SDKPreferences.shared.getCommunityId() ?? "")>>"
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func getInitialData() {
        NotificationCenter.default.addObserver(self, selector: #selector(conversationSyncCompleted), name: .conversationSyncCompleted, object: nil)
        loggedInUserTag()
        
        let chatroomRequest = GetChatroomRequest.Builder().chatroomId(chatroomId).build()
        guard let chatroom = LMChatClient.shared.getChatroom(request: chatroomRequest)?.data?.chatroom, (chatroom.isConversationStored) else {
            chatroomWasNotLoaded = true
            return
        }
        //2nd case -> chatroom is deleted, if yes return
        if chatroom.deletedBy != nil {
            (delegate as? LMChatMessageListViewController)?.navigationController?.popViewController(animated: true)
            return
        }
        chatroomViewData = chatroom
        chatroomTopic = chatroom.topic
        if chatroomTopic == nil, let topicId = chatroom.topicId {
            chatroomTopic = LMChatClient.shared.getConversation(request: GetConversationRequest.builder().conversationId(topicId).build())?.data?.conversation
        }
        delegate?.updateTopicBar()
        var medianConversationId: String?
        if let conId = self.chatroomDetailsExtra.conversationId {
            medianConversationId = conId
        } else if let reportedConId = self.chatroomDetailsExtra.reportedConversationId {
            medianConversationId = reportedConId
        } else {
            medianConversationId = nil
        }
        //3rd case -> open a conversation directly through search/deep links
        if let medianConversationId {
            // fetch list from searched or specific conversationid
            fetchIntermediateConversations(chatroom: chatroom, conversationId: medianConversationId)
        }
        //4th case -> chatroom is present and conversation is not present
//        else  if chatroom.totalAllResponseCount == 0 {
//            // Convert chatroom data into first conversation and display
//            //                chatroomDataToHeaderConversation(chatroom)
//            fetchBottomConversations()
//        }
        //5th case -> chatroom is opened through deeplink/explore feed, which is open for the first time
//        else if chatroomWasNotLoaded {
//            fetchBottomConversations()
//            chatroomWasNotLoaded = false
//        }
        //6th case -> chatroom is present and conversation is present, chatroom opened for the first time from home feed
//        else if chatroom.lastSeenConversation == nil {
//            // showshimmer
//        }
        //7th case -> chatroom is present but conversations are not stored in chatroom
        else if !chatroom.isConversationStored {
            // showshimmer
        }
        //8th case -> chatroom is present and conversation is present, chatroom has no unseen conversations
//        else if chatroom.unseenCount == 0 {
//            fetchBottomConversations()
//        }
        //9th case -> chatroom is present and conversation is present, chatroom has unseen conversations
        else {
//            fetchIntermediateConversations(chatroom: chatroom, conversationId: chatroom.lastSeenConversation?.id ?? "")
            fetchBottomConversations()
        }
        
        fetchChatroomActions()
        markChatroomAsRead()
        fetchMemberState()
        observeConversations(chatroomId: chatroom.id)
    }
    
    func syncLatestConversations(withConversationId conversationId: String) {
        LMChatClient.shared.loadLatestConversations(withConversationId: conversationId, chatroomId: chatroomId)
    }
    
    func convertConversationsIntoGroupedArray(conversations: [Conversation]?) -> [LMChatMessageListView.ContentModel] {
        guard let conversations else { return [] }
        print("conversations ------> \(conversations)")
        let dictionary = Dictionary(grouping: conversations, by: { $0.date })
        var conversationsArray: [LMChatMessageListView.ContentModel] = []
        for key in dictionary.keys {
            conversationsArray.append(.init(data: (dictionary[key] ?? []).compactMap({self.convertConversation($0)}), section: key ?? "", timestamp: convertDateStringToInterval(key ?? "")))
        }
        return conversationsArray
    }
    
    func fetchBottomConversations(onButtonClicked: Bool = false) {
        let request = GetConversationsRequest.Builder()
            .chatroomId(chatroomId)
            .limit(conversationFetchLimit)
            .type(.bottom)
            .build()
        let response = LMChatClient.shared.getConversations(withRequest: request)
        guard let conversations = response?.data?.conversations else { return }
        chatMessages = conversations
        messagesList.removeAll()
        messagesList.append(contentsOf: convertConversationsIntoGroupedArray(conversations: conversations))
        if conversations.count < conversationFetchLimit {
            if  let chatroom = chatroomViewData {
                let message = chatroomDataToConversation(chatroom)
                insertOrUpdateConversationIntoList(message)
            }
        }
        fetchingInitialBottomData = !onButtonClicked
        LMChatClient.shared.observeLiveConversation(withChatroomId: chatroomId)
        delegate?.scrollToBottom(forceToBottom: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {[weak self] in
            self?.fetchingInitialBottomData = false
        }
        trackLastConversationExist = true
    }
    
    func fetchTopConversations() {
        let request = GetConversationsRequest.Builder()
            .chatroomId(chatroomId)
            .limit(conversationFetchLimit)
            .type(.top)
            .build()
        let response = LMChatClient.shared.getConversations(withRequest: request)
        guard let conversations = response?.data?.conversations else { return }
        chatMessages = conversations
        messagesList.removeAll()
        messagesList.append(contentsOf: convertConversationsIntoGroupedArray(conversations: conversations))
        if  let chatroom = chatroomViewData {
            let message = chatroomDataToConversation(chatroom)
            insertOrUpdateConversationIntoList(message)
        }
        if conversations.count < conversationFetchLimit {
            trackLastConversationExist = true
        } else {
            trackLastConversationExist = false
        }
        delegate?.scrollToSpecificConversation(indexPath: IndexPath(row: 0, section: 0), isExistingIndex: false)
    }
    
    func chatroomDataToHeaderConversation(_ chatroom: Chatroom) {
        let message = chatroomDataToConversation(chatroom)
        insertOrUpdateConversationIntoList(message)
    }
    
    func fetchConversationsOnScroll(conversationId: String, type: GetConversationType) {
        var conversation: Conversation?
        if let message = chatMessages.first(where: {($0.id ?? "") == conversationId }) {
            conversation = message
        } else if let message = LMChatClient.shared.getConversation(request: .builder().conversationId(conversationId).build())?.data?.conversation {
            conversation = message
        } else {
            return
        }
        let request = GetConversationsRequest.Builder()
            .chatroomId(chatroomId)
            .limit(conversationFetchLimit)
            .conversation(conversation)
            .observer(self)
            .type(type)
            .build()
        let response = LMChatClient.shared.getConversations(withRequest: request)
        guard var conversations = response?.data?.conversations, conversations.count > 0 else {
            if type == .below { trackLastConversationExist = true }
            return
        }
        if type == .above, conversations.count < conversationFetchLimit, let chatroom = self.chatroomViewData {
            conversations.insert(chatroomDataToConversation(chatroom), at: 0)
        }
        for item in conversations {
            insertOrUpdateConversationIntoList(item)
        }
        messagesList.sort(by: {$0.timestamp < $1.timestamp})
        let direction: ScrollDirection = type == .above ? .scroll_UP : .scroll_DOWN
        delegate?.reloadData(at: direction)
    }
    
    func getMoreConversations(conversationId: String, direction: ScrollDirection) {
        
        switch direction {
        case .scroll_UP:
                print("fetch more data above data ....")
                fetchConversationsOnScroll(conversationId: conversationId, type: .above)
        case .scroll_DOWN:
                print("fetch more data below data ....")
                fetchConversationsOnScroll(conversationId: conversationId, type: .below)
        default:
            break
        }
    }
    
    func fetchIntermediateConversations(chatroom: Chatroom, conversationId: String) {
        let getConversationRequest = GetConversationRequest.builder()
            .conversationId(conversationId)
            .build()
        guard let mediumConversation = LMChatClient.shared.getConversation(request: getConversationRequest)?.data?.conversation else {
            if conversationId == self.chatroomViewData?.id {
                fetchTopConversations()
            }
            return
        }
        
        let getAboveConversationRequest = GetConversationsRequest.builder()
            .conversation(mediumConversation)
            .type(.above)
            .chatroomId(chatroomViewData?.id ?? "")
            .limit(conversationFetchLimit)
            .build()
        let aboveConversations = LMChatClient.shared.getConversations(withRequest: getAboveConversationRequest)?.data?.conversations ?? []
        
        let getBelowConversationRequest = GetConversationsRequest.builder()
            .conversation(mediumConversation)
            .type(.below)
            .chatroomId(chatroomViewData?.id ?? "")
            .limit(conversationFetchLimit)
            .build()
        let belowConversations = LMChatClient.shared.getConversations(withRequest: getBelowConversationRequest)?.data?.conversations ?? []
        var allConversations = aboveConversations + [mediumConversation] + belowConversations
        
        if aboveConversations.count < conversationFetchLimit {
            allConversations.insert(chatroomDataToConversation(chatroom), at: 0)
        }
        
        chatMessages = allConversations
        messagesList = convertConversationsIntoGroupedArray(conversations: allConversations)
        messagesList.sort(by: {$0.timestamp < $1.timestamp})
        guard let section = messagesList.firstIndex(where: {$0.section == mediumConversation.date}),
              let index = messagesList[section].data.firstIndex(where: {$0.messageId == mediumConversation.id}) else { return }
        fetchingInitialBottomData = true
        delegate?.scrollToSpecificConversation(indexPath: IndexPath(row: index, section: section), isExistingIndex: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {[weak self] in
            self?.fetchingInitialBottomData = false
        }
        if chatMessages.count < conversationFetchLimit {
            trackLastConversationExist = true
        } else {
            trackLastConversationExist = false
        }
    }
    
    func syncConversation() {
        let chatroomRequest = GetChatroomRequest.Builder().chatroomId(chatroomId).build()
        let response = LMChatClient.shared.getChatroom(request: chatroomRequest)
        if response?.data?.chatroom?.isConversationStored == true{
            LMChatClient.shared.loadConversations(withChatroomId: chatroomId, loadType: .reopen)
        } else {
            LMChatClient.shared.loadConversations(withChatroomId: chatroomId, loadType: .firstTime)
        }
    }
    
    func convertConversation(_ conversation: Conversation) -> LMChatMessageListView.ContentModel.Message {
        var replies: [LMChatMessageListView.ContentModel.Message] = []
        var replyConversation: Conversation? = conversation.replyConversation
        
        if (conversation.replyConversation == nil), let replyConId = conversation.replyConversationId, let replyCon = LMChatClient.shared.getConversation(request: .builder().conversationId(replyConId).build())?.data?.conversation{
            replyConversation = replyCon
        }
        if let chatroomid = conversation.replyChatroomId, let chatroom = LMChatClient.shared.getChatroom(request: .Builder().chatroomId(chatroomid).build())?.data?.chatroom {
            replyConversation = chatroomDataToConversation(chatroom)
        }
        
        if let replyConversation {
            replies =
            [.init(messageId: replyConversation.id ?? "", memberTitle: conversation.member?.communityManager(),
                   message: ignoreGiphyUnsupportedMessage(replyConversation.answer),
                   timestamp: replyConversation.createdEpoch,
                      reactions: nil,
                   attachments: replyConversation.attachments?.sorted(by: {($0.index ?? 0) < ($1.index ?? 0)}).compactMap({.init(fileUrl: FileUtils.imageUrl($0.url), thumbnailUrl: FileUtils.imageUrl($0.thumbnailUrl), fileSize: $0.meta?.size, numberOfPages: $0.meta?.numberOfPage, duration: $0.meta?.duration, fileType: $0.type, fileName: $0.name)}), replied: nil,
                   isDeleted: replyConversation.deletedByMember != nil,
                   createdBy: replyConversation.member?.sdkClientInfo?.uuid != UserPreferences.shared.getClientUUID() ? replyConversation.member?.name : "You",
                   createdByImageUrl: replyConversation.member?.imageUrl, createdById: replyConversation.member?.sdkClientInfo?.uuid,
                   isIncoming: replyConversation.member?.sdkClientInfo?.uuid != UserPreferences.shared.getClientUUID(),
                   messageType: replyConversation.state.rawValue,
                   createdTime: LMCoreTimeUtils.timestampConverted(withEpoch: replyConversation.createdEpoch ?? 0),
                   ogTags: createOgTags(replyConversation.ogTags),
                   isEdited: replyConversation.isEdited,
                   attachmentUploaded: replyConversation.attachmentUploaded, isShowMore: false, messageStatus: messageStatus(replyConversation.conversationStatus),
                   tempId: replyConversation.temporaryId)]
        }
        return .init(messageId: conversation.id ?? "", memberTitle: conversation.member?.communityManager(),
                     message: ignoreGiphyUnsupportedMessage(conversation.answer),
                     timestamp: conversation.createdEpoch,
                     reactions: reactionGrouping(conversation.reactions?.reversed() ?? []),
                     attachments: conversation.attachments?.sorted(by: {($0.index ?? 0) < ($1.index ?? 0)}).map({.init(fileUrl: FileUtils.imageUrl($0.url), thumbnailUrl: FileUtils.imageUrl($0.thumbnailUrl), fileSize: $0.meta?.size, numberOfPages: $0.meta?.numberOfPage, duration: $0.meta?.duration, fileType: $0.type, fileName: $0.name)}),
                     replied: replies,
                     isDeleted: conversation.deletedByMember != nil,
                     createdBy: conversation.member?.name,
                     createdByImageUrl: conversation.member?.imageUrl,
                     createdById: conversation.member?.sdkClientInfo?.uuid,
                     isIncoming: conversation.member?.sdkClientInfo?.uuid != UserPreferences.shared.getClientUUID(),
                     messageType: conversation.state.rawValue, createdTime: LMCoreTimeUtils.timestampConverted(withEpoch: conversation.createdEpoch ?? 0), ogTags: createOgTags(conversation.ogTags), isEdited: conversation.isEdited, attachmentUploaded: conversation.attachmentUploaded, isShowMore: false, messageStatus: messageStatus(conversation.conversationStatus), tempId: conversation.temporaryId)
    }
    
    func messageStatus(_ status: ConversationStatus?) -> LMMessageStatus {
        guard let status else { return .sending }
        switch status {
        case .sent:
            return .sent
        case .sending:
            return .sending
        case .failed:
            return .failed
        default:
            return .sending
        }
    }
    
    func ignoreGiphyUnsupportedMessage(_ message: String) -> String {
        let text = message.replacingOccurrences(of: GiphyAPIConfiguration.gifMessage, with: "")
        return text //GetAttributedTextWithRoutes.getAttributedText(from: text).string
    }
    
    func createOgTags(_ ogTags: LinkOGTags?) -> LMChatMessageListView.ContentModel.OgTags? {
        guard let ogTags else {
            return nil
        }
        return .init(link: ogTags.url, thumbnailUrl: ogTags.image, title: ogTags.title, subtitle: ogTags.description)
    }
    
    func reactionGrouping(_ reactions: [Reaction]) -> [LMChatMessageListView.ContentModel.Reaction] {
        guard !reactions.isEmpty else { return []}
        let reactionsOnly = reactions.map { $0.reaction }.unique()
        let grouped = Dictionary(grouping: reactions, by: {$0.reaction})
        var reactionsArray: [LMChatMessageListView.ContentModel.Reaction] = []
        for item in reactionsOnly {
            let membersIds = grouped[item]?.compactMap({$0.member?.uuid}) ?? []
            reactionsArray.append(.init(memberUUID: membersIds, reaction: item, count: membersIds.count))
        }
        return reactionsArray
    }

    func insertOrUpdateConversationIntoList(_ conversation: Conversation) {
        if let firstIndex = chatMessages.firstIndex(where: {($0.id == conversation.id) || ($0.id == conversation.temporaryId) || ($0.temporaryId != nil && $0.temporaryId == conversation.temporaryId)}) {
            chatMessages[firstIndex] = conversation
            updateConversationIntoList(conversation)
        } else {
            chatMessages.append(conversation)
            insertConversationIntoList(conversation)
        }
    }
    
    func insertConversationIntoList(_ conversation: Conversation) {
        let conversationDate = conversation.date ?? ""
        if let index = messagesList.firstIndex(where: {$0.section == conversationDate}) {
            var sectionData = messagesList[index]
            sectionData.data.append(convertConversation(conversation))
            sectionData.data.sort(by: {($0.timestamp ?? 0) < ($1.timestamp ?? 0)})
            messagesList[index] = sectionData
        } else {
            messagesList.append((.init(data: [convertConversation(conversation)], section: conversationDate, timestamp: convertDateStringToInterval(conversationDate))))
        }
    }
    
    func updateConversationIntoList(_ conversation: Conversation) {
        let conversationDate = conversation.date ?? ""
        if let index = messagesList.firstIndex(where: {$0.section == conversationDate}) {
            var sectionData = messagesList[index]
            if let conversationIndex = sectionData.data.firstIndex(where: {$0.messageId == conversation.id || $0.messageId == conversation.temporaryId}) {
                sectionData.data[conversationIndex] = convertConversation(conversation)
            }
            sectionData.data.sort(by: {($0.timestamp ?? 0) < ($1.timestamp ?? 0)})
            messagesList[index] = sectionData
        }
    }
    
    func chatroomDataToConversation(_ chatroom: Chatroom) -> Conversation {
        let conversation = Conversation.builder()
            .date(chatroom.date)
            .answer(chatroom.title)
            .member(chatroom.member)
            .state(LMChatMessageListView.chatroomHeader)
            .createdEpoch(chatroom.dateEpoch)
            .id(chatroomId)
            .reactions(chatroom.reactions)
            .hasReactions(chatroom.hasReactions)
            .conversationStatus(.sent)
            .build()
        return conversation
    }
    
    func fetchMemberState() {
        LMChatClient.shared.getMemberState {[weak self] response in
            guard let memberState = response.data else { return }
            self?.memberState = memberState
            self?.delegate?.memberRightsCheck()
        }
    }
    
    func markChatroomAsRead() {
        let request = MarkReadChatroomRequest.builder()
            .chatroomId(chatroomId)
            .build()
        LMChatClient.shared.markReadChatroom(request: request) { response in
            print(response)
        }
    }
    
    func fetchChatroomActions() {
        let request = GetChatroomActionsRequest.builder()
            .chatroomId(chatroomId)
            .build()
        LMChatClient.shared.getChatroomActions(request: request) {[weak self] response in
            guard let actionsData = response.data else { return }
            self?.chatroomActionData = actionsData
            self?.delegate?.updateChatroomSubtitles()
        }
    }
    
    func fetchContentDownloadSetting() {
        LMChatClient.shared.getContentDownloadSettings {[weak self] response in
            guard let settings = response.data?.settings else { return }
            self?.contentDownloadSettings = settings
        }
    }
    
    func muteUnmuteChatroom(value: Bool) {
        let request = MuteChatroomRequest.builder()
            .chatroomId(chatroomViewData?.id ?? "")
            .value(value)
            .build()
        LMChatClient.shared.muteChatroom(request: request) {[weak self] response in
            guard response.success else { return }
            if value {
                self?.delegate?.showToastMessage(message: String(format: Constants.shared.strings.muteUnmuteMessage, "muted"))
            } else {
                self?.delegate?.showToastMessage(message: String(format: Constants.shared.strings.muteUnmuteMessage, "unmuted"))
            }
            self?.fetchChatroomActions()
        }
    }
    
    func leaveChatroom() {
        let request = LeaveSecretChatroomRequest.builder()
            .chatroomId(chatroomViewData?.id ?? "")
            .uuid(UserPreferences.shared.getClientUUID() ?? "")
            .isSecret(chatroomViewData?.isSecret ?? false)
            .build()
        LMChatClient.shared.leaveSecretChatroom(request: request) { [weak self] response in
            guard response.success else { return }
            (self?.delegate as? LMViewController)?.dismissViewController()
        }
    }
    
    func performChatroomActions(action: ChatroomAction) {
        guard let fromViewController = delegate as? LMViewController else { return }
        switch action.id {
        case .viewParticipants:
            NavigationScreen.shared.perform(.participants(chatroomId: chatroomViewData?.id ?? "", isSecret: chatroomViewData?.isSecret ?? false), from: fromViewController, params: nil)
        case .invite:
            guard let chatroomId = chatroomViewData?.id else { return }
            ShareContentUtil.shareChatroom(viewController: fromViewController, chatroomId: chatroomId)
        case .report:
            NavigationScreen.shared.perform(.report(chatroomId: chatroomViewData?.id ?? "", conversationId: nil, memberId: nil), from: fromViewController, params: nil)
        case .leaveChatRoom:
            leaveChatroom()
        case .unFollow:
            followUnfollow(status: false, forceToUpdate: true)
        case .follow:
            followUnfollow(status: true, forceToUpdate: true)
        case .mute:
            muteUnmuteChatroom(value: true)
        case .unMute:
            muteUnmuteChatroom(value: false)
        default:
            break
        }
    }
}

extension LMChatMessageListViewModel: ConversationClientObserver {
    
    public func initial(_ conversations: [Conversation]) {
    }
    
    public func onChange(removed: [Int], inserted: [(Int, Conversation)], updated: [(Int, Conversation)]) {
    }
    
    func convertDateStringToInterval(_ strDate: String) -> Int {
        // Create Date Formatter
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = .current
        // Set Date Format
        dateFormatter.dateFormat = "d MMM y"
        
        // Convert String to Date
        return Int(dateFormatter.date(from: strDate)?.timeIntervalSince1970 ?? 0)
    }
    
    func decodeUrl(url: String, decodeResponse: ((LinkOGTags?) -> Void)?) {
        let request = DecodeUrlRequest.builder()
            .url(url)
            .build()
        LMChatClient.shared.decodeUrl(request: request) {[weak self] response in
            guard let ogTags = response.data?.ogTags else { return }
            self?.currentDetectedOgTags = ogTags
            decodeResponse?(ogTags)
        }
    }
}

extension LMChatMessageListViewModel: ConversationChangeDelegate {
    
    func observeConversations(chatroomId: String) {
        let request = ObserveConversationsRequest.builder()
            .chatroomId(chatroomId)
            .listener(self)
            .build()
        LMChatClient.shared.observeConversations(request: request)
    }
    
    func removeObserveConversations() {
        LMChatClient.shared.removeObserverConversation(self)
    }
    
    func addObserveConversations() {
        LMChatClient.shared.addObserverConversation(self)
    }
    
    public func getPostedConversations(conversations: [Conversation]?) {
        print("getPostedConversations -- \(conversations)")
        guard let conversations, !fetchingInitialBottomData else { return }
        for item in conversations {
            insertOrUpdateConversationIntoList(item)
        }
        if !conversations.isEmpty {
            delegate?.reloadChatMessageList()
        }
    }
    
    public func getChangedConversations(conversations: [Conversation]?) {
        print("getChangedConversations -- \(conversations)")
        guard let conversations, !fetchingInitialBottomData else { return }
        for item in conversations {
            insertOrUpdateConversationIntoList(item)
        }
        if !conversations.isEmpty {
            delegate?.reloadChatMessageList()
        }
    }
    
    public func getNewConversations(conversations: [Conversation]?) {
        print("getNewConversations -- \(conversations)")
        guard let conversations, !fetchingInitialBottomData else { return }
        for item in conversations {
            if (item.attachmentCount ?? 0) > 0 {
                if item.attachmentUploaded == true {
                    insertOrUpdateConversationIntoList(item)
                }
            } else {
                insertOrUpdateConversationIntoList(item)
            }
        }
        if !conversations.isEmpty {
            delegate?.scrollToBottom(forceToBottom: false)
        }
    }
    
}

extension LMChatMessageListViewModel: LMChatMessageListControllerDelegate {
    
    func postMessage(message: String?,
                     filesUrls: [LMChatAttachmentMediaData]?,
                     shareLink: String?,
                     replyConversationId: String?,
                     replyChatRoomId: String?, temporaryId: String? = nil) {
        LMSharedPreferences.removeValue(forKey: chatroomId)
        guard let communityId = chatroomViewData?.communityId else { return }
        if !trackLastConversationExist {
            fetchBottomConversations()
        }
        let temporaryId = temporaryId ?? ValueUtils.getTemporaryId()
        var requestBuilder = PostConversationRequest.Builder()
            .chatroomId(self.chatroomId)
            .text(message ?? "")
            .temporaryId(temporaryId)
            .repliedConversationId(replyConversationId)
            .repliedChatroomId(replyChatRoomId)
            .attachmentCount(filesUrls?.count)
            .shareLink(shareLink)
        
        if let shareLink, !shareLink.isEmpty, self.currentDetectedOgTags?.url == shareLink {
            requestBuilder = requestBuilder.shareLink(shareLink)
                .ogTags(currentDetectedOgTags)
            currentDetectedOgTags = nil
        }
        let postConversationRequest = requestBuilder.build()
        
        let tempConversation = saveTemporaryConversation(uuid: UserPreferences.shared.getClientUUID() ?? "", communityId: communityId, request: postConversationRequest, fileUrls: filesUrls)
        insertOrUpdateConversationIntoList(tempConversation)
        delegate?.scrollToBottom(forceToBottom: true)
        
        LMChatClient.shared.postConversation(request: postConversationRequest) {[weak self] response in
            guard let self, let conversation = response.data else {
                self?.delegate?.showToastMessage(message: response.errorMessage)
                self?.updateConversationUploadingStatus(messageId: temporaryId, withStatus: .failed)
                return
            }
            onConversationPosted(response: conversation.conversation, updatedFileUrls: filesUrls)
        }
    }
    private func saveTemporaryConversation(uuid: String,
                                           communityId: String,
                                           request: PostConversationRequest,
                                           fileUrls: [LMChatAttachmentMediaData]?) -> Conversation {
        var conversation = DataModelConverter.shared.convertPostConversation(uuid: uuid, communityId: communityId, request: request, fileUrls: fileUrls)
        
        let saveConversationRequest = SaveConversationRequest.builder()
            .conversation(conversation)
            .build()
        LMChatClient.shared.saveTemporaryConversation(request: saveConversationRequest)
        if let replyId = conversation.replyConversationId {
            let replyConversationRequest = GetConversationRequest.builder().conversationId(replyId).build()
            if let replyConver = LMChatClient.shared.getConversation(request: replyConversationRequest)?.data?.conversation {
               conversation = conversation.toBuilder()
                    .replyConversation(replyConver)
                    .build()
            }
        }
        let member = LMChatClient.shared.getCurrentMember()?.data?.member
        conversation = conversation.toBuilder()
            .member(member)
            .build()
        return conversation
    }
    
    func onConversationPosted(response: Conversation?,
                              updatedFileUrls: [LMChatAttachmentMediaData]?, isRetry: Bool = false) {
        guard let conversation = response, let conversId = conversation.id else {
            return
        }
        var requestFiles:[LMChatAttachmentUploadRequest] = []
        if let updatedFileUrls, !updatedFileUrls.isEmpty {
            requestFiles.append(contentsOf: getUploadFileRequestList(fileUrls: updatedFileUrls, conversationId: conversId, chatroomId: conversation.chatroomId ?? ""))
            LMChatConversationAttachmentUpload.shared.uploadConversationAttchment(withAttachments: requestFiles, conversationId: conversId, convTempId: conversation.temporaryId ?? "")
        }
        if !isRetry {
            savePostedConversation(requestList: requestFiles, conversation: conversation)
            followUnfollow()
        }
    }
    
    func getUploadFileRequestList(fileUrls: [LMChatAttachmentMediaData], conversationId: String, chatroomId: String) -> [LMChatAttachmentUploadRequest] {
        var fileUploadRequests: [LMChatAttachmentUploadRequest] = []
        for (index, attachment) in fileUrls.enumerated() {
            let attachmentMetaDataRequest = LMChatAttachmentMetaDataRequest.builder()
                .duration(attachment.duration)
                .numberOfPage(attachment.pdfPageCount)
                .size(Int(attachment.size ?? 0))
                .build()
            let attachmentDataRequest = LMChatAttachmentUploadRequest.builder()
                .name(attachment.mediaName)
                .fileUrl(FileUtils.getFilePath(withFileName: attachment.url?.lastPathComponent))
                .localFilePath(FileUtils.getFilePath(withFileName: attachment.url?.lastPathComponent)?.absoluteString)
                .fileType(attachment.fileType.rawValue)
                .width(attachment.width)
                .height(attachment.height)
                .awsFolderPath(LMChatAWSManager.awsFilePathForConversation(chatroomId: chatroomId, conversationId: conversationId, attachmentType: attachment.fileType.rawValue, fileExtension: attachment.url?.pathExtension ?? "", filename: attachment.mediaName ?? "no_name_\(Int.random(in: 1...100))"))
                .thumbnailAWSFolderPath(LMChatAWSManager.awsFilePathForConversation(chatroomId: chatroomId, conversationId: conversationId, attachmentType: attachment.fileType.rawValue, fileExtension: attachment.url?.pathExtension ?? "", filename: attachment.mediaName ?? "no_name_\(Int.random(in: 1...100))", isThumbnail: true))
                .thumbnailLocalFilePath(FileUtils.getFilePath(withFileName: attachment.thumbnailurl?.lastPathComponent)?.absoluteString ?? "")
                .meta(attachmentMetaDataRequest)
                .index(index + 1)
                .build()
            fileUploadRequests.append(attachmentDataRequest)
        }
        
        return fileUploadRequests
    }
    
    func savePostedConversation(requestList: [LMChatAttachmentUploadRequest],
                                conversation: Conversation) {
        let attachments = requestList.map { request in
            let tempId = "\(conversation.temporaryId ?? "")-\(request.index)"
            return Attachment.builder()
                .id(tempId)
                .name(request.name)
                .url(request.fileUrl?.absoluteString ?? "")
                .type(request.fileType)
                .index(request.index)
                .width(request.width)
                .height(request.height)
                .awsFolderPath(request.awsFolderPath)
                .localFilePath(request.localFilePath)
                .meta(
                    AttachmentMeta.builder()
                        .duration(request.meta?.duration)
                        .numberOfPage(request.meta?.numberOfPage)
                        .size(request.meta?.size)
                        .build()
                )
                .build()
        }
        
        let updatedConversation = conversation.toBuilder()
        .attachments(attachments)
        .build()
        let request = SavePostedConversationRequest.builder()
            .conversation(updatedConversation)
            .build()
        LMChatClient.shared.savePostedConversation(request: request)
        
        if (conversation.attachmentCount ?? 0) > 0 {
            if conversation.attachmentUploaded == true {
                insertOrUpdateConversationIntoList(conversation)
            }
        } else {
            insertOrUpdateConversationIntoList(conversation)
        }
    }
    
    func retryUploadConversation(_ messageId: String) {
        let request = GetConversationRequest.builder()
            .conversationId(messageId)
            .build()
        guard let conversation = LMChatClient.shared.getConversation(request: request)?.data?.conversation,
              let _ = chatroomViewData?.id else {
            return
        }
        let fileUrls: [LMChatAttachmentMediaData] = (conversation.attachments ?? []).map { attachment in
            return LMChatAttachmentMediaData(url: FileUtils.getFilePath(withFileName: URL(string: attachment.url ?? "")?.lastPathComponent),
                                             fileType: MediaType(rawValue: attachment.type ?? "image") ?? .image,
                                             width: attachment.width,
                                             height: attachment.height,
                                             thumbnailurl: FileUtils.getFilePath(withFileName: URL(string: attachment.thumbnailUrl ?? "")?.lastPathComponent),
                                             size: attachment.meta?.size,
                                             mediaName: attachment.name,
                                             pdfPageCount: attachment.meta?.numberOfPage,
                                             duration: attachment.meta?.duration,
                                             awsFolderPath: attachment.awsFolderPath,
                                             thumbnailAwsPath: attachment.thumbnailAWSFolderPath,
                                             format: attachment.type,
                                             image: nil,
                                             livePhoto: nil)
        }
        if let conId = Int(conversation.id ?? "NA"), conId > 0, fileUrls.count > 0 {
            updateConversationUploadingStatus(messageId: conversation.id ?? "", withStatus: .sending)
            onConversationPosted(response: conversation, updatedFileUrls: fileUrls, isRetry: true)
        } else {
            if Int(conversation.id ?? "NA") == nil {
                self.currentDetectedOgTags = conversation.ogTags
                postMessage(message: conversation.answer, filesUrls: fileUrls, shareLink: conversation.ogTags?.url, replyConversationId: conversation.replyConversationId, replyChatRoomId: conversation.replyChatroomId, temporaryId: conversation.temporaryId)
            }
        }
    }
    
    func postEditedConversation(text: String, shareLink: String?, conversation: Conversation?) {
        guard !text.isEmpty, let conversationId = conversation?.id else { return }
        LMSharedPreferences.removeValue(forKey: chatroomId)
        let request = EditConversationRequest.builder()
            .conversationId(conversationId)
            .text(text)
            .shareLink(shareLink)
            .build()
        LMChatClient.shared.editConversation(request: request) {[weak self] resposne in
            guard resposne.success, let _ = resposne.data?.conversation else { return}
        }
    }
    
    func followUnfollow(status: Bool = true, forceToUpdate: Bool = false) {
        guard (chatroomViewData?.followStatus == false || forceToUpdate), let chatroomId = chatroomViewData?.id else { return }
        let request = FollowChatroomRequest.builder()
            .chatroomId(chatroomId)
            .uuid(UserPreferences.shared.getClientUUID() ?? "")
            .value(status)
            .build()
        LMChatClient.shared.followChatroom(request: request) {[weak self] response in
            guard response.success else {
                return
            }
            if status {
                self?.delegate?.showToastMessage(message: Constants.shared.strings.followedMessage)
            } else {
                self?.delegate?.showToastMessage(message: Constants.shared.strings.unfollowedMessage)
            }
            self?.fetchChatroomActions()
            self?.chatroomViewData = LMChatClient.shared.getChatroom(request: .Builder().chatroomId(self?.chatroomId ?? "").build())?.data?.chatroom
            LMChatClient.shared.syncChatrooms()
        }
    }
    
    func putConversationReaction(conversationId: String, reaction: String) {
        updateReactionsForUI(reaction: reaction, conversationId: conversationId, chatroomId: nil)
        let request = PutReactionRequest.builder()
            .conversationId(conversationId)
            .reaction(reaction)
            .build()
        LMChatClient.shared.putReaction(request: request) {[weak self] response in
            guard response.success else {
                return
            }
            self?.followUnfollow()
        }
    }
    
    private func updateReactionsForUI(reaction: String, conversationId: String?, chatroomId: String?) {
        if chatroomId != nil, let chatroomViewData {
            var reactions = self.chatroomViewData?.reactions ?? []
            reactions = updatedReactionsFor(existingReactions: reactions, currentReaction: reaction)
            let updatedChatroom = chatroomViewData.toBuilder()
                .reactions(reactions)
                .hasReactions(!reactions.isEmpty)
                .build()
            self.chatroomViewData = updatedChatroom
            let message = chatroomDataToConversation(updatedChatroom)
            insertOrUpdateConversationIntoList(message)
            delegate?.reloadChatMessageList()
            return
        }
        guard let conIndex = chatMessages.firstIndex(where: {$0.id == conversationId})
               else {
            return
        }
        let conversation = chatMessages[conIndex]
        var reactions = conversation.reactions ?? []
        if let index = reactions.firstIndex(where: {$0.member?.sdkClientInfo?.uuid == UserPreferences.shared.getClientUUID()}) {  
            reactions.remove(at: index)
        }
        let member = LMChatClient.shared.getMember(request: GetMemberRequest.builder().uuid(UserPreferences.shared.getClientUUID() ?? "").build())?.data?.member
        let reactionData = Reaction.builder()
            .reaction(reaction)
            .member(member)
            .build()
        reactions.append(reactionData)
        let conv = conversation.toBuilder().reactions(reactions).build()
        chatMessages[conIndex] = conv
        insertOrUpdateConversationIntoList(conv)
        delegate?.reloadChatMessageList()
    }
    
    private func updatedReactionsFor(existingReactions: [Reaction], currentReaction: String) -> [Reaction] {
        var reactions = existingReactions
        if let index = reactions.firstIndex(where: {$0.member?.sdkClientInfo?.uuid == UserPreferences.shared.getClientUUID()}) {
            reactions.remove(at: index)
        }
        let member = LMChatClient.shared.getMember(request: GetMemberRequest.builder().uuid(UserPreferences.shared.getClientUUID() ?? "").build())?.data?.member
        let reactionData = Reaction.builder()
            .reaction(currentReaction)
            .member(member)
            .build()
        reactions.append(reactionData)
        return reactions
    }
    
    func putChatroomReaction(chatroomId: String, reaction: String) {
        updateReactionsForUI(reaction: reaction, conversationId: nil, chatroomId: chatroomId)
        let request = PutReactionRequest.builder()
            .chatroomId(chatroomId)
            .reaction(reaction)
            .build()
        LMChatClient.shared.putReaction(request: request) { response in
            guard response.success else {
                return
            }
        }
    }
    
    func deleteConversations(conversationIds: [String]) {
        let request = DeleteConversationsRequest.builder()
            .conversationIds(conversationIds)
            .build()
        LMChatClient.shared.deleteConversations(request: request) {[weak self] response in
            guard response.success else {
                return
            }
            self?.onDeleteConversation(ids: conversationIds)
        }
    }
    
    func deleteTempConversation(conversationId: String) {
//        guard let conversation = chatMessages.first(where: {$0.id == conversationId}) else { return }
//        if let sectionIndex = messagesList.firstIndex(where: {$0.section == conversation.date}) {
//            var section = messagesList[sectionIndex]
//            section.data.removeAll(where: {$0.messageId == conversationId})
//        }
//        LMChatClient.shared.deleteTempConversations(conversationId: conversationId)
    }
    
    func fetchConversation(withId conversationId: String) {
        let request = GetConversationRequest.builder()
            .conversationId(conversationId)
            .build()
        guard let conversation = LMChatClient.shared.getConversation(request: request)?.data?.conversation else { return }
        insertOrUpdateConversationIntoList(conversation)
        delegate?.reloadChatMessageList()
    }
    
    func updateDeletedReaction(conversationId: String?, chatroomId: String?) {
        guard let conversationId, let conversation = chatMessages.first(where: {$0.id == conversationId}) else {
            updateDeletedReactionChatroom(chatroomId: chatroomId)
            return
        }
        var reactions = conversation.reactions ?? []
        reactions.removeAll(where: {$0.member?.sdkClientInfo?.uuid == UserPreferences.shared.getClientUUID()})
        let updatedConversation = conversation.toBuilder()
            .reactions(reactions)
            .hasReactions(!reactions.isEmpty)
            .build()
        insertOrUpdateConversationIntoList(updatedConversation)
        delegate?.reloadChatMessageList()
    }
    
    func updateDeletedReactionChatroom(chatroomId: String?) {
        guard chatroomId != nil, let chatroomViewData else { return }
        var reactions = chatroomViewData.reactions ?? []
        reactions.removeAll(where: {$0.member?.sdkClientInfo?.uuid == UserPreferences.shared.getClientUUID()})
        
        let updatedChatroom = chatroomViewData.toBuilder()
            .reactions(reactions)
            .hasReactions(!reactions.isEmpty)
            .build()
        self.chatroomViewData = updatedChatroom
        let message = chatroomDataToConversation(updatedChatroom)
        insertOrUpdateConversationIntoList(message)
        delegate?.reloadChatMessageList()
    }
    
    func updateConversationUploadingStatus(messageId: String, withStatus status: ConversationStatus) {
        LMChatClient.shared.updateConversationUploadingStatus(withId: messageId, withStatus: status)
    }
    
    private func onDeleteConversation(ids: [String]) {
        for conId in ids {
            if let index = chatMessages.firstIndex(where: {$0.id == conId}) {
                let conversation = chatMessages[index]
                let request = GetMemberRequest.builder()
                    .uuid(memberState?.member?.sdkClientInfo?.uuid ?? "")
                    .build()
                let builder = conversation.toBuilder()
                                .deletedBy(conId)
                                .deletedByMember(LMChatClient.shared.getMember(request: request)?.data?.member)
                let updatedConversation = builder.build()
                chatMessages[index] = updatedConversation
                insertOrUpdateConversationIntoList(updatedConversation)
            }
        }
        delegate?.reloadChatMessageList()
    }
    
    func editConversation(conversationId: String) {
        self.editChatMessage = chatMessages.first(where: {$0.id == conversationId})
    }
    
    func replyConversation(conversationId: String) {
        if let conversation = chatMessages.first(where: {$0.id == conversationId && $0.state != .chatroomDataHeader}) {
            self.replyChatMessage = conversation
        } else {
            self.replyChatroom = conversationId
        }
    }
    
    func setAsCurrentTopic(conversationId: String) {
        chatroomTopic = chatMessages.first(where: {$0.id == conversationId})
        delegate?.updateTopicBar()
        let request = SetChatroomTopicRequest.builder()
            .chatroomId(chatroomId)
            .conversationId(conversationId)
            .build()
        LMChatClient.shared.setChatroomTopic(request: request) {[weak self] response in
            guard let self, response.success else {
                return
            }
        }
    }
    
    func copyConversation(conversationIds: [String]) {
        
        var copiedString: String = ""
        for convId in conversationIds {
            guard let chatMessage = self.chatMessages.first(where: {$0.id == convId}), !chatMessage.answer.isEmpty else {return}
            if conversationIds.count > 1 {
                let answer =  GetAttributedTextWithRoutes.getAttributedText(from: chatMessage.answer.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: GiphyAPIConfiguration.gifMessage, with: ""))
                copiedString = copiedString  + "[\(chatMessage.date ?? ""), \(chatMessage.createdAt ?? "")] \(chatMessage.member?.name ?? ""): \(answer.string) \n"
                //        else if let chatRoom = chatMessage.chatRoom {
                //            let chatroomTitle =  GetTaggedNames.shared.getTaggedAttributedNames(with: chatRoom.title, andPrefix: "", forTextView: true)
                //            copiedString = "[\(chatRoom.date ?? ""), \(chatRoom.createdAt ?? "")] \(chatRoom.member?.name ?? ""): \(chatroomTitle?.string ?? "") "
                //        }
            } else {
                let answer =  GetAttributedTextWithRoutes.getAttributedText(from: chatMessage.answer.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: GiphyAPIConfiguration.gifMessage, with: ""))
                copiedString = copiedString  + "\(answer.string)"
            }
        }
        
        let pasteBoard = UIPasteboard.general
        pasteBoard.string = copiedString
    }
    
    func fetchReplyConversationOnClick(repliedConversationId: String) {
        if let conversation = chatMessages.first(where: {$0.id == repliedConversationId}) {
            messagesList
        } else if let chatroomViewData {
            fetchIntermediateConversations(chatroom: chatroomViewData, conversationId: repliedConversationId)
        }
    }
    
    func postMessageWithAttachment() {
        
    }
    
    func postMessageWithGifAttachment() {
        
    }
    
    func postMessageWithAudioAttachment(with url: URL) {
        print(">>>Audio URL<<<")
        print(url)
        print(">>>Audio URL<<<")
    }
}
