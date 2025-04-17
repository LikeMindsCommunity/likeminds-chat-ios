//
//  LMChatAIBotInitiationViewController.swift
//  LikeMindsChatCore
//
//  Created by Arpit Verma on 13/04/25.
//

import UIKit
import Lottie
import LikeMindsChatUI

open class LMChatAIBotInitiationViewController: LMViewController, LMAIChatBotChatViewModelProtocol {
    
    // MARK: - UI Constants
    private let animationContainerSize: CGFloat = 450
    private let previewLabelBottomPadding: CGFloat = 40
    private let previewLabelSidePadding: CGFloat = 20
    private let animationName = "ai_chat_loading"
    
    // MARK: - Data Properties
    var viewModel: LMAIChatBotChatViewModel?
    
    // MARK: - UI Components
    private lazy var containerView: LMView = {
        let view = LMView()
        view.backgroundColor = Appearance.shared.colors.white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var animationContainerView: LMView = {
        let view = LMView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var previewLabel: LMLabel = {
        let label = LMLabel()
        label.text = Constants.shared.strings.aiSetupText
        label.textAlignment = .center
        label.textColor = Appearance.shared.colors.gray1
        label.font = Appearance.shared.fonts.textFont1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var animationView: LottieAnimationView?
    
    // MARK: - Initialization
    required public init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupLayouts()
        setupAnimation()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAnimation()
        viewModel?.initializeChatbot()
    }
    
    // MARK: - LMAIChatBotChatViewModelProtocol
    
    public func didStartInitialization() {
        // Animation is already running, no need to do anything
    }
    
    public func didCompleteInitialization() {
        stopAnimation()
        // Dismiss immediately after navigation is complete
        dismiss(animated: true)
    }
    
    public func didFailInitialization(with error: String) {
        stopAnimation()
        showError(message: error)
    }
    
    // MARK: - Private Methods
    
    private func stopAnimation() {
        animationView?.stop()
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(
            title: nil,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    // MARK: - Setup Methods
    open override func setupViews() {
        super.setupViews()
        view.addSubview(containerView)
        containerView.addSubview(animationContainerView)
        containerView.addSubview(previewLabel)
    }
    
    open override func setupLayouts() {
        super.setupLayouts()
        
        NSLayoutConstraint.activate([
            // Container View
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Animation Container
            animationContainerView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            animationContainerView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            animationContainerView.widthAnchor.constraint(equalToConstant: animationContainerSize),
            animationContainerView.heightAnchor.constraint(equalToConstant: animationContainerSize),
            
            // Preview Label
            previewLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: previewLabelSidePadding),
            previewLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -previewLabelSidePadding),
            previewLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -previewLabelBottomPadding)
        ])
    }
    
    private func setupAnimation() {
        // Try loading from main bundle first
        if let animation = LottieAnimation.named(animationName) {
            setupAnimationView(with: animation)
            return
        }
        
        // Try loading from framework bundle
        let frameworkBundle = Bundle(for: type(of: self))
        if let animation = LottieAnimation.named(animationName, bundle: frameworkBundle) {
            setupAnimationView(with: animation)
            return
        }
        
        // Try loading from file path
        if let path = frameworkBundle.path(forResource: animationName, ofType: "json") {
            let animation = LottieAnimation.filepath(path)
            guard let animation = animation else {
                print("Error: Could not load animation from path: \(path)")
                return
            }
            setupAnimationView(with: animation)
            return
        }
        
        print("Error: Could not load animation named \(animationName) from any source")
    }
    
    private func setupAnimationView(with animation: LottieAnimation) {
        animationView = LottieAnimationView(animation: animation)
        
        guard let animationView = animationView else { return }
        
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.animationSpeed = 1.0
        animationView.translatesAutoresizingMaskIntoConstraints = false
        
        animationContainerView.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.topAnchor.constraint(equalTo: animationContainerView.topAnchor),
            animationView.leadingAnchor.constraint(equalTo: animationContainerView.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: animationContainerView.trailingAnchor),
            animationView.bottomAnchor.constraint(equalTo: animationContainerView.bottomAnchor)
        ])
    }
    
    private func startAnimation() {
        animationView?.play()
    }
} 