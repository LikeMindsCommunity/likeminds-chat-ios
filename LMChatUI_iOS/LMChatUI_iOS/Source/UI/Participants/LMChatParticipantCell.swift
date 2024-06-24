//
//  LMChatParticipantCell.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 16/02/24.
//

import Foundation
import Kingfisher

@IBDesignable
open class LMChatParticipantCell: LMTableViewCell {
    
    public struct ContentModel {
        public let id: String?
        public let name: String
        public let designationDetail: String?
        public let profileImageUrl: String?
        public let customTitle: String?
        
        public init(id: String?, name: String, designationDetail: String?, profileImageUrl: String?, customTitle: String?) {
            self.id = id
            self.name = name
            self.designationDetail = designationDetail
            self.profileImageUrl = profileImageUrl
            self.customTitle = customTitle
        }
    }
    
    // MARK: UI Elements
    open private(set) lazy var participantView: LMChatParticipantView = {
        let view = LMUIComponents.shared.participantView.init().translatesAutoresizingMaskIntoConstraints()
        view.clipsToBounds = true
        return view
    }()
    
    open private(set) lazy var sepratorView: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        return view
    }()
    
    
    // MARK: setupViews
    open override func setupViews() {
        super.setupViews()
        
        contentView.addSubview(containerView)
        containerView.addSubview(participantView)
        containerView.addSubview(sepratorView)
    }
    
    
    // MARK: setupLayouts
    open override func setupLayouts() {
        super.setupLayouts()
        contentView.pinSubView(subView: containerView)
        NSLayoutConstraint.activate([
            participantView.topAnchor.constraint(equalTo: containerView.topAnchor),
            participantView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            participantView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            participantView.bottomAnchor.constraint(equalTo: sepratorView.topAnchor),
            sepratorView.leadingAnchor.constraint(equalTo: participantView.profileImageView.leadingAnchor, constant: 5),
            sepratorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            sepratorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            sepratorView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    
    // MARK: setupAppearance
    open override func setupAppearance() {
        super.setupAppearance()
        sepratorView.backgroundColor = Appearance.shared.colors.gray4
        backgroundColor = Appearance.shared.colors.clear
        contentView.backgroundColor = Appearance.shared.colors.clear
    }
    
    
    // MARK: configure
    open func configure(with data: ContentModel) {
        participantView.setData(.init(name: data.name, designationDetail: data.designationDetail, profileImageUrl: data.profileImageUrl, customTitle: data.customTitle, isPending: false))
    }
}


