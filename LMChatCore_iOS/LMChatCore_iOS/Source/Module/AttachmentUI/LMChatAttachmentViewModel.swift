//
//  LMChatAttachmentViewModel.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 13/03/24.
//

import Foundation
import LikeMindsChatUI
import LikeMindsChat

public protocol LMChatAttachmentViewModelProtocol: LMBaseViewControllerProtocol {
}

public final class LMChatAttachmentViewModel {
    
    weak var delegate: LMChatAttachmentViewModelProtocol?
    var chatroomId: String?
    var mediaCellData: [MediaPickerModel] = []
    var selectedMedia: MediaPickerModel?
    var mediaType: MediaType?
    var sourceType: LMAttachmentSourceType = .photoLibrary
    
    public enum LMAttachmentSourceType {
        case camera
        case photoLibrary
        case document
        case audio
        case giphy
    }
    
    init(delegate: LMChatAttachmentViewModelProtocol?) {
        self.delegate = delegate
    }
    
    public static func createModule(delegate: LMChatAttachmentViewDelegate?, chatroomId: String?, sourceType: LMAttachmentSourceType) throws -> LMChatAttachmentViewController {
        guard LMChatMain.isInitialized else { throw LMChatError.chatNotInitialized }
        
        let viewcontroller = LMCoreComponents.shared.attachmentMessageScreen.init()
        viewcontroller.delegate = delegate
        let viewmodel = Self.init(delegate: viewcontroller)
        viewmodel.chatroomId = chatroomId
        viewmodel.sourceType = sourceType
        viewcontroller.viewModel = viewmodel
        return viewcontroller
    }
    
    public static func createModuleWithData(mediaData: [MediaPickerModel], delegate: LMChatAttachmentViewDelegate?, chatroomId: String?, mediaType: MediaType) throws -> LMChatAttachmentViewController {
        guard LMChatMain.isInitialized else { throw LMChatError.chatNotInitialized }
        
        let viewcontroller = LMCoreComponents.shared.attachmentMessageScreen.init()
        viewcontroller.delegate = delegate
        let viewmodel = Self.init(delegate: viewcontroller)
        viewmodel.chatroomId = chatroomId
        viewmodel.mediaCellData = mediaData
        viewmodel.mediaType = mediaType
        viewcontroller.viewModel = viewmodel
        return viewcontroller
    }
    
}
