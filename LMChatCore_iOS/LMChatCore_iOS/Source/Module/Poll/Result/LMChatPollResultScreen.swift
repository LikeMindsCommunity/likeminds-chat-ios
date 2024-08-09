//
//  LMChatPollResultScreen.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 30/07/24.
//

import LikeMindsChatUI
import UIKit

open class LMChatPollResultScreen: LMViewController {
    open private(set) lazy var containerView: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        return view
    }()
    
    open private(set) lazy var optionView: LMCollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        let collection = LMCollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.registerCell(type: LMUIComponents.shared.resultPollOptionCell)
        collection.dataSource = self
        collection.delegate = self
        collection.bounces = false
        collection.showsHorizontalScrollIndicator = false
        collection.showsVerticalScrollIndicator = false
        return collection
    }()
    
    open private(set) lazy var pageController: UIPageViewController = {
        let controller = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        controller.dataSource = self
        controller.delegate = self
        return controller
    }()
    
    open private(set) lazy var optionViewBottomLine: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        return view
    }()
    
    // MARK: Data Variables
    public var optionList: [LMChatPollResultCollectionCell.ContentModel] = []
    public var userListVC: [UIViewController] = []
    public var viewModel: LMChatPollResultViewModel?
    
    
    open override func setupViews() {
        super.setupViews()
        
        view.addSubview(containerView)
        containerView.addSubview(optionView)
        containerView.addSubview(optionViewBottomLine)
        
        self.addChild(pageController)
        containerView.addSubview(pageController.view)
        self.pageController.didMove(toParent: self)
    }
    
    open override func setupLayouts() {
        super.setupLayouts()
        
        view.safeAreaPinSubView(subView: containerView)
        
        optionView.addConstraint(top: (containerView.topAnchor, 0),
                                 leading: (containerView.leadingAnchor, 4),
                                 trailing: (containerView.trailingAnchor, 2))
        optionView.setHeightConstraint(with: 56, priority: .required)
        
        optionViewBottomLine.addConstraint(top: (optionView.bottomAnchor, 0),
                                 leading: (optionView.leadingAnchor, 0),
                                 trailing: (optionView.trailingAnchor, 0))
        optionViewBottomLine.setHeightConstraint(with: 1, priority: .required)
        
        pageController.view.translatesAutoresizingMaskIntoConstraints = false
        
        pageController.view.addConstraint(top: (optionViewBottomLine.bottomAnchor, 0),
                                          bottom: (containerView.bottomAnchor, 8),
                                          leading: (containerView.leadingAnchor, 0),
                                          trailing: (containerView.trailingAnchor, 0))
    }
    
    
    // MARK: setupAppearance
    open override func setupAppearance() {
        super.setupAppearance()
        
        view.backgroundColor = Appearance.shared.colors.white
        optionView.backgroundColor = Appearance.shared.colors.clear
        optionViewBottomLine.backgroundColor = Appearance.shared.colors.previewBackgroundColor
//        optionViewBottomLine.addShadow()
    }
    
    
    // MARK: viewDidLoad
    open override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationTitleAndSubtitle(with: "Poll Results", subtitle: nil, alignment: .center)
        viewModel?.initializeView()
    }
}


// MARK: Collection View
extension LMChatPollResultScreen: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        optionList.count
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let data = optionList[safe: indexPath.row],
           let cell = collectionView.dequeueReusableCell(with: LMUIComponents.shared.resultPollOptionCell, for: indexPath) {
            cell.configure(with: data)
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let count = optionList.count
        
        if count < 3 {
            return .init(width: collectionView.frame.width / CGFloat(count), height: collectionView.frame.height)
        } else {
            return .init(width: collectionView.frame.width * 0.3, height: collectionView.frame.height)
        }
    }
    
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let count = optionList.count
        
        for i in 0..<count {
            optionList[i].isSelected = indexPath.row == i
        }
        
        collectionView.reloadData()
        
        pageController.setViewControllers([userListVC[indexPath.row]], direction: .forward, animated: false)
    }
}


// MARK: LMChatPollResultViewModelProtocol
extension LMChatPollResultScreen: LMChatPollResultViewModelProtocol {
    public func loadOptionList(with data: [LMChatPollResultCollectionCell.ContentModel], index: Int) {
        self.optionList = data
        optionView.reloadData()
        
        DispatchQueue.main.async { [weak optionView] in
            optionView?.scrollToItem(at: .init(row: index, section: 0), at: .centeredHorizontally, animated: false)
        }
    }
    
    public func setupViewControllers(with pollID: String, optionList: [String], selectedID: Int) {
        optionList.forEach {
            let viewController = LMChatPollResultListViewModel.createModule(for: pollID, optionId: $0)
            userListVC.append(viewController)
        }
        
        pageController.setViewControllers([userListVC[selectedID]], direction: .forward, animated: false)
    }
}


// MARK: UIPageViewControllerDataSource
extension LMChatPollResultScreen: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    open func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        getViewController(forViewController: viewController, isNextController: false)
    }
    
    open func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        getViewController(forViewController: viewController, isNextController: true)
    }
    
    func getViewController(forViewController vc: UIViewController, isNextController: Bool) -> UIViewController? {
        var index: Int = 0
        
        for (location, scene) in userListVC.enumerated() {
            if scene == vc {
                index = location
                break
            }
        }
     
        index += isNextController ? 1 : -1
        
        if userListVC.indices.contains(index) {
            return userListVC[index]
        }
        
        return nil
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed,
           let first = pageViewController.viewControllers?.first,
           let index = userListVC.firstIndex(of: first) {
            let count = optionList.count
            
            for i in 0..<count {
                optionList[i].isSelected = index == i
            }
            
            optionView.reloadData()
            viewModel?.trackEventForPageSwipe(optionId: optionList[index].optionID)
            DispatchQueue.main.async { [weak optionView] in
                optionView?.scrollToItem(at: .init(row: index, section: 0), at: .centeredHorizontally, animated: false)
            }
        }
    }
}
