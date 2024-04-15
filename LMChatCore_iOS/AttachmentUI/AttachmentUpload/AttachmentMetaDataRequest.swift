//
//  AttachmentMetaDataRequest.swift
//  LMChatCore_iOS
//
//  Created by Pushpendra Singh on 15/04/24.
//

import Foundation

import Foundation

class AttachmentMetaDataRequest: NSObject, NSCoding {
    let numberOfPage: Int?
    let size: Int64?
    let duration: Int?
    
    init(numberOfPage: Int?,
         size: Int64?,
         duration: Int?) {
        self.numberOfPage = numberOfPage
        self.size = size
        self.duration = duration
    }
    
    static func builder() -> Builder {
        Builder()
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let numberOfPage = aDecoder.decodeObject(forKey: "numberOfPage") as? Int
        let size = aDecoder.decodeObject(forKey: "size") as? Int64
        let duration = aDecoder.decodeObject(forKey: "duration") as? Int
        self.init(numberOfPage: numberOfPage, size: size, duration: duration)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(numberOfPage, forKey: "numberOfPage")
        aCoder.encode(size, forKey: "size")
        aCoder.encode(duration, forKey: "duration")
    }
    
    class Builder {
        private var numberOfPage: Int?
        private var size: Int64?
        private var duration: Int?
        
        func numberOfPage(_ numberOfPage: Int?) -> Builder {
            self.numberOfPage = numberOfPage
            return self
        }
        
        func size(_ size: Int64?) -> Builder {
            self.size = size
            return self
        }
        
        func duration(_ duration: Int?) -> Builder {
            self.duration = duration
            return self
        }
        
        func build() -> AttachmentMetaDataRequest {
            return AttachmentMetaDataRequest(numberOfPage: numberOfPage,
                                          size: size,
                                          duration: duration)
        }
    }
    
    func toBuilder() -> Builder {
        return Builder()
            .numberOfPage(numberOfPage)
            .size(size)
            .duration(duration)
    }
}