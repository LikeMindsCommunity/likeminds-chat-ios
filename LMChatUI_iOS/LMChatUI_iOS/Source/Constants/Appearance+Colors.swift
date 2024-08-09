//
//  Appearance+Fonts.swift
//  LMFramework
//
//  Created by Devansh Mohata on 07/12/23.
//

import UIKit

public extension Appearance {
    struct Colors {
        private init() { }
        
        // Shared Instance
        public static var shared = Colors()
        
        // Custom Colors
        public var gray1: UIColor = UIColor(r: 34, g: 32, b: 32)
        public var gray2: UIColor = UIColor(r: 80, g: 75, b: 75)
        public var gray3: UIColor = UIColor(r: 15, g: 30, b: 61, a: 0.4)
        public var gray4: UIColor = UIColor(r: 208, g: 216, b: 226, a: 0.4)
        public var gray51: UIColor = UIColor(r: 51, g: 51, b: 51)
        public var gray102: UIColor = UIColor(r: 102, g: 102, b: 102)
        public var gray155: UIColor = UIColor(r: 155, g: 155, b: 155)
        public var blueGray: UIColor = UIColor(r: 72, g: 79, b: 103)
        public var textColor: UIColor = UIColor(r: 102, g: 102, b: 102)
        public var backgroundColor: UIColor = UIColor(r: 209, g: 216, b: 225)
        public var navigationTitleColor: UIColor = UIColor(r: 51, g: 51, b: 51)
        public var navigationBackgroundColor: UIColor = UIColor(r: 249, g: 249, b: 249, a: 0.94)
        public var notificationBackgroundColor: UIColor = UIColor(r: 172, g: 183, b: 192)
        
        public var previewBackgroundColor: UIColor = UIColor(hex: 0xD0D8E2)
        public var previewSubtitleTextColor: UIColor = UIColor(r: 60, g: 60, b: 67, a: 0.6)
        
        public var incomingColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        public var outgoingColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1) //UIColor(red: 0.88, green: 0.99, blue: 0.98, alpha: 1)
        public var appTintColor: UIColor = .link
        public var pollOptionBorderColor: UIColor =  .link.withAlphaComponent(0.3)//UIColor(hex: 0x06C3AF, alpha: 0.3)
        public var secondaryBackgroundColor: UIColor = UIColor(hex: 0xF2F2F7)
        // UIKit Colors
        public var white: UIColor = .white
        public var black: UIColor = .black
        public var clear: UIColor = .clear
        public var red: UIColor = .systemRed
        public var userProfileColor: UIColor = .blue
        public var linkColor: UIColor = .link
        public var hashtagColor: UIColor = .blue
        public var systemYellow: UIColor = .systemYellow
    }
}
