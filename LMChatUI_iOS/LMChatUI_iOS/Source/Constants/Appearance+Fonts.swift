//
//  Appearance+Fonts.swift
//  LMFramework
//
//  Created by Devansh Mohata on 07/12/23.
//

import UIKit

public extension Appearance {
    struct Fonts {
        private init() { }
        
        // Shared Instance
        public static var shared = Fonts()
        
        // Variables
        public var headingFont: UIFont = .systemFont(ofSize: 18, weight: .medium)
        public var headingFont1: UIFont = .systemFont(ofSize: 16, weight: .medium)
        public var headingFont2: UIFont = .systemFont(ofSize: 12, weight: .medium)
        public var headingFont3: UIFont = .systemFont(ofSize: 14, weight: .medium)
        public var subHeadingFont1: UIFont = .systemFont(ofSize: 12)
        public var subHeadingFont2: UIFont = .systemFont(ofSize: 14)
        public var textFont1: UIFont = .systemFont(ofSize: 16)
        public var textFont2: UIFont = .systemFont(ofSize: 14)
        public var buttonFont1: UIFont = .systemFont(ofSize: 14)
        public var buttonFont2: UIFont = .systemFont(ofSize: 16)
        public var buttonFont3: UIFont = .systemFont(ofSize: 12, weight: .bold)
        public var navigationTitleFont: UIFont = .systemFont(ofSize: 18, weight: .bold)
        public var navigationSubtitleFont: UIFont = .systemFont(ofSize: 14)
        public var normalFontSize11: UIFont = .systemFont(ofSize: 11)
        public var normalFontSize12: UIFont = .systemFont(ofSize: 12)
        public var emojiTrayFont: UIFont = .systemFont(ofSize: 30)
        public var headingLabel: UIFont = .systemFont(ofSize: 16, weight: .bold)
        public var italicFont16:UIFont = .italicSystemFont(ofSize: 16)
        public var italicFont13:UIFont = .italicSystemFont(ofSize: 13)
        public var italicFont14:UIFont = .italicSystemFont(ofSize: 14)
    }
}
