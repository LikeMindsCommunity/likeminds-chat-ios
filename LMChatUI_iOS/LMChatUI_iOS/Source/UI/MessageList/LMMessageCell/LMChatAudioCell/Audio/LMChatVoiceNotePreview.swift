//
//  LMChatVoiceNotePreview.swift
//  LikeMindsChatUI
//
//  Created by Devansh Mohata on 17/04/24.
//

import UIKit

public protocol LMChatAudioProtocol: AnyObject {
    func didTapPlayPauseButton(for url: String, index: IndexPath)
    func didSeekTo(_ position: Float, _ url: String, index: IndexPath)
    func pauseAudioPlayer()
}

public struct LMChatAudioContentModel {
    let fileName: String?
    let url: String?
    let duration: Int
    let thumbnail: String?
    
    public init(fileName: String?, url: String?, duration: Int, thumbnail: String?) {
        self.fileName = fileName
        self.url = url
        self.duration = duration
        self.thumbnail = thumbnail
    }
}

open class LMChatVoiceNotePreview: LMView {
    // MARK: UI Elements
    open private(set) lazy var containerView: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        return view
    }()
    
    open private(set) lazy var playPauseButton: LMImageView = {
        let button = LMImageView().translatesAutoresizingMaskIntoConstraints()
        button.image = Constants.shared.images.playCircleFilled
        button.contentMode = .scaleAspectFill
        button.isUserInteractionEnabled = true
        return button
    }()
    
    open private(set) lazy var slider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.setThumbImage(UIImage(systemName: "circle.fill"), for: .normal)
        return slider
    }()
    
    
    open private(set) lazy var img: LMImageView = {
        let image = LMImageView().translatesAutoresizingMaskIntoConstraints()
        image.image = Constants.shared.images.micFillIcon
        return image
    }()
    
    open private(set) lazy var durationLbl: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.text = "00:00"
        label.textColor = Appearance.shared.colors.black
        label.font = .systemFont(ofSize: 10)
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
        
        containerView.addSubview(playPauseButton)
        containerView.addSubview(slider)
        containerView.addSubview(img)
        containerView.addSubview(durationLbl)
    }
    
    
    // MARK: setupLayouts
    override open func setupLayouts() {
        pinSubView(subView: containerView)
        
        playPauseButton.addConstraint(top: (containerView.topAnchor, 16),
                                      leading: (containerView.leadingAnchor, 12))
        playPauseButton.setHeightConstraint(with: 36)
        playPauseButton.setWidthConstraint(with: playPauseButton.heightAnchor)
        
        slider.addConstraint(leading: (playPauseButton.trailingAnchor, 6),
                             trailing: (containerView.trailingAnchor, -8),
                             centerY: (playPauseButton.centerYAnchor, 0))
        slider.setHeightConstraint(with: 10)
        
        img.addConstraint(top: (playPauseButton.bottomAnchor, 0),
                          bottom: (containerView.bottomAnchor, -4),
                          leading: (slider.leadingAnchor, 0))
        img.setHeightConstraint(with: UIFont.systemFont(ofSize: 10).lineHeight)
        img.setWidthConstraint(with: img.heightAnchor)
        
        durationLbl.addConstraint(leading: (img.trailingAnchor, 4),
                                  centerY: (img.centerYAnchor, 0))
        durationLbl.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -4).isActive = true
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
        case .began:
            delegate?.didTapPlayPauseButton(for: url, index: index)
        case .ended:
            delegate?.didSeekTo(slider.value, url, index: index)
        default:
            break
        }
    }
    
    
    // MARK: configure
    open func configure(with data: LMChatAudioContentModel, delegate: LMChatAudioProtocol?, index: IndexPath) {
        self.url = data.url
        self.duration = data.duration
        self.index = index
        durationLbl.text = convertSecondsToFormattedTime(seconds: data.duration)
        self.delegate = delegate
    }
    
    
    // Updates Seeker value when needed! (0 - 100)
    open func updateSeekerValue(with time: Float, for url: String) {
        guard self.url == url else { return }
        isPlaying = true
        let percentage = (time / Float(duration)) * 100
        slider.value = self.url == url ? percentage : .zero
        playPauseButton.image = self.url == url ? Constants.shared.images.pauseCircleFilled : Constants.shared.images.playCircleFilled
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
