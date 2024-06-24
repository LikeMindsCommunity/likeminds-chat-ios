//
//  String+Extension.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 11/04/24.
//

import Foundation

extension String {
    var detectedLinks: [String] { DataDetector.find(all: .link, in: self) }
    var detectedFirstLink: String? { DataDetector.first(type: .link, in: self) }
    
    func getQueryItems() -> [String : String] {
        var queryItems: [String : String] = [:]
        let components: NSURLComponents? = self.getURLComonents()
        for item in components?.queryItems ?? [] {
            queryItems[item.name] = item.value?.removingPercentEncoding
        }
        return queryItems
    }
    
    func getURLComonents() -> NSURLComponents? {
        var components: NSURLComponents? = nil
        let linkUrl = URL(string: self.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? "")
        if let linkUrl = linkUrl {
            components = NSURLComponents(url: linkUrl, resolvingAgainstBaseURL: true)
        }
        return components
    }
}
