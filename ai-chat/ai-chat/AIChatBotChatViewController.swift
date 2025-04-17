//
//  ViewController.swift
//  ai-chat
//
//  Created by Arpit Verma on 11/04/25.
//

import FirebaseMessaging
import LikeMindsChatUI
import UIKit
import LikeMindsChatCore
import LikeMindsChatUI

 class LMAIChatBotViewController: LMViewController {
    
    
    var viewModel: LMAIChatBotChatViewModel?
    // MARK: - UI Components
    private lazy var notificationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "bell"), for: .normal)
        button.tintColor = .black
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .white
        collectionView.register(PlaceholderCell.self, forCellWithReuseIdentifier: "PlaceholderCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private lazy var aiChatButton: LMChatAIButton = {
        let button = LMChatAIButton(frame: .zero)
        button.delegate = self
        button.translatesAutoresizingMaskIntoConstraints = false
        button.clipsToBounds = true
        return button
    }()
    
    // MARK: - Lifecycle
   open override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupAIChatButton()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .white
        
        // Add subviews
        view.addSubview(collectionView)
        view.addSubview(aiChatButton)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Collection View
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // AI Chat Button - Adjusted for capsule shape
            aiChatButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            aiChatButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            aiChatButton.widthAnchor.constraint(equalToConstant: 100), // Adjusted width
            aiChatButton.heightAnchor.constraint(equalToConstant: 40)  // Adjusted height
        ])
    }
    
    open override func setupNavigationBar() {
        title = "Explore"
        navigationController?.navigationBar.prefersLargeTitles = false
        
        // Add notification button to navigation bar
        let notificationBarButton = UIBarButtonItem(customView: notificationButton)
        navigationItem.rightBarButtonItem = notificationBarButton
    }
    
    private func setupAIChatButton() {
        let userDefaults = UserDefaults.standard
        let apiKey = userDefaults.string(forKey: "apiKey") ?? ""
        let userId = userDefaults.string(forKey: "userId") ?? ""
        let username = userDefaults.string(forKey: "username") ?? ""
        
        let props = LMChatAIButtonProps(
            apiKey: apiKey,
            uuid: userId,
            userName: username
        )
        aiChatButton.props = props
        
        // Additional styling for capsule shape
        aiChatButton.layer.cornerRadius = 20 // Half of the height (40/2)
        aiChatButton.clipsToBounds = true
    }
    
     private func startAIChatBot(apiKey: String, username: String, userId: String) {
         
         LMChatCore.shared.showChat(
             apiKey: apiKey,
             username: username,
             uuid: userId
         ) { [weak self] result in
             guard let self = self else { return }
             
             self.showHideLoaderView(isShow: false, backgroundColor: .clear)
             
             switch result {
             case .success:
                 do {
                     let initiationVC = try LMAIChatBotChatViewModel.createModule()
                     
                     
                     let navigation = UINavigationController(
                        rootViewController: initiationVC)
                     // Ensure we're on the main thread and the view is in the window hierarchy
                     DispatchQueue.main.async {
                         if let window = self.window {
                             navigation.modalPresentationStyle = .overFullScreen
                             self.window?.rootViewController = navigation
//                             window.rootViewController?.present(initiationVC, animated: true)
                         } else {
                             self.present(initiationVC, animated: true)
                         }
                     }
                 } catch {
                     self.showErrorAlert(message: "Failed to create AI Chat module: \(error.localizedDescription)")
                 }
             case .failure(let error):
                 self.showErrorAlert(message: error.localizedDescription)
             }
         }
     }

}



// MARK: - UICollectionViewDataSource
extension LMAIChatBotViewController: UICollectionViewDataSource {
   open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4 // Show exactly 4 placeholder cards
    }
    
   open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlaceholderCell", for: indexPath) as! PlaceholderCell
        return cell
    }
}


// MARK: - UICollectionViewDelegateFlowLayout
extension LMAIChatBotViewController: UICollectionViewDelegateFlowLayout {
   open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 16) / 2
        return CGSize(width: width, height: width)
    }
}

// MARK: - LMChatAIButtonDelegate
extension LMAIChatBotViewController: LMChatAIButtonDelegate {
    public func didTapAIButton(_ button: LMChatAIButton,props: LMChatAIButtonProps) {
        guard let props = button.props,
              let apiKey = props.apiKey,
              let username = props.userName,
              let userId = props.uuid else {
            showErrorAlert(message: "Missing required credentials")
            return
        }
        startAIChatBot(apiKey: apiKey, username: username, userId: userId)
    }
}

// MARK: - PlaceholderCell
class PlaceholderCell: UICollectionViewCell {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let shimmerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(containerView)
        containerView.addSubview(shimmerView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            shimmerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            shimmerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            shimmerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            shimmerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        startShimmerAnimation()
    }
    
    private func startShimmerAnimation() {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = shimmerView.bounds
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        
        let lightColor = UIColor.white.withAlphaComponent(0.5).cgColor
        let darkColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor
        
        gradientLayer.colors = [darkColor, lightColor, darkColor]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1.0, -0.5, 0.0]
        animation.toValue = [1.0, 1.5, 2.0]
        animation.duration = 1.5
        animation.repeatCount = .infinity
        
        gradientLayer.add(animation, forKey: "shimmer")
        shimmerView.layer.addSublayer(gradientLayer)
    }
}



