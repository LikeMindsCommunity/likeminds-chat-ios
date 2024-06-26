//
//  LMChatEmojiCollectionCell.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 08/05/24.
//

import Foundation

open class LMChatEmojiCollectionCell: LMCollectionViewCell {
    
    public struct ContentModel {
        let emojiIcon: String
        public init(emojiIcon: String) {
            self.emojiIcon = emojiIcon
        }
    }
    
    open private(set) lazy var titleLabel: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.font = Appearance.shared.fonts.emojiTrayFont
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupLayouts()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
        setupLayouts()
    }
    
    open override func setupViews() {
        super.setupViews()
        contentView.addSubview(containerView)
        containerView.addSubview(titleLabel)
    }
    
    open override func setupLayouts() {
        super.setupLayouts()
        contentView.pinSubView(subView: containerView)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
    }
    
    open func configure(data: ContentModel) {
        titleLabel.text = data.emojiIcon
    }
}
