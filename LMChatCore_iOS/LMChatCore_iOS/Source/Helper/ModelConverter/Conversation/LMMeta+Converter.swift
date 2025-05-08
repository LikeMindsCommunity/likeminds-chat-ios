//
//  LMMeta+Converter.swift
//  Pods
//
//  Created by AI on 21/01/25.
//

import LikeMindsChatData
import LikeMindsChatUI

extension LMMeta {
  /**
   Converts an `LMMeta` instance into an `LMMetaViewData`.
  
   - Returns: An `LMMetaViewData` populated with the data from this `LMMeta`.
   */
  public func toViewData() -> LMMetaViewData {
    let metaType = LMMetaViewDataType(rawValue: self.type?.uppercased() ?? "") ?? .UNKNOWN

    return LMMetaViewData(
      sourceChatroomId: self.sourceChatroomId,
      sourceChatroomName: self.sourceChatroomName,
      sourceConversation: self.sourceConversation?.toViewData(),
      type: metaType
    )
  }
}

extension LMMetaViewData {
  /**
   Converts an `LMMetaViewData` instance back into an `LMMeta`.
  
   - Returns: An `LMMeta` created using the data from this `LMMetaViewData`.
   */
  public func toLMMeta() -> LMMeta {
    return LMMeta.builder()
      .sourceChatroomId(self.sourceChatroomId)
      .sourceChatroomName(self.sourceChatroomName)
      .sourceConversation(self.sourceConversation?.toConversation())
      .type(self.type?.rawValue)
      .build()
  }
}
