//
//  LMMetaViewData.swift
//  Pods
//
//  Created by AI on 21/01/25.
//

import Foundation

public enum LMMetaViewDataType: String {
  case REPLY_PRIVATELY = "REPLY_PRIVATELY"
  case UNKNOWN = "UNKNOWN"
}

/// A view-data class that mirrors the properties of `LMMeta`.
///
/// This class is mutable and can be used in UI layers or intermediate layers
/// where flexibility in modifying properties is required.
public class LMMetaViewData {
  // MARK: - Properties
  public var sourceChatroomId: String?
  public var sourceChatroomName: String?
  public var sourceConversation: ConversationViewData?
  public var type: LMMetaViewDataType?

  // MARK: - Initializer
  public init(
    sourceChatroomId: String?,
    sourceChatroomName: String?,
    sourceConversation: ConversationViewData?,
    type: LMMetaViewDataType?
  ) {
    self.sourceChatroomId = sourceChatroomId
    self.sourceChatroomName = sourceChatroomName
    self.sourceConversation = sourceConversation
    self.type = type
  }

  // MARK: - Builder Pattern
  public class Builder {
    private var sourceChatroomId: String?
    private var sourceChatroomName: String?
    private var sourceConversation: ConversationViewData?
    private var type: LMMetaViewDataType?

    public init() {}

    public func sourceChatroomId(_ sourceChatroomId: String?) -> Builder {
      self.sourceChatroomId = sourceChatroomId
      return self
    }

    public func sourceChatroomName(_ sourceChatroomName: String?) -> Builder {
      self.sourceChatroomName = sourceChatroomName
      return self
    }

    public func sourceConversation(_ sourceConversation: ConversationViewData?) -> Builder {
      self.sourceConversation = sourceConversation
      return self
    }

    public func type(_ type: LMMetaViewDataType?) -> Builder {
      self.type = type
      return self
    }

    public func build() -> LMMetaViewData {
      return LMMetaViewData(
        sourceChatroomId: sourceChatroomId,
        sourceChatroomName: sourceChatroomName,
        sourceConversation: sourceConversation,
        type: type
      )
    }
  }
}
