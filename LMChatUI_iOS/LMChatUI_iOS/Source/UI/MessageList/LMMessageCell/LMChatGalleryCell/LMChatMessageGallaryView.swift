//
//  LMChatMessageGallaryView.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 02/04/24.
//

import Foundation
import Kingfisher

public protocol LMChatMessageGallaryViewDelegate: AnyObject {
    func onClickAttachment(_ index: Int)
}

open class LMChatMessageGallaryView: LMView {

    struct ContentModel {
        public let fileUrl: String?
        public let thumbnailUrl: String?
        public let fileSize: Int?
        public let duration: Int?
        public let fileType: AttachmentViewData.AttachmentType?
        public let fileName: String?
    }

    /// Content the gallery should display.
    public var content: [UIView] = []

    // Previews indices locations:
    // When one item available:
    // -------
    // |     |
    // |  0  |
    // |     |
    // -------
    // When two items available or When three items available:
    // -------------
    // |     |     |
    // |  0  |  1  |
    // |     |     |
    // -------------
    // When four and more items available:
    // -------------
    // |     |     |
    // |  0  |  1  |
    // |     |     |
    // -------------
    // |     |     |
    // |  2  |  3  |
    // |     |     |
    // -------------
    /// The spots gallery items takes.
    public private(set) lazy var itemSpots = [
        itemSpot0,
        itemSpot1,
        itemSpot2,
        itemSpot3,
    ]

    open private(set) lazy var singleImage: ImagePreview = { [unowned self] in
        let imagePreview = ImagePreview()
            .translatesAutoresizingMaskIntoConstraints()
        imagePreview.backgroundColor = .black
        imagePreview.cornerRadius(with: 12)
        imagePreview.tag = 0
        imagePreview.isUserInteractionEnabled = true
        let tapGuesture = UITapGestureRecognizer(
            target: self,
            action: #selector(onAttachmentClicked)
        )
        tapGuesture.numberOfTapsRequired = 1
        imagePreview.addGestureRecognizer(tapGuesture)
        imagePreview.widthAnchor.constraint(equalToConstant: widthViewSize)
            .isActive = true
        let aspectRatioConstraints = NSLayoutConstraint(
            item: imagePreview,
            attribute: .width,
            relatedBy: .lessThanOrEqual,
            toItem: imagePreview,
            attribute: .height,
            multiplier: 1.4,
            constant: 0
        )
        imagePreview.addConstraint(aspectRatioConstraints)
        imagePreview.heightAnchor.constraint(equalToConstant: heightViewSize)
            .isActive = true
        return imagePreview
    }()

    open private(set) lazy var itemSpot0: ImagePreview = { [unowned self] in
        let imagePreview = ImagePreview()
            .translatesAutoresizingMaskIntoConstraints()
        imagePreview.backgroundColor = .black
        imagePreview.cornerRadius(with: 12)
        imagePreview.tag = 0
        imagePreview.isUserInteractionEnabled = true
        let tapGuesture = UITapGestureRecognizer(
            target: self,
            action: #selector(onAttachmentClicked)
        )
        tapGuesture.numberOfTapsRequired = 1
        imagePreview.addGestureRecognizer(tapGuesture)
        imagePreview.widthAnchor.constraint(equalToConstant: widthViewSize / 2)
            .isActive = true
        let aspectRatioConstraints = NSLayoutConstraint(
            item: imagePreview,
            attribute: .width,
            relatedBy: .lessThanOrEqual,
            toItem: imagePreview,
            attribute: .height,
            multiplier: 1.4,
            constant: 0
        )
        imagePreview.addConstraint(aspectRatioConstraints)
        imagePreview.heightAnchor.constraint(
            equalToConstant: heightViewSize / 2
        ).isActive = true
        return imagePreview
    }()

    open private(set) lazy var itemSpot1: ImagePreview = { [unowned self] in
        let imagePreview = ImagePreview()
            .translatesAutoresizingMaskIntoConstraints()
        imagePreview.backgroundColor = .black
        imagePreview.cornerRadius(with: 12)
        imagePreview.tag = 1
        imagePreview.isUserInteractionEnabled = true
        let tapGuesture = UITapGestureRecognizer(
            target: self,
            action: #selector(onAttachmentClicked)
        )
        tapGuesture.numberOfTapsRequired = 1
        imagePreview.addGestureRecognizer(tapGuesture)
        imagePreview.widthAnchor.constraint(equalToConstant: widthViewSize / 2)
            .isActive = true
        let aspectRatioConstraints = NSLayoutConstraint(
            item: imagePreview,
            attribute: .width,
            relatedBy: .lessThanOrEqual,
            toItem: imagePreview,
            attribute: .height,
            multiplier: 1.4,
            constant: 0
        )
        imagePreview.addConstraint(aspectRatioConstraints)
        imagePreview.heightAnchor.constraint(
            equalToConstant: heightViewSize / 2
        ).isActive = true
        return imagePreview
    }()

