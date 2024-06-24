//
//  LMViewController.swift
//  LMFramework
//
//  Created by Devansh Mohata on 24/11/23.
//

import UIKit

public extension UIViewController {
    
    /// Adds child view controller to the parent.
    ///
    /// - Parameter child: Child view controller.
    func add(child: UIViewController, to subView: UIView) {
        addChild(child)
        subView.addSubview(child.view)
        child.didMove(toParent: self)
    }
    
    /// It removes the child view controller from the parent.
    func remove() {
        guard parent != nil else {
            return
        }
        willMove(toParent: nil)
        removeFromParent()
        view.removeFromSuperview()
    }
}

public protocol LMBaseViewControllerProtocol: AnyObject {
    func presentAlert(with alert: UIAlertController, animated: Bool)
    func showHideLoaderView(isShow: Bool)
    func showError(with message: String, isPopVC: Bool)
    func popViewController(animated: Bool)
}

/// Base LM View Controller Class with LM Life Cycle Methods
@IBDesignable
open class LMViewController: UIViewController {
    // MARK: UI Elements
    open private(set) lazy var loaderScreen: LMView = {
        let view = LMView(frame: view.bounds).translatesAutoresizingMaskIntoConstraints()
        view.backgroundColor = Appearance.shared.colors.white
        return view
    }()
    
    open private(set) lazy var navigationTitleView: LMView = {
        let view = LMView(frame: view.bounds).translatesAutoresizingMaskIntoConstraints()
        view.backgroundColor = .clear
        return view
    }()
    
