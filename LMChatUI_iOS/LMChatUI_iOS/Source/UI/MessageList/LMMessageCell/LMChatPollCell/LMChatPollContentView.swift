//
//  LMChatPollContentView.swift
//  LikeMindsChat
//
//  Created by Pushpendra Singh on 24/07/24.
//

import Foundation


open class LMChatPollContentView: LMChatMessageContentView {
    
    open private(set) lazy var pollDisplayView: LMChatPollView = {
        let view = LMUIComponents.shared.pollDisplayView.init().translatesAutoresizingMaskIntoConstraints()
        view.backgroundColor = .clear
        view.cornerRadius(with: 12)
        return view
    }()
    
    
    // MARK: setupViews
    open override func setupViews() {
        super.setupViews()
        bubbleView.addArrangeSubview(pollDisplayView, atIndex: 2)
        pollDisplayView.addSubview(cancelRetryContainerStackView)
    }
    
    // MARK: setupLayouts
    open override func setupLayouts() {
        super.setupLayouts()
        pollDisplayView.widthAnchor.constraint(equalToConstant: Self.widthOfScreen * 0.70).isActive = true
        cancelRetryContainerStackView.centerXAnchor.constraint(equalTo: pollDisplayView.centerXAnchor).isActive = true
        cancelRetryContainerStackView.centerYAnchor.constraint(equalTo: pollDisplayView.centerYAnchor).isActive = true

    }
    
    open override func setDataView(_ data: LMChatMessageCell.ContentModel, index: IndexPath) {
        super.setDataView(data, index: index)
        self.textLabel.isHidden = true
        updateRetryButton(data)
        if data.message?.isDeleted == true {
            pollDisplayView.isHidden = true
        } else {
            pollDisplayPreview(data.message?.pollData)
        }
        pollDisplayView.bringSubviewToFront(cancelRetryContainerStackView)
        bubbleView.layoutIfNeeded()
    }

    func pollDisplayPreview(_ pollData: LMChatPollView.ContentModel?) {
        guard let pollData else {
            pollDisplayView.isHidden = true
            return
        }
        pollDisplayView.isHidden = false
        pollDisplayView.configure(with: pollData, delegate: nil)
    }
     
    func updateRetryButton(_ data: LMChatMessageCell.ContentModel) {
        loaderView.isHidden = !(data.message?.messageStatus == .sending)
        retryView.isHidden = !(data.message?.messageStatus == .failed)
    }
    
    override func prepareToResuse() {
        super.prepareToResuse()
    }
}
