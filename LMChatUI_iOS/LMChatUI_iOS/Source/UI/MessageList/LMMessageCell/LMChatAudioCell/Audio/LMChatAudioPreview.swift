//
//  LMChatAudioPreview.swift
//  LikeMindsChatUI
//
//  Created by Devansh Mohata on 17/04/24.
//

import Kingfisher
import UIKit

public extension Notification.Name {
    static let audioDurationUpdate = Notification.Name("Audio Duration Updated")
}

open class LMChatAudioPreview: LMView {
    // MARK: UI Elements
    open private(set) lazy var containerView: LMView = {
        let view = LMView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
        
    open private(set) lazy var thumbnailImage: LMImageView = {
        let imageView = LMImageView().translatesAutoresizingMaskIntoConstraints()
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        return imageView
    }()
    
    open private(set) lazy var headphoneContainerView: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        view.cornerRadius(with: 12)
        view.backgroundColor = Appearance.shared.colors.black.withAlphaComponent(0.6)
        return view
    }()
    
    open private(set) lazy var headphoneImage: LMImageView = {
        let imageView = LMImageView().translatesAutoresizingMaskIntoConstraints()
        imageView.image = Constants.shared.images.audioIcon.withSystemImageConfig(pointSize: 30)
        imageView.contentMode = .center
        imageView.tintColor = .white
        return imageView
    }()
    
    open private(set) lazy var durationLbl: LMLabel = {
        let label = LMLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "00:00"
        label.textAlignment = .center
        label.textColor = .white
        label.font = .systemFont(ofSize: 10)
        return label
    }()
    
    open private(set) lazy var playPauseButton: LMImageView = {
        let button = LMImageView()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.image = Constants.shared.images.playCircleFilled
        button.contentMode = .scaleAspectFill
        button.isUserInteractionEnabled = true
        return button
    }()
    
    open private(set) lazy var slider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.setThumbImage(Constants.shared.images.circleFill, for: .normal)
        return slider
    }()
    
    open private(set) lazy var titleLabel: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.text = "Audio"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .lightGray
        return label
    }()
    
    
    weak var delegate: LMChatAudioProtocol?
    var url: String?
    var duration = 0
    var index: IndexPath?
    var isPlaying: Bool = false
    
    
    // MARK: setupViews
    override open func setupViews() {
        super.setupViews()
        
        addSubview(containerView)
        
        containerView.addSubview(thumbnailImage)
        containerView.addSubview(headphoneContainerView)
        
        headphoneContainerView.addSubview(headphoneImage)
        headphoneContainerView.addSubview(durationLbl)
        
        containerView.addSubview(playPauseButton)
        containerView.addSubview(slider)
        containerView.addSubview(durationLbl)
        containerView.addSubview(titleLabel)
    }
    
    
    // MARK: setupLayouts
    override open func setupLayouts() {
        pinSubView(subView: containerView)
        
        thumbnailImage.addConstraint(top: (containerView.topAnchor, 0),
                                     bottom: (containerView.bottomAnchor, 0),
                                     leading: (containerView.leadingAnchor, 0))
        
        thumbnailImage.pinSubView(subView: headphoneContainerView)
        thumbnailImage.setWidthConstraint(with: thumbnailImage.heightAnchor)
        
        headphoneImage.addConstraint(top: (headphoneContainerView.topAnchor, 4),
                                     leading: (headphoneContainerView.leadingAnchor, 4),
                                     trailing: (headphoneContainerView.trailingAnchor, -4))
        
        durationLbl.topAnchor.constraint(equalTo: headphoneImage.bottomAnchor, constant: 2).isActive = true
        durationLbl.leadingAnchor.constraint(equalTo: headphoneContainerView.leadingAnchor, constant: 4).isActive = true
        durationLbl.trailingAnchor.constraint(equalTo: headphoneContainerView.trailingAnchor, constant: -4).isActive = true
        durationLbl.bottomAnchor.constraint(equalTo: headphoneContainerView.bottomAnchor, constant: -4).isActive = true
        
        titleLabel.addConstraint(bottom: (thumbnailImage.bottomAnchor, -8),
                                 leading: (thumbnailImage.trailingAnchor, 8),
                                 trailing: (containerView.trailingAnchor, -8))
        
        playPauseButton.addConstraint(top: (thumbnailImage.topAnchor, 8),
                                      bottom: (titleLabel.topAnchor, -6),
                                      leading: (thumbnailImage.trailingAnchor, 8))
        playPauseButton.setHeightConstraint(with: 36)
        playPauseButton.setWidthConstraint(with: playPauseButton.heightAnchor)
        
        slider.addConstraint(leading: (playPauseButton.trailingAnchor, 4),
                             trailing: (containerView.trailingAnchor, -4),
                             centerY: (playPauseButton.centerYAnchor, 0))
        slider.setHeightConstraint(with: 10)
    }
    
    
    // MARK: setupActions
    override open func setupActions() {
        playPauseButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapPlayPauseButton)))
        slider.addTarget(self, action: #selector(didSeekPlayer), for: .valueChanged)
        slider.minimumValue = 0
        slider.maximumValue = 100
    }
    
    
    // MARK: setupAppearance
    override open func setupAppearance() {
        super.setupAppearance()
        containerView.backgroundColor = .gray.withAlphaComponent(0.1)
    }
    
    @objc
    open func didTapPlayPauseButton() {
        guard let url,
        let index else { return }
        
        if isPlaying {
            playPauseButton.image = Constants.shared.images.playCircleFilled
            isPlaying.toggle()
        }
        
        delegate?.didTapPlayPauseButton(for: url, index: index)
    }
    
    @objc
    open func didSeekPlayer(slider: UISlider, event: UIEvent) {
        guard let index,
              let url,
              let touchEvent = event.allTouches?.first else { return }
        switch touchEvent.phase {
        case .ended:
            delegate?.didSeekTo(slider.value, url, index: index)
        default:
            delegate?.pauseAudioPlayer()
        }
    }
    
    
    // MARK: configure
    open func configure(with data: LMChatAudioContentModel, delegate: LMChatAudioProtocol?, index: IndexPath) {
        titleLabel.text = data.fileName
        titleLabel.isHidden = data.fileName?.isEmpty != false
        url = data.url
        duration = data.duration
        self.index = index
        self.delegate = delegate
        durationLbl.text = convertSecondsToFormattedTime(seconds: data.duration)
        thumbnailImage.kf.setImage(with: URL(string: data.thumbnail ?? ""))
    }
    
    
    // Updates Seeker value when needed! (0 - 100)
    open func updateSeekerValue(with time: Float, for url: String) {
        guard self.url == url else { return }
        isPlaying = true
        let percentage = (time / Float(duration)) * 100
        slider.value = self.url == url ? percentage : .zero
        playPauseButton.image =  self.url == url ?  Constants.shared.images.pauseCircleFilled : Constants.shared.images.playCircleFilled
        durationLbl.text = convertSecondsToFormattedTime(seconds: Int(time))
    }
    
    open func resetView() {
        playPauseButton.image = Constants.shared.images.playCircleFilled
        durationLbl.text = convertSecondsToFormattedTime(seconds: duration)
        isPlaying = false
        slider.value = 0
    }
    
    func convertSecondsToFormattedTime(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let seconds = seconds % 60
        
        if hours > 0 {
            return String(format: "%i:%02i:%02i", hours, minutes, seconds)
        } else {
            return String(format: "%02i:%02i", minutes, seconds)
        }
    }
}
