//
//  LMChatMediaPreviewScreen.swift
//  LikeMindsChatCore
//
//  Created by Devansh Mohata on 19/04/24.
//

import AVKit
import LikeMindsChatUI
import UIKit

open class LMChatMediaPreviewScreen: LMViewController {
    open private(set) lazy var mediaCollectionView: LMCollectionView = { [unowned self] in
        let collectionView = LMCollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.registerCell(type: LMChatMediaImagePreview.self)
        collectionView.registerCell(type: LMChatMediaVideoPreview.self)
        collectionView.isPagingEnabled = true
        collectionView.bounces = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()
    
    lazy var layout = UICollectionViewCompositionalLayout {[unowned self] (sectionIndex, environment) -> NSCollectionLayoutSection? in
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPagingCentered
        
        section.visibleItemsInvalidationHandler = { [weak self] visibleItems, _, _ in
            self?.setNavigationData(index: visibleItems.last?.indexPath.row ?? 0)
        }
        
        return section
    }
    
    var viewModel: LMChatMediaPreviewViewModel!
    var mediaData: [LMChatMediaPreviewContentModel] = []
    var userName = ""
    var date = ""
    
    open override func setupViews() {
        super.setupViews()
        view.addSubview(mediaCollectionView)
    }
    
    open override func setupLayouts() {
        super.setupLayouts()
        
        mediaCollectionView.addConstraint(top: (view.safeAreaLayoutGuide.topAnchor, 0),
                                          bottom: (view.safeAreaLayoutGuide.bottomAnchor, 0),
                                          leading: (view.safeAreaLayoutGuide.leadingAnchor, 0),
                                          trailing: (view.safeAreaLayoutGuide.trailingAnchor, 0))
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.showMediaPreview()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.scrollToMediaPreview()
    }
        
    open func navigateToVideoPlayer(with url: String) {
        guard let videoURL = URL(string: url) else {
            showErrorAlert(message: "Unable to play video")
            return
        }
        
        let player = AVPlayer(url: videoURL)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        playerViewController.allowsPictureInPicturePlayback = false
        playerViewController.showsPlaybackControls = true
        
        present(playerViewController, animated: false) {
            player.play()
        }
    }
}

extension LMChatMediaPreviewScreen: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        mediaData.count
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if mediaData[indexPath.row].isVideo,
           let cell = collectionView.dequeueReusableCell(with: LMChatMediaVideoPreview.self, for: indexPath) {
            cell.configure(with: mediaData[indexPath.row]) { [weak self] in
                guard let self else { return }
                navigateToVideoPlayer(with: mediaData[indexPath.row].mediaURL)
            }
            return cell
        } else if let cell = collectionView.dequeueReusableCell(with: LMChatMediaImagePreview.self, for: indexPath) {
            cell.configure(with: mediaData[indexPath.row])
            return cell
        }
        
        return UICollectionViewCell()
    }
}


// MARK: LMMediaViewModelDelegate
extension LMChatMediaPreviewScreen: LMMediaViewModelDelegate {
    public func showImages(with media: [LMChatMediaPreviewContentModel], userName: String, date: String) {
        self.mediaData = media
        mediaCollectionView.reloadData()
        
        self.userName = userName
        self.date = date
    }
    
    public func scrollToIndex(index: Int) {
        if index < mediaCollectionView.numberOfItems(inSection: 0) {
            DispatchQueue.main.async { [weak self] in
                self?.mediaCollectionView.isPagingEnabled = false
                self?.mediaCollectionView.scrollToItem(at: .init(row: index, section: 0), at: .centeredHorizontally, animated: true)
                self?.mediaCollectionView.isPagingEnabled = true
            }
        }
        
        setNavigationData(index: index)
    }
    
    public func setNavigationData(index: Int) {
        var subtitle = date
        
        if mediaData.count > 1 {
            subtitle = "\(index + 1) of \(mediaData.count) •" + subtitle
        }
        
        setNavigationTitleAndSubtitle(with: userName, subtitle: subtitle, alignment: .leading)
    }
}
