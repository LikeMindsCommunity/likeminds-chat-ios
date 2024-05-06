//
//  BottomMessageComposerView.swift
//  LMChatCore_iOS
//
//  Created by Pushpendra Singh on 31/01/24.
//

import AVFoundation
import LMChatUI_iOS
import UIKit

public protocol LMBottomMessageComposerDelegate: AnyObject {
    func composeMessage(message: String)
    func composeAttachment()
    func composeAudio()
    func composeGif()
    func linkDetected(_ link: String)
    
    func audioRecordingStarted()
    func audioRecordingEnded()
    func playRecording()
    func stopRecording(_ onStop: (() -> Void))
    func deleteRecording()
    
    func cancelReply()
    func cancelLinkPreview()
}

@IBDesignable
open class LMBottomMessageComposerView: LMView {
    
    open weak var delegate: LMBottomMessageComposerDelegate?
    let audioButtonTag = 10
    let messageButtonTag = 11
    
    // MARK: UI Elements
    open private(set) lazy var containerView: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
//        view.backgroundColor = Appearance.shared.colors.backgroundColor
        return view
    }()
    
    open private(set) lazy var topSeparatorView: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        view.backgroundColor = Appearance.shared.colors.gray155
        return view
    }()
    
    open private(set) lazy var addOnVerticleStackView: LMStackView = {
        let view = LMStackView().translatesAutoresizingMaskIntoConstraints()
        view.axis = .vertical
        view.distribution = .fill
        view.spacing = 0
        return view
    }()
    
    open private(set) lazy var horizontalStackView: LMStackView = {
        let view = LMStackView().translatesAutoresizingMaskIntoConstraints()
        view.axis = .horizontal
        view.spacing = 12
        return view
    }()
    
    open private(set) lazy var inputTextContainerView: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        view.cornerRadius(with: 18)
        view.backgroundColor = .white
        view.borderColor(withBorderWidth: 1, with: Appearance.shared.colors.gray155)
        return view
    }()
    
    open private(set) lazy var inputTextAndGifHorizontalStackView: LMStackView = {
        let view = LMStackView().translatesAutoresizingMaskIntoConstraints()
        view.axis = .horizontal
        view.spacing = 8
        return view
    }()
    
    open private(set) lazy var inputTextView: LMChatTaggingTextView = {
        let view = LMChatTaggingTextView().translatesAutoresizingMaskIntoConstraints()
        //        view.textContainerInset = .zero
        view.backgroundColor = Appearance.shared.colors.white
        view.placeHolderText = "Write somthing"
        view.mentionDelegate = self
        view.isScrollEnabled = false
        return view
    }()
    
    open private(set) var inputTextViewHeightConstraint: NSLayoutConstraint?
    open private(set) var taggingViewHeightConstraints: NSLayoutConstraint?
    
    open private(set) lazy var gifButton: LMButton = {
        let button = LMButton().translatesAutoresizingMaskIntoConstraints()
        button.setImage(gifBadgeIcon, for: .normal)
        button.widthAnchor.constraint(equalToConstant: 40.0).isActive = true
        button.addTarget(self, action: #selector(gifButtonClicked), for: .touchUpInside)
        return button
    }()
    
    open private(set) lazy var attachmentButton: LMButton = {
        let button = LMButton().translatesAutoresizingMaskIntoConstraints()
        button.setImage(attachmentButtonIcon, for: .normal)
        button.widthAnchor.constraint(equalToConstant: 40.0).isActive = true
        button.addTarget(self, action: #selector(attachmentButtonClicked), for: .touchUpInside)
        return button
    }()
    
    open private(set) lazy var replyMessageView: LMMessageReplyPreview = {
        let view = LMMessageReplyPreview().translatesAutoresizingMaskIntoConstraints()
        view.onClickCancelReplyPreview = { [weak self] in
            self?.replyMessageViewContainer.isHidden = true
            self?.delegate?.cancelReply()
        }
        return view
    }()
    
    open private(set) lazy var replyMessageViewContainer: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        view.addSubview(replyMessageView)
        view.pinSubView(subView: replyMessageView, padding: .init(top: 6, left: 16, bottom: -4, right: -16))
        view.isHidden = true
        return view
    }()
    
    open private(set) lazy var linkPreviewView: LMBottomMessageLinkPreview = {
        let view = LMBottomMessageLinkPreview().translatesAutoresizingMaskIntoConstraints()
        view.delegate = self
        return view
    }()
    
    open private(set) lazy var taggingListView: LMChatTaggingListView = {
        let view = LMChatTaggingListView().translatesAutoresizingMaskIntoConstraints()
        let viewModel = LMChatTaggingListViewModel(delegate: view)
        view.viewModel = viewModel
        view.delegate = self
        return view
    }()
    
    
    open private(set) lazy var audioMessageContainerStack: LMStackView = {
        let stack = LMStackView().translatesAutoresizingMaskIntoConstraints()
        stack.axis = .vertical
        stack.distribution = .fill
        stack.alignment = .fill
        stack.spacing = .zero
        return stack
    }()
    
    
    // MARK: Send Button
    open private(set) lazy var sendButton: LMButton = {
        let button = LMButton().translatesAutoresizingMaskIntoConstraints()
        button.setImage(micButtonIcon, for: .normal)
        button.contentMode = .scaleToFill
        return button
    }()
    
    
    // MARK: Audio Elements
    open private(set) lazy var audioContainerView: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        view.backgroundColor = .clear
        return view
    }()
    
    open private(set) lazy var micFlickerButton: LMButton = {
        let button = LMButton().translatesAutoresizingMaskIntoConstraints()
        button.setTitle(nil, for: .normal)
        button.setImage(Constants.shared.images.micIcon, for: .normal)
        return button
    }()
    
    open private(set) lazy var recordDuration: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.text = "00:00"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .lightGray
        return label
    }()
    
    open private(set) lazy var audioStack: LMStackView = {
        let stack = LMStackView().translatesAutoresizingMaskIntoConstraints()
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = 8
        return stack
    }()
    
    open private(set) lazy var slideToCancel: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.text = "< Slide To Cancel"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .lightGray
        return label
    }()
    
    open private(set) lazy var deleteAudioRecord: LMButton = {
        let button = LMButton().translatesAutoresizingMaskIntoConstraints()
        button.setTitle(nil, for: .normal)
        button.setImage(UIImage(systemName: "x.circle"), for: .normal)
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        return button
    }()
    
    open private(set) lazy var stopAudioRecord: LMButton = {
        let button = LMButton().translatesAutoresizingMaskIntoConstraints()
        button.setTitle(nil, for: .normal)
        button.setImage(Constants.shared.images.stopRecordButton, for: .normal)
        button.tintColor = Appearance.shared.colors.red
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        return button
    }()
    
    open private(set) lazy var restrictionLabel: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.text = "Restricted to reply in this chatroom!"
        label.backgroundColor = Appearance.shared.colors.white
        label.paddingRight = 20
        label.paddingLeft = 20
        label.textAlignment = .center
        label.numberOfLines = 2
        label.font = .systemFont(ofSize: 14)
        label.textColor = Appearance.shared.colors.textColor
        return label
    }()
    
    open private(set) lazy var lockContainerView: LMView = {
        let container = LMView().translatesAutoresizingMaskIntoConstraints()
        container.backgroundColor = .white
        return container
    }()
    
    open private(set) lazy var lockIcon: LMImageView = {
        let image = LMImageView(image: Constants.shared.images.lockFillIcon)
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    let maxHeightOfTextView: CGFloat = 120
    let minHeightOfTextView: CGFloat = 44
    
    var sendButtonTrailingConstant: CGFloat = -8
    var sendButtonCenterYConstant: CGFloat = 0
    var sendButtonTrailingConstraint: NSLayoutConstraint?
    var sendButtonCenterYConstraint: NSLayoutConstraint?
    var sendButtonLongPressGesture: UILongPressGestureRecognizer!
    var sendButtonPanPressGesture: UIPanGestureRecognizer!
    var isLinkPreviewCancel: Bool = false
    
    
    /*
     Purpose of isTranslationX - It will define the movement of send button at any current point.
        if value is nil it means, sendButton is not translating in any direction
        if value is true it means, sendButton is translating in X direction
        if value is false it means, sendButton is translating in Y direction
     
        Default is nil means, it is stationary in the beginning
    */
    var isTranslationX: Bool? = nil
    var isPlayingAudio = false
    var isLockedIn = false
    
    let micButtonIcon = Constants.shared.images.micIcon.withSystemImageConfig(pointSize: 24)
    let sendButtonIcon = Constants.shared.images.sendButton.withSystemImageConfig(pointSize: 30)
    let attachmentButtonIcon = Constants.shared.images.plusIcon.withSystemImageConfig(pointSize: 24)
    let gifBadgeIcon = UIImage(named: "gifBadge", in: LMChatCoreBundle, with: nil)
    
    let sendButtonHeightConstant: CGFloat = 40
    var lockContainerViewHeight: CGFloat = 100
    var lockContainerViewHeightConstraint: NSLayoutConstraint?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        showHideLockContainer(isShow: false)
        sendButton.tag = messageButtonTag
    }
    
    // MARK: setupViews
    open override func setupViews() {
        super.setupViews()
        addSubview(containerView)
        containerView.addSubview(addOnVerticleStackView)
        
        containerView.addSubview(audioMessageContainerStack)
        containerView.addSubview(lockContainerView)
        lockContainerView.addSubview(lockIcon)
        containerView.addSubview(sendButton)
        
        audioMessageContainerStack.addArrangedSubview(horizontalStackView)
        audioMessageContainerStack.addArrangedSubview(audioContainerView)
        
        inputTextContainerView.addSubview(inputTextAndGifHorizontalStackView)
        inputTextAndGifHorizontalStackView.addArrangedSubview(inputTextView)
        inputTextAndGifHorizontalStackView.addArrangedSubview(gifButton)
        
        horizontalStackView.addArrangedSubview(attachmentButton)
        horizontalStackView.addArrangedSubview(inputTextContainerView)
        
        addOnVerticleStackView.addArrangedSubview(linkPreviewView)
        addOnVerticleStackView.addArrangedSubview(replyMessageViewContainer)
        addOnVerticleStackView.insertArrangedSubview(taggingListView, at: 0)
        
        audioContainerView.addSubview(micFlickerButton)
        audioContainerView.addSubview(recordDuration)
        audioContainerView.addSubview(audioStack)
        
        audioStack.addArrangedSubview(slideToCancel)
        audioStack.addArrangedSubview(stopAudioRecord)
        audioStack.addArrangedSubview(deleteAudioRecord)
        
        linkPreviewView.isHidden = true
        replyMessageViewContainer.isHidden = true
        
        containerView.addSubview(restrictionLabel)
    }
    
    // MARK: setupLayouts
    open override func setupLayouts() {
        super.setupLayouts()
        
        pinSubView(subView: containerView)
        addOnVerticleStackView.addConstraint(top: (containerView.topAnchor, 4),
                                             leading: (containerView.leadingAnchor, 0),
                                             trailing: (containerView.trailingAnchor, 0))
        
        audioMessageContainerStack.addConstraint(top: (addOnVerticleStackView.bottomAnchor, 4),
                                                 bottom: (containerView.bottomAnchor, -4),
                                                 leading: (containerView.leadingAnchor, 8))
        
        micFlickerButton.addConstraint(top: (audioContainerView.topAnchor, 4),
                                       bottom: (audioContainerView.bottomAnchor, -4),
                                       leading: (audioContainerView.leadingAnchor, 8))
        
        recordDuration.addConstraint(top: (micFlickerButton.topAnchor, 0),
                                     bottom: (micFlickerButton.bottomAnchor, 0),
                                     leading: (micFlickerButton.trailingAnchor, 8))
        
        audioStack.addConstraint(top: (recordDuration.topAnchor, 0),
                                    bottom: (recordDuration.bottomAnchor, 0),
                                    trailing: (audioContainerView.trailingAnchor, -8))
        
        audioStack.leadingAnchor.constraint(greaterThanOrEqualTo: recordDuration.trailingAnchor, constant: 8).isActive = true
        
        deleteAudioRecord.setWidthConstraint(with: deleteAudioRecord.heightAnchor)
        stopAudioRecord.setWidthConstraint(with: stopAudioRecord.heightAnchor)
        
        sendButton.addConstraint(leading: (audioMessageContainerStack.trailingAnchor, 8))
        
        sendButtonCenterYConstraint = sendButton.centerYAnchor.constraint(equalTo: audioMessageContainerStack.centerYAnchor, constant: sendButtonCenterYConstant)
        sendButtonCenterYConstraint?.isActive = true
        
        sendButtonTrailingConstraint = sendButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: sendButtonTrailingConstant)
        sendButtonTrailingConstraint?.isActive = true
        
        lockContainerView.addConstraint(bottom: (audioMessageContainerStack.bottomAnchor, 0),
                                        leading: (audioMessageContainerStack.trailingAnchor, 8),
                                        trailing: (containerView.trailingAnchor, sendButtonTrailingConstant))
        lockContainerViewHeightConstraint = lockContainerView.setHeightConstraint(with: lockContainerViewHeight)
        
        lockIcon.addConstraint(top: (lockContainerView.topAnchor, 8),
                               leading: (lockContainerView.leadingAnchor, 8),
                               trailing: (lockContainerView.trailingAnchor, -8))
        lockIcon.setHeightConstraint(with: lockIcon.widthAnchor)
        
        sendButton.setHeightConstraint(with: sendButtonHeightConstant)
        sendButton.setWidthConstraint(with: sendButton.heightAnchor)
        
        
        containerView.setHeightConstraint(with: minHeightOfTextView, relatedBy: .greaterThanOrEqual)
        
        inputTextAndGifHorizontalStackView.addConstraint(top: (inputTextContainerView.topAnchor, 0),
                                                         bottom: (inputTextContainerView.bottomAnchor, 0),
                                                         leading: (inputTextContainerView.leadingAnchor, 8),
                                                         trailing: (inputTextContainerView.trailingAnchor, -8))
        inputTextViewHeightConstraint = inputTextView.setHeightConstraint(with: 36)
        
        taggingViewHeightConstraints = taggingListView.setHeightConstraint(with: 0)
        containerView.pinSubView(subView: restrictionLabel)
    }
    
    
    // MARK: setupActions
    open override func setupActions() {
        super.setupActions()
        sendButton.addTarget(self, action: #selector(sendMessageButtonClicked), for: .touchUpInside)
        
        sendButtonLongPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(sendButtonLongPressed))
        sendButtonLongPressGesture.minimumPressDuration = 0.5
        sendButtonLongPressGesture.delegate = self
        
        sendButtonPanPressGesture = UIPanGestureRecognizer(target: self, action: #selector(sendButtonPanPress))
        
        sendButtonLongPressGesture.isEnabled = true
        sendButtonPanPressGesture.isEnabled = true
        
        sendButton.addGestureRecognizer(sendButtonLongPressGesture)
        sendButton.addGestureRecognizer(sendButtonPanPressGesture)
        
        audioContainerView.isHidden = true
        restrictionLabel.isHidden = true
        
        deleteAudioRecord.addTarget(self, action: #selector(onTapDeleteRecording), for: .touchUpInside)
        micFlickerButton.addTarget(self, action: #selector(onTapPlayPauseRecording), for: .touchUpInside)
        stopAudioRecord.addTarget(self, action: #selector(onTapStopAudioRecording), for: .touchUpInside)
    }
    
    func enableOrDisableMessageBox(withMessage message: String?, isEnable: Bool) {
        restrictionLabel.text = message
        restrictionLabel.isHidden = isEnable
        containerView.isUserInteractionEnabled = isEnable
    }
    
    @objc func sendMessageButtonClicked(_ sender: UIButton) {
        if sender.tag == audioButtonTag {
            audioButtonClicked(sender)
            return
        }
        let message = inputTextView.getText()
        guard !message.isEmpty,
              message != inputTextView.placeHolderText else {
            return
        }
        inputTextView.text = inputTextView.placeHolderText
        inputTextView.resignFirstResponder()
        isLinkPreviewCancel = false
        replyMessageViewContainer.isHidden = true
        closeLinkPreview()
        contentHeightChanged()
        delegate?.composeMessage(message: message)
        
        checkSendButtonGestures()
    }
    
    @objc func attachmentButtonClicked(_ sender: UIButton) {
        delegate?.composeAttachment()
    }
    
    @objc func gifButtonClicked(_ sender: UIButton) {
        delegate?.composeGif()
    }
    
    @objc func audioButtonClicked(_ sender: UIButton) {
        delegate?.composeAudio()
        resetRecordingView()
    }
    
    open override func setupAppearance() {
        super.setupAppearance()
        audioContainerView.backgroundColor = .white
        audioContainerView.layer.cornerRadius = 8
        
        let frameHeight = self.frame.width * 0.3
        
        if frameHeight > 0 {
            lockContainerViewHeight = frameHeight
            lockContainerViewHeightConstraint?.constant = lockContainerViewHeight
        }
        
        lockContainerView.roundCorners([.layerMinXMinYCorner, .layerMaxXMinYCorner], with: sendButtonHeightConstant / 2)
    }
    
    func showReplyView(withData data: LMMessageReplyPreview.ContentModel) {
        replyMessageView.setData(data)
        replyMessageViewContainer.isHidden = false
    }
}

extension LMBottomMessageComposerView: LMFeedTaggingTextViewProtocol {
    public func mentionStarted(with text: String, chatroomId: String) {
        taggingListView.fetchUsers(for: text, chatroomId: chatroomId)
    }
    
    public func mentionStopped() {
        taggingListView.stopFetchingUsers()
    }
    
    
    public func contentHeightChanged() {
        let width = inputTextView.frame.size.width
        
        let newSize = inputTextView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        
        inputTextView.isScrollEnabled = newSize.height > maxHeightOfTextView
        inputTextViewHeightConstraint?.constant = min(newSize.height, maxHeightOfTextView)
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        checkSendButtonGestures()
        
        // Find first url link here and ignore email
        let links = textView.text.detectedLinks
        if !isLinkPreviewCancel, !links.isEmpty, let link = links.first(where: {!$0.isEmail()}) {
            self.delegate?.linkDetected(link)
        } else {
            linkPreviewView.isHidden = true
        }
    }
}

extension LMBottomMessageComposerView: LMChatTaggedUserFoundProtocol {
    public func userSelected(with route: String, and userName: String) {
        inputTextView.addTaggedUser(with: userName, route: route)
        mentionStopped()
    }
    
    public func updateHeight(with height: CGFloat) {
        taggingViewHeightConstraints?.constant = height
    }
}


// MARK: UIGestureRecognizerDelegate
extension LMBottomMessageComposerView: UIGestureRecognizerDelegate {
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer == sendButtonLongPressGesture && otherGestureRecognizer == sendButtonPanPressGesture
    }
}


// MARK: AUDIO EXTENSION
extension LMBottomMessageComposerView {
    @objc
    open func sendButtonLongPressed(_ sender: UILongPressGestureRecognizer) {
        guard inputTextView.text == inputTextView.placeHolderText || inputTextView.text.isEmpty else { return }
        
        if #available(iOS 17, *) {
            if AVAudioApplication.shared.recordPermission == .granted {
                handleLongPress(sender)
            } else if AVAudioApplication.shared.recordPermission == .denied {
                print("no mic access")
            } else if AVAudioApplication.shared.recordPermission == .undetermined {
                AVAudioApplication.requestRecordPermission { _ in }
            }
        } else {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted:
                handleLongPress(sender)
            case .denied:
                print("No Access to microphone")
            case .undetermined:
                AVAudioSession.sharedInstance().requestRecordPermission { _ in}
            default:
                break
            }
        }
    }
    
    public func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        inputTextView.resignFirstResponder()
        
        switch sender.state {
        case .began:
            delegate?.audioRecordingStarted()
        case .ended,
                .cancelled:
            if !isLockedIn {
                delegate?.audioRecordingEnded()
            }
            break
        default:
            break
        }
    }
    
    @objc
    open func sendButtonPanPress(_ sender: UIPanGestureRecognizer) {
        guard sendButtonLongPressGesture.state == .changed else { return }
        
        let translation = sender.translation(in: self)
        
        // It means send Button has already a motion of X translation
        // Cases: 
        //  1. It is still going deeper into X translation
        //  2. It is going back towards zero
        if isTranslationX == true {
            if translation.x < sendButtonTrailingConstant {
                if abs(translation.x) < UIScreen.main.bounds.width * 0.3 {
                    sendButtonTrailingConstraint?.constant = translation.x
                } else {
                    delegate?.deleteRecording()
                    resetRecordingView()
                }
            } else {
                sendButtonTrailingConstraint?.constant = sendButtonTrailingConstant
                isTranslationX = nil
            }
        } else if isTranslationX == false {
            if translation.y < 0 {
                if abs(translation.y) < lockContainerViewHeight * 0.7 {
                    sendButtonCenterYConstraint?.constant = translation.y
                } else {
                    isLockedIn = true
                    setupLockedAudioView()
                }
            } else {
                sendButtonCenterYConstraint?.constant = sendButtonCenterYConstant
                isTranslationX = nil
            }
        } else {
            if translation.x < sendButtonTrailingConstant || translation.y < sendButtonCenterYConstant {
                isTranslationX = abs(translation.x) > abs(translation.y)
            }
        }
        
        // In Case if it is translating X, hide the container view
        if isTranslationX == true {
            showHideLockContainer(isShow: translation.x > -16)
        }
    }
        
    
    func updateRecordTime(with seconds: Int, isPlayback: Bool = false) {
        recordDuration.text = convertSecondsToFormattedTime(seconds: seconds)
        isPlayingAudio = isPlayback
        
        if !isPlayback {
            UIView.animate(withDuration: 0.3, delay: 0.1) { [weak self] in
                guard let self else { return }
                self.micFlickerButton.alpha = self.micFlickerButton.alpha == 1 ? 0.5 : 1
            }
        }
    }
    
    // TODO: Remove this, when moving it to UI Library, same function exists in `LMChatAudioPreview`
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