    open private(set) lazy var titleStackView: LMStackView =  {
        let stackView = LMStackView().translatesAutoresizingMaskIntoConstraints()
        stackView.spacing = 0
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
        navigationTitleView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: navigationTitleView.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: navigationTitleView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: navigationTitleView.bottomAnchor),
            stackView.trailingAnchor.constraint(equalTo: navigationTitleView.trailingAnchor)
        ])
        stackView.addArrangedSubview(navigationHeaderTitleLabel)
        stackView.addArrangedSubview(navigationHeaderSubtitleLabel)
        return stackView
    }()
    
    open private(set) lazy var navigationHeaderTitleLabel: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        view.backgroundColor = Appearance.shared.colors.white
        return label
    }()
    
    open private(set) lazy var navigationHeaderSubtitleLabel: LMLabel = {
        let label = LMLabel().translatesAutoresizingMaskIntoConstraints()
        view.backgroundColor = Appearance.shared.colors.white
        return label
    }()
    
    open private(set) lazy var loaderView: UIActivityIndicatorView = {
        let loader = UIActivityIndicatorView(style: .large)
        loader.translatesAutoresizingMaskIntoConstraints = false
        loader.tintColor = Appearance.shared.colors.gray51
        return loader
    }()
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    open override func loadView() {
        super.loadView()
        setupViews()
        setupLayouts()
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        changeNavBar()
        setupActions()
        setupObservers()
        setupNavigationBar()
    }
    
    func changeNavBar() {
        guard let navigationBar = navigationController?.navigationBar else { return }
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Appearance.shared.colors.navigationBackgroundColor
        navigationBar.standardAppearance = appearance;
        navigationBar.scrollEdgeAppearance = navigationBar.standardAppearance
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupAppearance()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupKeyboardNotifications()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboardNotifications()
    }
    
    open func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    
    open func removeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    open func initializeHideKeyboard(_ givenView: UIView){
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(dismissMyKeyboard))
        givenView.addGestureRecognizer(tap)
    }
    
    @objc open func dismissMyKeyboard(){
        view.endEditing(true)
    }
    
    @objc
    open func keyboardWillShow(_ sender: Notification) {
        guard let userInfo = sender.userInfo else {
            return
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc
    open func keyboardWillHide(_ sender: Notification) {
        self.view.layoutIfNeeded()
    }
    
    open func setBackButtonWithAction() {
        let backImage = Constants.shared.images.leftArrowIcon
        self.navigationController?.navigationBar.backIndicatorImage = backImage
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = backImage
        let backItem = UIBarButtonItem(image: backImage, style: .plain, target: nil, action: nil)
        backItem.tintColor = Appearance.shared.colors.linkColor
        self.navigationItem.backBarButtonItem = backItem
    }
    
    open func setRightNavigationWithAction(title: String?, image: UIImage?, style: UIBarButtonItem.Style, target: Any?, action: Selector?) {
        let rightItem = title != nil ? UIBarButtonItem(title: title, style: style, target: target, action: action) : UIBarButtonItem(image: image, style: style, target: target, action: action)
        rightItem.tintColor = Appearance.shared.colors.linkColor
        var rightItems = self.navigationItem.rightBarButtonItems ?? []
        rightItems.append(rightItem)
        
        self.navigationItem.rightBarButtonItems = rightItems
    }
    
    open func showErrorAlert(_ title: String? = "Error", message: String?) {
        guard let message = message else { return }
//        self.presentAlert(title: title, message: message)
    }
    
    @objc open func errorMessage(notification: Notification) {
        if let errorMessage = notification.object as? String {
            self.showErrorAlert(message: errorMessage)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    open func setupNavigationBar() {
        navigationController?.navigationBar.isTranslucent = true
        if #available(iOS 15, *) {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = Appearance.shared.colors.navigationBackgroundColor
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }
    }
    
    @objc open func dismissViewController() {
        guard let _ = self.navigationController?.popViewController(animated: true) else {
            self.dismiss(animated: true)
            return
        }
    }
    
    public func setNavigationTitleAndSubtitle(with title: String?, subtitle: String?, alignment: UIStackView.Alignment = .center) {
        let widthConstraint = NSLayoutConstraint.init(item: navigationTitleView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: UIScreen.main.bounds.width)
        widthConstraint.priority = .defaultLow
        widthConstraint.isActive = true
        
        titleStackView.alignment = alignment
        
        navigationHeaderTitleLabel.text = title
        navigationHeaderTitleLabel.textColor = Appearance.shared.colors.black
        navigationHeaderTitleLabel.font = Appearance.shared.fonts.navigationTitleFont
        navigationHeaderTitleLabel.isHidden = (title ?? "").isEmpty
        
        navigationHeaderSubtitleLabel.text = subtitle
        navigationHeaderSubtitleLabel.textColor = Appearance.shared.colors.textColor
        navigationHeaderSubtitleLabel.font = Appearance.shared.fonts.navigationSubtitleFont
        navigationHeaderSubtitleLabel.isHidden = (subtitle ?? "").isEmpty
        
        navigationItem.titleView = navigationTitleView
    }
    
    open func showHideLoaderView(isShow: Bool) {
        if isShow {
            view.addSubview(loaderScreen)
            loaderScreen.addSubview(loaderView)
            
            NSLayoutConstraint.activate([
                loaderScreen.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                loaderScreen.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                loaderScreen.topAnchor.constraint(equalTo: view.topAnchor),
                loaderScreen.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                
                loaderView.centerXAnchor.constraint(equalTo: loaderScreen.centerXAnchor),
                loaderView.centerYAnchor.constraint(equalTo: loaderScreen.centerYAnchor),
                loaderView.heightAnchor.constraint(equalToConstant: 50),
                loaderView.widthAnchor.constraint(equalTo: loaderView.heightAnchor, multiplier: 1)
            ])
            view.bringSubviewToFront(loaderScreen)
            loaderView.startAnimating()
        } else if loaderView.isDescendant(of: view) {
            view.sendSubviewToBack(loaderScreen)
            loaderView.stopAnimating()
            loaderView.removeFromSuperview()
            loaderScreen.removeFromSuperview()
        }
    }
    
    public func displayToast(_ message : String, font: UIFont = UIFont.systemFont(ofSize: 16)) {
        
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow })else {
            return
        }
        if let toast = window.subviews.first(where: { $0 is UILabel && $0.tag == -1001 }) {
            toast.removeFromSuperview()
        }
        
        let toastView = LMLabel()
        toastView.backgroundColor = Appearance.shared.colors.black.withAlphaComponent(0.7)
        toastView.textColor = Appearance.shared.colors.white
        toastView.textAlignment = .center
        toastView.font = font
        toastView.cornerRadius(with: 8)
        toastView.text = message
        toastView.numberOfLines = 0
        toastView.alpha = 0
        toastView.translatesAutoresizingMaskIntoConstraints = false
        toastView.tag = -1001
        
        window.addSubview(toastView)
        
        let horizontalCenterContraint: NSLayoutConstraint = NSLayoutConstraint(item: toastView, attribute: .centerX, relatedBy: .equal, toItem: window, attribute: .centerX, multiplier: 1, constant: 0)
        
        let widthContraint: NSLayoutConstraint = NSLayoutConstraint(item: toastView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: (self.view.frame.size.width-25) )
        
        let verticalContraint: [NSLayoutConstraint] = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(>=200)-[toastView(==50)]-68-|", options: [.alignAllCenterX, .alignAllCenterY], metrics: nil, views: ["toastView": toastView])
        
        NSLayoutConstraint.activate([horizontalCenterContraint, widthContraint])
        NSLayoutConstraint.activate(verticalContraint)
        
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn, animations: {
            toastView.alpha = 1
        }, completion: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: {
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn, animations: {
                toastView.alpha = 0
            }, completion: { finished in
                toastView.removeFromSuperview()
            })
        })
    }
}


