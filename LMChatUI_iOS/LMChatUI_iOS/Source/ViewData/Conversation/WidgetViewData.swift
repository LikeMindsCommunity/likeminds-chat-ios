//
//  WidgetViewData.swift
//  Pods
//
//  Created by Anurag Tyagi on 21/01/25.
//

import Foundation

/// A view-data class that mirrors the properties of `Widget`.
///
/// This class is mutable and can be used in UI layers or intermediate layers where flexibility in modifying properties is required.
public class WidgetViewData {
  // MARK: - Properties
  public var id: String?
  public var parentEntityID: String?
  public var parentEntityType: String?
  public var metadata: [String: Any]?
  public var createdAt: Double?
  public var updatedAt: Double?
  public var lmMeta: LMMetaViewData?

  // MARK: - Initializer
  /**
   Initializes a new `WidgetViewData`.
  
   - Parameters:
     - id: The unique identifier of the widget.
     - parentEntityID: The ID of the parent entity associated with the widget.
     - parentEntityType: The type of the parent entity.
     - metadata: Metadata associated with the widget.
     - createdAt: The creation timestamp of the widget.
     - updatedAt: The last update timestamp of the widget.
     - lmMeta: Additional metadata related to LikeMinds.
   */
  public init(
    id: String?,
    parentEntityID: String?,
    parentEntityType: String?,
    metadata: [String: Any]?,
    createdAt: Double?,
    updatedAt: Double?,
    lmMeta: LMMetaViewData?
  ) {
    self.id = id
    self.parentEntityID = parentEntityID
    self.parentEntityType = parentEntityType
    self.metadata = metadata
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.lmMeta = lmMeta
  }
}