    open private(set) lazy var itemSpot2: ImagePreview = { [unowned self] in
        let imagePreview = ImagePreview()
            .translatesAutoresizingMaskIntoConstraints()
        imagePreview.backgroundColor = .black
        imagePreview.cornerRadius(with: 12)
        imagePreview.tag = 2
        imagePreview.isUserInteractionEnabled = true
        let tapGuesture = UITapGestureRecognizer(
            target: self,
            action: #selector(onAttachmentClicked)
        )
        tapGuesture.numberOfTapsRequired = 1
        imagePreview.addGestureRecognizer(tapGuesture)
        imagePreview.widthAnchor.constraint(equalToConstant: widthViewSize / 2)
            .isActive = true
        let aspectRatioConstraints = NSLayoutConstraint(
            item: imagePreview,
            attribute: .width,
            relatedBy: .lessThanOrEqual,
            toItem: imagePreview,
            attribute: .height,
            multiplier: 1.4,
            constant: 0
        )
        imagePreview.addConstraint(aspectRatioConstraints)
        imagePreview.heightAnchor.constraint(
            equalToConstant: heightViewSize / 2
        ).isActive = true
        return imagePreview
    }()

    open private(set) lazy var itemSpot3: ImagePreview = { [unowned self] in
        let imagePreview = ImagePreview()
            .translatesAutoresizingMaskIntoConstraints()
        imagePreview.backgroundColor = .black
        imagePreview.cornerRadius(with: 12)
        imagePreview.tag = 3
        imagePreview.isUserInteractionEnabled = true
        let tapGuesture = UITapGestureRecognizer(
            target: self,
            action: #selector(onAttachmentClicked)
        )
        tapGuesture.numberOfTapsRequired = 1
        imagePreview.addGestureRecognizer(tapGuesture)
        imagePreview.widthAnchor.constraint(equalToConstant: widthViewSize / 2)
            .isActive = true
        let aspectRatioConstraints = NSLayoutConstraint(
            item: imagePreview,
            attribute: .width,
            relatedBy: .lessThanOrEqual,
            toItem: imagePreview,
            attribute: .height,
            multiplier: 1.4,
            constant: 0
        )
        imagePreview.addConstraint(aspectRatioConstraints)
        imagePreview.heightAnchor.constraint(
            equalToConstant: heightViewSize / 2
        ).isActive = true
        return imagePreview
    }()

    /// Overlay to be displayed when `content` contains more items than the gallery can display.
    public private(set) lazy var moreItemsOverlay: LMLabel = {
        let label = LMLabel()
            .translatesAutoresizingMaskIntoConstraints()
        label.textColor = Appearance.shared.colors.white
        label.textAlignment = .center
        label.font = Appearance.shared.fonts.headingFont
        label.backgroundColor = Appearance.shared.colors.black
            .withAlphaComponent(0.7)
        label.text = "+2"
        return label
    }()

    /// Container holding all previews.
    open private(set) lazy var previewsContainerView: LMStackView = {
        let view = LMStackView().translatesAutoresizingMaskIntoConstraints()
        view.axis = .vertical
        view.distribution = .fillEqually
        view.alignment = .fill
        view.spacing = 4
        view.isLayoutMarginsRelativeArrangement = true
        return view
    }()

    /// Left container for previews.
    public private(set) lazy var topPreviewsContainerView: LMStackView = {
        let view = LMStackView().translatesAutoresizingMaskIntoConstraints()
        view.spacing = 4
        view.axis = .horizontal
        view.distribution = .fillEqually
        view.alignment = .fill
        return view
    }()

    /// Right container for previews.
    public private(set) lazy var bottomPreviewsContainerView: LMStackView = {
        let view = LMStackView().translatesAutoresizingMaskIntoConstraints()
        view.spacing = 4
        view.axis = .horizontal
        view.distribution = .fillEqually
        view.alignment = .fill
        return view
    }()

    var viewData: [ContentModel]?
    weak var delegate: LMChatMessageGallaryViewDelegate?

    // MARK: - Overrides

    open override func setupLayouts() {
        super.setupLayouts()

        pinSubView(subView: previewsContainerView)

    }