// MARK: LMViewLifeCycle
extension LMViewController: LMViewLifeCycle {
    /// This function handles the initialization of views.
    open func setupViews() { }
    
    /// This function handles the initialization of autolayouts.
    open func setupLayouts() { }
    
    /// This function handles the initialization of actions.
    open func setupActions() { }
    
    /// This function handles the initialization of styles.
    open func setupAppearance() { }
    
    /// This function handles the initialization of observers.
    open func setupObservers() { }
}


// MARK: LMBaseViewControllerProtocol
@objc
extension LMViewController: LMBaseViewControllerProtocol {
    open func presentAlert(with alert: UIAlertController, animated: Bool = true) {
        present(alert, animated: animated)
    }
    
    open func showError(with message: String, isPopVC: Bool) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        
        let action = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            if isPopVC {
                self?.navigationController?.popViewController(animated: true)
            }
        }
        
        alert.addAction(action)
        presentAlert(with: alert)
    }
    
    open func showHideLoaderView(isShow: Bool, backgroundColor: UIColor) {
        if isShow {
            view.addSubview(loaderScreen)
            loaderScreen.backgroundColor = backgroundColor
            loaderScreen.addSubview(loaderView)
            
            NSLayoutConstraint.activate([
                loaderScreen.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                loaderScreen.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                loaderScreen.topAnchor.constraint(equalTo: view.topAnchor),
                loaderScreen.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                
                loaderView.centerXAnchor.constraint(equalTo: loaderScreen.centerXAnchor),
                loaderView.centerYAnchor.constraint(equalTo: loaderScreen.centerYAnchor),
                loaderView.heightAnchor.constraint(equalToConstant: 50),
                loaderView.widthAnchor.constraint(equalTo: loaderView.heightAnchor, multiplier: 1)
            ])
            view.bringSubviewToFront(loaderScreen)
            loaderView.startAnimating()
        } else if loaderView.isDescendant(of: view) {
            view.sendSubviewToBack(loaderScreen)
            loaderView.stopAnimating()
            loaderView.removeFromSuperview()
            loaderScreen.removeFromSuperview()
        }
    }
    
    open func popViewController(animated: Bool) {
        navigationController?.popViewController(animated: animated)
    }
}