extension LMBottomMessageComposerView: LMBottomMessageLinkPreviewDelete {
    
    public func closeLinkPreview() {
        linkPreviewView.isHidden = true
        isLinkPreviewCancel = true
        delegate?.cancelLinkPreview()
    }
}



// Audio Logic
extension LMBottomMessageComposerView {
    // Resets Recording View and shows Text Input View
    func resetRecordingView() {
        sendButton.tag = messageButtonTag
        resetSendButtonConstraints()
        
        recordDuration.text = "00:00"
        
        horizontalStackView.isHidden = false
        audioContainerView.isHidden = true
        
        resetSendButtonConstraints()
        checkSendButtonGestures()
        
        sendButton.setImage(micButtonIcon, for: .normal)
        sendButtonPanPressGesture.isEnabled = true
        sendButtonLongPressGesture.isEnabled = true
        
        isPlayingAudio = false
        isLockedIn = false
        showHideLockContainer(isShow: false)
    }
    
    
    // Shows Initial Recording View
    func showRecordingView() {
        sendButton.tag = audioButtonTag
        
        isLockedIn = false
        horizontalStackView.isHidden = true
        audioContainerView.isHidden = false
        
        resetSendButtonConstraints()
        setVisibilityOfAudioElements(slideCancel: true, stopAudio: false, deleteAudio: false)
        showHideLockContainer(isShow: true)
        
        micFlickerButton.setImage(Constants.shared.images.micIcon, for: .normal)
        micFlickerButton.tintColor = Appearance.shared.colors.red
        micFlickerButton.isEnabled = false
    }
    
    
    // Resets Send Button Constraints
    func resetSendButtonConstraints() {
        sendButtonTrailingConstraint?.constant = sendButtonTrailingConstant
        sendButtonCenterYConstraint?.constant = sendButtonCenterYConstant
    }
    
    
    // Checks if Long and Pan Gestures should be enabled or not
    func checkSendButtonGestures() {
        let isText = (inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines) == inputTextView.placeHolderText)
        
