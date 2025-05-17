//
//  Widget+Converter.swift
//  Pods
//
//  Created by Anurag Tyagi on 21/01/25.
//

import LikeMindsChatData
import LikeMindsChatUI

extension Widget {
  /**
   Converts a `Widget` instance into a `WidgetViewData`.
  
   - Returns: A `WidgetViewData` populated with the data from this `Widget`.
   */
  public func toViewData() -> WidgetViewData {
    return WidgetViewData(
      id: self.id,
      parentEntityID: self.parentEntityID,
      parentEntityType: self.parentEntityType,
      metadata: self.metadata,
      createdAt: self.createdAt,
      updatedAt: self.updatedAt,
      lmMeta: self.lmMeta?.toViewData()
    )
  }
}

extension WidgetViewData {
  /**
   Converts a `WidgetViewData` instance back into a `Widget`.
  
   - Returns: A `Widget` created using the data from this `WidgetViewData`.
   */
  public func toWidget() -> Widget {
    return Widget.Builder()
      .id(self.id)
      .parentEntityID(self.parentEntityID)
      .parentEntityType(self.parentEntityType)
      .metadata(self.metadata)
      .createdAt(self.createdAt)
      .updatedAt(self.updatedAt)
      .lmMeta(self.lmMeta?.toLMMeta())
      .build()
  }
}
