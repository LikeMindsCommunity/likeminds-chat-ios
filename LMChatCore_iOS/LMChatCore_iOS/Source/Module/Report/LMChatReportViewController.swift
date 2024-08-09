//
//  LMChatReportViewController.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 06/03/24.
//

import UIKit
import LikeMindsChatUI

public protocol LMChatReportViewModelProtocol: LMBaseViewControllerProtocol {
    func updateView(with tags: [(name: String, tagID: Int)], selectedTag: Int, showTextView: Bool)
    func didReceivedReportContent(reason: String?)
}

public protocol LMChatReportViewDelegate: AnyObject {
    func didReportActionCompleted(reason: String?)
}

public extension LMChatReportViewModelProtocol {
    func updateView(with tags: [(name: String, tagID: Int)], selectedTag: Int, showTextView: Bool) {}
}

public extension LMChatReportViewDelegate {
    func didReportActionCompleted(reason: String?) {}
}

open class LMChatReportViewController: LMViewController {
    // MARK: UI Elements
    open private(set) lazy var containerView: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        view.backgroundColor = Appearance.shared.colors.clear
        return view
    }()
    
    open private(set) lazy var containerScrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.contentInset = .init(top: 16, left: 0, bottom: 0, right: 0)
        return scroll
    }()
    
    open private(set) lazy var stackView: LMStackView = {
        let stack = LMStackView().translatesAutoresizingMaskIntoConstraints()
        stack.axis = .vertical
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 8
        return stack
    }()
    
    open private(set) lazy var reportTitleLabel: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.text = "Please specify the problem to continue"
        label.font = Appearance.shared.fonts.headingFont1
        label.textColor = Appearance.shared.colors.gray51
        return label
    }()
    
    open private(set) lazy var reportSubtitleLabel: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        label.text = "You would be able to report this content after selecting a problem."
        label.numberOfLines = 0
        label.textColor = Appearance.shared.colors.gray102
        label.font = Appearance.shared.fonts.textFont1
        return label
    }()
    
    open private(set) lazy var collectionView: LMCollectionView = {
        let collection = LMChatTagCollectionView(frame: .zero, collectionViewLayout: TagsLayout()).translatesAutoresizingMaskIntoConstraints()
        collection.isScrollEnabled = true
        collection.dataSource = self
        collection.delegate = self
        collection.backgroundColor = Appearance.shared.colors.clear
        collection.registerCell(type: LMUIComponents.shared.reportCollectionCell)
        return collection
    }()
    
    open private(set) lazy var otherReasonTextView: LMTextView = {
        let textView = LMTextView().translatesAutoresizingMaskIntoConstraints()
        textView.delegate = self
        textView.backgroundColor = Appearance.shared.colors.clear
        return textView
    }()
    
    open private(set) lazy var sepratorView: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        view.backgroundColor = Appearance.shared.colors.linkColor
        return view
    }()
    
    open private(set) lazy var submitButton: LMButton = {
        let button = LMButton.createButton(with: "REPORT", image: nil, textColor: .white, textFont: Appearance.shared.fonts.buttonFont3, contentSpacing: .init(top: 16, left: 60, bottom: 16, right: 60))
        button.setFont(Appearance.shared.fonts.headingFont1)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.clipsToBounds = true
        button.backgroundColor = Appearance.shared.colors.red
        return button
    }()
    
    
    // MARK: Data Variables
    public var textInputHeight: CGFloat = 100
    public var tags: [(String, Int)] = []
    public var selectedTag = -1
    public var placeholderText = "Write Description!"
    public var viewmodel: LMChatReportViewModel?
    public var delegate: LMChatReportViewDelegate?
    
    
    // MARK: setupViews
    open override func setupViews() {
        super.setupViews()
        
        view.addSubview(containerView)
        
        containerView.addSubview(containerScrollView)
        containerView.addSubview(submitButton)
        
        containerScrollView.addSubview(stackView)
        
        [reportTitleLabel, reportSubtitleLabel, collectionView, otherReasonTextView, sepratorView].forEach { subview in
            stackView.addArrangedSubview(subview)
        }
        
        self.initializeHideKeyboard(containerScrollView)
    }
    
    
    // MARK: setupLayouts
    open override func setupLayouts() {
        super.setupLayouts()
        
        view.pinSubView(subView: containerView, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        
        containerScrollView.addConstraint(top: (containerView.topAnchor, 20),
                                          leading: (containerView.leadingAnchor, 0),
                                          trailing: (containerView.trailingAnchor, 0))
        
        submitButton.addConstraint(top: (containerScrollView.bottomAnchor, 16),
                                   bottom: (containerView.bottomAnchor, -100),
                                   centerX: (containerView.centerXAnchor, 0))
        
        containerScrollView.pinSubView(subView: stackView)
        
        stackView.setHeightConstraint(with: 50, priority: .defaultLow)
        stackView.setWidthConstraint(with: containerView.widthAnchor)
        
        collectionView.setHeightConstraint(with: stackView.widthAnchor, relatedBy: .lessThanOrEqual, multiplier: 0.5)
        
        otherReasonTextView.setHeightConstraint(with: textInputHeight)
        sepratorView.setHeightConstraint(with: 1)
        
        submitButton.addConstraint(top: (containerScrollView.bottomAnchor, 16),
                                   bottom: (containerView.bottomAnchor, -16),
                                   centerX: (containerView.centerXAnchor, 0))
        
        [reportTitleLabel, reportSubtitleLabel, collectionView, otherReasonTextView, sepratorView].forEach { subview in
            subview.addConstraint(leading: (stackView.leadingAnchor, 16),
                                  trailing: (stackView.trailingAnchor, -16))
        }
    }
    
    
    // MARK: setupAppearance
    open override func setupAppearance() {
        super.setupAppearance()
        view.backgroundColor = Appearance.shared.colors.white
        submitButton.layer.cornerRadius = submitButton.frame.height / 2
    }
    
    
    // MARK: setupActions
    open override func setupActions() {
        super.setupActions()
        submitButton.addTarget(self, action: #selector(didTapSubmitButton), for: .touchUpInside)
    }
    
    @objc
    open func didTapSubmitButton() {
        guard selectedTag != -1 else { return }
        
        if selectedTag == 11 {
            let reason = otherReasonTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !reason.isEmpty,
               reason != placeholderText {
                viewmodel?.reportContent(reason: otherReasonTextView.text)
            } else {
                showError(message: "Please Enter Valid Reason", isPopVC: false)
            }
        } else {
            viewmodel?.reportContent(reason: nil)
        }
    }
    
    // MARK: setupObservers
    open override func setupObservers() {
        super.setupObservers()
    }
    
    
    // MARK: viewDidLoad
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        updateTitle()
        
        otherReasonTextView.text = placeholderText
        otherReasonTextView.textColor = Appearance.shared.colors.gray155
        otherReasonTextView.font = Appearance.shared.fonts.textFont1
        
        setupButton(isEnabled: false)
        viewmodel?.fetchReportTags()
    }
    
    open func setupButton(isEnabled: Bool) {
        submitButton.isEnabled = isEnabled
        submitButton.backgroundColor = isEnabled ? Appearance.shared.colors.red : Appearance.shared.colors.gray4
    }
    
    func updateTitle() {
        if viewmodel?.messageId != nil {
            setNavigationTitleAndSubtitle(with: "Report Message", subtitle: nil, alignment: .center)
        } else if viewmodel?.chatroomId != nil {
            setNavigationTitleAndSubtitle(with: "Report Chatroom", subtitle: nil, alignment: .center)
        } else if viewmodel?.memberId != nil {
            setNavigationTitleAndSubtitle(with: "Report Member", subtitle: nil, alignment: .center)
        } else {
            setNavigationTitleAndSubtitle(with: "Report", subtitle: nil, alignment: .center)
        }
    }
    
    
    @objc
    open override func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrameKey = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardFrame = view.convert(keyboardFrameKey.cgRectValue, from: nil)
        
        var contentInset = containerScrollView.contentInset
        contentInset.bottom = keyboardFrame.size.height
        containerScrollView.contentInset = contentInset
        loadViewIfNeeded()
    }
    
    @objc
    open override func keyboardWillHide(_ notification: Notification){
        containerScrollView.contentInset.bottom = 0
    }
}