        // Making sure that the text field is empty and the user isn't locked in
        sendButtonLongPressGesture.isEnabled = isText && !isLockedIn
        sendButtonPanPressGesture.isEnabled = isText && !isLockedIn
        
        sendButton.setImage(isText ? micButtonIcon : sendButtonIcon, for: .normal)
    }
    
    // Sets the visibility of Slide To Cancel, Stop Audio Recording, Delete Audio Recording
    func setVisibilityOfAudioElements(slideCancel: Bool, stopAudio: Bool, deleteAudio: Bool) {
        deleteAudioRecord.isHidden = !deleteAudio
        stopAudioRecord.isHidden = !stopAudio
        slideToCancel.isHidden = !slideCancel
    }
    
    
    // When user stops recording, showing user the view of recorded view!
    func showPlayableRecordView() {
        resetSendButtonConstraints()
        setVisibilityOfAudioElements(slideCancel: false, stopAudio: false, deleteAudio: true)
        
        micFlickerButton.setImage(Constants.shared.images.playFill, for: .normal)
        micFlickerButton.tintColor = Appearance.shared.colors.gray155
        micFlickerButton.isEnabled = true
        
        sendButton.setImage(sendButtonIcon, for: .normal)
        
        showHideLockContainer(isShow: false)
        
        isPlayingAudio = false
    }
    

    // When User locks in 🤫🧏‍♂️
    func setupLockedAudioView() {
        checkSendButtonGestures()
        resetSendButtonConstraints()
        setVisibilityOfAudioElements(slideCancel: false, stopAudio: true, deleteAudio: true)
        
        showHideLockContainer(isShow: false)
        
        sendButton.setImage(sendButtonIcon, for: .normal)
    }
    
    func showHideLockContainer(isShow: Bool) {
        lockContainerView.isHidden = !isShow
    }
    
    func resetAudioDuration(with totalDuration: Int) {
        recordDuration.text = convertSecondsToFormattedTime(seconds: totalDuration)
        micFlickerButton.setImage(Constants.shared.images.playFill, for: .normal)
        isPlayingAudio = false
    }
}


@objc
extension LMBottomMessageComposerView {
    open func onTapStopAudioRecording() {
        delegate?.audioRecordingEnded()
    }
    
    open func onTapPlayPauseRecording() {
        if !isPlayingAudio {
            micFlickerButton.setImage(Constants.shared.images.pauseIcon, for: .normal)
            delegate?.playRecording()
        } else {
            micFlickerButton.setImage(Constants.shared.images.playFill, for: .normal)
            delegate?.stopRecording {
                isPlayingAudio = false
            }
        }
    }
    
    open func onTapDeleteRecording() {
        resetRecordingView()
        delegate?.deleteRecording()
    }
}
