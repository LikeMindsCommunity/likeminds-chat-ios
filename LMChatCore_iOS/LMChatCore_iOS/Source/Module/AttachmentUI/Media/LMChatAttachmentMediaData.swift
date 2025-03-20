//
//  AttachmentMediaData.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 12/04/24.
//

import Foundation
import PhotosUI

public struct LMChatAttachmentMediaData {
    
    let url: URL?
    let fileType: MediaType
    let width: Int?
    let height: Int?
    let thumbnailurl: URL?
    let size: Int?
    let mediaName: String?
    let pdfPageCount: Int?
    let duration: Int?
    let awsFolderPath: String?
    let thumbnailAwsPath: String?
    let format: String?
    let image: UIImage?
    let livePhoto: PHLivePhoto?
    
    init(url: URL?,
         fileType: MediaType,
         width: Int?,
         height: Int?,
         thumbnailurl: URL?,
         size: Int?,
         mediaName: String?,
         pdfPageCount: Int?,
         duration: Int?,
         awsFolderPath: String?,
         thumbnailAwsPath: String?,
         format: String?,
         image: UIImage?,
         livePhoto: PHLivePhoto?) {
        self.url = url
        self.fileType = fileType
        self.width = width
        self.height = height
        self.thumbnailurl = thumbnailurl
        self.size = size
        self.mediaName = mediaName
        self.pdfPageCount = pdfPageCount
        self.duration = duration
        self.awsFolderPath = awsFolderPath
        self.format = format
        self.image = image
        self.livePhoto = livePhoto
        self.thumbnailAwsPath = thumbnailAwsPath
    }
    
    static func builder() -> Builder {
        return Builder()
    }

    class Builder {
        private var url: URL?
        private var fileType: MediaType = .image
        private var width: Int?
        private var height: Int?
        private var thumbnailurl: URL?
        private var size: Int?
        private var mediaName: String?
        private var pdfPageCount: Int?
        private var duration: Int?
        private var awsFolderPath: String?
        private var thumbnailAwsPath: String?
        private var format: String?
        private var image: UIImage?
        private var livePhoto: PHLivePhoto?
        
        func url(_ url: URL?) -> Builder {
            self.url = url
            return self
        }
        
        func fileType(_ fileType: MediaType) -> Builder {
            self.fileType = fileType
            return self
        }
        
        func width(_ width: Int?) -> Builder {
            self.width = width
            return self
        }
        
        func height(_ height: Int?) -> Builder {
            self.height = height
            return self
        }
        
        func thumbnailurl(_ thumbnailurl: URL?) -> Builder {
            self.thumbnailurl = thumbnailurl
            return self
        }
        
        func size(_ size: Int?) -> Builder {
            self.size = size
            return self
        }
        
        func mediaName(_ mediaName: String?) -> Builder {
            self.mediaName = mediaName
            return self
        }
        
        func pdfPageCount(_ pdfPageCount: Int?) -> Builder {
            self.pdfPageCount = pdfPageCount
            return self
        }
        
        func duration(_ duration: Int?) -> Builder {
            self.duration = duration
            return self
        }
        
        func awsFolderPath(_ awsFolderPath: String?) -> Builder {
            self.awsFolderPath = awsFolderPath
            return self
        }
        
        func thumbnailAwsPath(_ thumbnailAwsPath: String?) -> Builder {
            self.thumbnailAwsPath = thumbnailAwsPath
            return self
        }
        
        func format(_ format: String?) -> Builder {
            self.format = format
            return self
        }
        
        func image(_ image: UIImage?) -> Builder {
            self.image = image
            return self
        }
        
        func livePhoto(_ livePhoto: PHLivePhoto?) -> Builder {
            self.livePhoto = livePhoto
            return self
        }
        
        func build() -> LMChatAttachmentMediaData {
            return LMChatAttachmentMediaData(url: url!,
                                             fileType: fileType,
                                             width: width,
                                             height: height,
                                             thumbnailurl: thumbnailurl,
                                             size: size,
                                             mediaName: mediaName,
                                             pdfPageCount: pdfPageCount,
                                             duration: duration,
                                             awsFolderPath: awsFolderPath,
                                             thumbnailAwsPath: thumbnailAwsPath,
                                             format: format,
                                             image: image,
                                             livePhoto: livePhoto)
        }
    }
}
