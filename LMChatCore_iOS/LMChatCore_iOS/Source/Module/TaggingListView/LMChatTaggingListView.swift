//
//  LMChatTaggingListView.swift
//  lm-feedCore-iOS
//
//  Created by Devansh Mohata on 11/01/24.
//

import UIKit
import LikeMindsChatUI

public protocol LMChatTaggedUserFoundProtocol: AnyObject {
    func userSelected(with route: String, and userName: String)
    func updateHeight(with height: CGFloat)
}

public protocol LMChatTaggingProtocol: AnyObject {
    func fetchUsers(for searchString: String, chatroomId: String)
}

@IBDesignable
open class LMChatTaggingListView: LMView {
    // MARK: UI Elements
    open private(set) lazy var containerView: LMView = {
        let view = LMView().translatesAutoresizingMaskIntoConstraints()
        return view
    }()
    
    open private(set) lazy var tableView: LMTableView = {[unowned self] in
        let table = LMTableView().translatesAutoresizingMaskIntoConstraints()
        table.dataSource = self
        table.delegate = self
        table.showsVerticalScrollIndicator = false
        table.clipsToBounds = true
        table.separatorStyle = .none
        table.register(LMUIComponents.shared.taggingTableViewCell)
        return table
    }()
    
    
    // MARK: Data Variables
    public let cellHeight: CGFloat = 60
    public var taggingCellsData: [LMChatTaggingUserTableCell.ViewModel] = []
    public var viewModel: LMChatTaggingListViewModel?
    public weak var delegate: LMChatTaggedUserFoundProtocol?
    
    
    // MARK: setupViews
    open override func setupViews() {
        super.setupViews()
        addSubview(containerView)
        containerView.addSubview(tableView)
    }
    
    
    // MARK: setupLayouts
    open override func setupLayouts() {
        super.setupLayouts()
        pinSubView(subView: containerView)
        containerView.pinSubView(subView: tableView)
    }
    
    
    // MARK: setupAppearance
    open override func setupAppearance() {
        super.setupAppearance()
        backgroundColor = Appearance.shared.colors.clear
        containerView.backgroundColor = Appearance.shared.colors.white
        containerView.layer.borderColor = Appearance.shared.colors.gray4.cgColor
        containerView.layer.borderWidth = 1
        containerView.roundCornerWithShadow(cornerRadius: 16, shadowRadius: .zero, offsetX: .zero, offsetY: .zero, colour: .black, opacity: 0.1, corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
        tableView.backgroundColor = Appearance.shared.colors.clear
    }
    
    
    // MARK: Get Users
    public func getUsers(for searchString: String, chatroomId: String) {
        viewModel?.fetchUsers(with: searchString, chatroomId: chatroomId)
    }
    
    public func stopFetchingUsers() {
        viewModel?.stopFetchingUsers()
    }
}


// MARK: UITableView
extension LMChatTaggingListView: UITableViewDataSource, UITableViewDelegate {
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        taggingCellsData.count
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(LMUIComponents.shared.taggingTableViewCell) {
            let data = taggingCellsData[indexPath.row]
            cell.configure(with: data)
            return cell
        }
        
        return UITableViewCell()
    }
    
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { cellHeight
    }
    
    open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if taggingCellsData.count - 1 == indexPath.row {
            viewModel?.fetchMoreUsers()
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = taggingCellsData[indexPath.row]
        delegate?.userSelected(with: user.route, and: user.userName)
    }
    
}


// MARK: LMChatTaggingListViewModelProtocol
extension LMChatTaggingListView: LMChatTaggingListViewModelProtocol {
    public func updateList(with users: [LMChatTaggingUserTableCell.ViewModel]) {
        taggingCellsData.removeAll(keepingCapacity: true)
        taggingCellsData.append(contentsOf: users)
        tableView.reloadData()
        delegate?.updateHeight(with: min(tableView.tableViewHeight, cellHeight * 3))
    }
}


// MARK: LMChatTaggingProtocol
extension LMChatTaggingListView: LMChatTaggingProtocol {
    public func fetchUsers(for searchString: String, chatroomId: String) {
        viewModel?.fetchUsers(with: searchString, chatroomId: chatroomId)
    }
}