    // MARK: setupViews
    open override func setupViews() {
        super.setupViews()
        addSubview(previewsContainerView)
        previewsContainerView.addArrangedSubview(topPreviewsContainerView)

        topPreviewsContainerView.addArrangedSubview(itemSpots[0])
        topPreviewsContainerView.addArrangedSubview(itemSpots[1])

        previewsContainerView.addArrangedSubview(bottomPreviewsContainerView)

        bottomPreviewsContainerView.addArrangedSubview(itemSpots[2])
        bottomPreviewsContainerView.addArrangedSubview(itemSpots[3])

        previewsContainerView.addArrangedSubview(singleImage)
    }

    override open func setupAppearance() {
        super.setupAppearance()
    }
    func setData(_ data: [ContentModel]) {
        viewData = data
        itemSpots.forEach({ $0.isHidden = true })
        singleImage.isHidden = true
        if data.count == 1, let item = data.first {
            singleImage.isHidden = false
            topPreviewsContainerView.isHidden = true
            bottomPreviewsContainerView.isHidden = true
            loadImageData(item: item, imagePreview: singleImage)
            return
        } else {
            topPreviewsContainerView.isHidden = false
        }
        bottomPreviewsContainerView.isHidden = data.count <= 3
        for (index, item) in data.enumerated() {
            if data.count > 4 {
                if index > 3 {
                    itemSpots[index - 1].addSubviewWithDefaultConstraints(
                        moreItemsOverlay
                    )
                    moreItemsOverlay.isHidden = false
                    moreItemsOverlay.text = "+\(data.count - 3)"
                    break
                }
            } else if data.count > 2 && data.count < 4 {
                if index > 1 {
                    itemSpots[index - 1].addSubviewWithDefaultConstraints(
                        moreItemsOverlay
                    )
                    moreItemsOverlay.isHidden = false
                    moreItemsOverlay.text = "+\(data.count - 1)"
                    break
                }
            }
            moreItemsOverlay.isHidden = true
            loadImageData(item: item, imagePreview: itemSpots[index])
        }
    }

    func loadImageData(item: ContentModel, imagePreview: ImagePreview) {
        var imageUrl: String?

        if item.fileType == .video {
            imageUrl = item.thumbnailUrl
        } else {
            imageUrl = item.fileUrl
        }

        guard let imageUrl else {
            return
        }

        imagePreview.isHidden = false

        if item.fileType == .video {
            imagePreview.setData(imageUrl, withPlaceholder: nil)
            imagePreview.playIconImage.isHidden = false
        } else {
            imagePreview.setData(imageUrl)
            imagePreview.playIconImage.isHidden = true
        }
    }

    @objc func onAttachmentClicked(_ gesture: UITapGestureRecognizer) {
        guard let tag = gesture.view?.tag else { return }
        delegate?.onClickAttachment(tag)
    }

}

extension LMChatMessageGallaryView {

    open class ImagePreview: LMView {

        // MARK: - Subviews

        public private(set) lazy var imageView: LMImageView = {
            let imageView = LMImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.layer.masksToBounds = true
            imageView.image = Constants.shared.images.galleryIcon
            imageView.backgroundColor = Appearance.shared.colors.black
            return
                imageView
                .translatesAutoresizingMaskIntoConstraints()
        }()

        open private(set) lazy var playIconImage: LMImageView = {
            let image = LMImageView()
            image.translatesAutoresizingMaskIntoConstraints = false
            image.contentMode = .scaleAspectFill
            image.clipsToBounds = true
            image.backgroundColor = Appearance.shared.colors.white
            image.isUserInteractionEnabled = false
            image.image = Constants.shared.images.playCircleFilled
            image.setWidthConstraint(with: 40)
            image.setHeightConstraint(with: 40)
            image.cornerRadius(with: 20)
            image.tintColor = Appearance.shared.colors.black.withAlphaComponent(
                0.8
            )
            return image
        }()

        override open func setupAppearance() {
            super.setupAppearance()
        }

        override open func setupViews() {
            super.setupViews()
            addSubview(imageView)
            addSubview(playIconImage)
        }

        override open func setupLayouts() {
            super.setupLayouts()
            pinSubView(subView: imageView)
            playIconImage.centerYAnchor.constraint(equalTo: centerYAnchor)
                .isActive = true
            playIconImage.centerXAnchor.constraint(equalTo: centerXAnchor)
                .isActive = true
        }

        func setData(
            _ url: String,
            withPlaceholder placeholder: UIImage? = UIImage(
                named: "imageplaceholder",
                in: Bundle.LMBundleIdentifier,
                compatibleWith: nil
            )
        ) {
            imageView.kf.setImage(
                with: URL(string: url),
                placeholder: placeholder
            )
        }
    }
}