// MARK: UICollectionView
extension LMChatReportViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { tags.count }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(with: LMUIComponents.shared.reportCollectionCell, for: indexPath) {
            let name = tags[indexPath.row].0
            let tagID = tags[indexPath.row].1
            
            cell.configure(with: name, isSelected: tagID == selectedTag) { [weak self] in
                self?.viewmodel?.updateSelectedTag(with: tagID)
            }
            return cell
        }
        return UICollectionViewCell()
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = tags[indexPath.row].0.sizeOfString(with: Appearance.shared.fonts.textFont1).width + 32
        return .init(width: width, height: 50)
    }
}


// MARK: UITextViewDelegate
extension LMChatReportViewController: UITextViewDelegate {
    open func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines) == placeholderText {
            textView.text = nil
            textView.textColor = Appearance.shared.colors.gray51
            textView.font = Appearance.shared.fonts.textFont1
        }
    }
    
    open func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = placeholderText
            textView.textColor = Appearance.shared.colors.gray155
            textView.font = Appearance.shared.fonts.textFont1
        }
    }
}


// MARK: LMChatReportViewModelProtocol
extension LMChatReportViewController: LMChatReportViewModelProtocol {
    
    public func didReceivedReportContent(reason: String?) {
        let title = "\(viewmodel?.contentType.rawValue ?? "") is reported for review"
        let message = "Our team will look into your feedback and will take appropriate action on this \(viewmodel?.contentType.rawValue ?? "")"
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                self?.delegate?.didReportActionCompleted(reason: reason)
                self?.popViewController(animated: true)
            })
            self?.present(alert, animated: true)
        }
    }
    
    public func updateView(with tags: [(name: String, tagID: Int)], selectedTag: Int, showTextView: Bool) {
        self.tags = tags
        self.selectedTag = selectedTag
        collectionView.reloadData()
        
        otherReasonTextView.isHidden = !showTextView
        sepratorView.isHidden = !showTextView
        
        setupButton(isEnabled: selectedTag != -1)
        
        if showTextView {
            otherReasonTextView.becomeFirstResponder()
        } else {
            otherReasonTextView.resignFirstResponder()
        }
    }
}
