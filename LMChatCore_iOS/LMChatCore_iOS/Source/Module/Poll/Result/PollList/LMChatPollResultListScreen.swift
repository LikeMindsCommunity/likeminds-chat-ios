//
//  LMChatPollResultListScreen.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 30/07/24.
//

import LikeMindsChatUI

open class LMChatPollResultListScreen: LMViewController {
    // MARK: UI Elements
    open private(set) lazy var voteView: LMTableView = {
        let table = LMTableView().translatesAutoresizingMaskIntoConstraints()
        table.register(LMUIComponents.shared.participantListCell)
        table.dataSource = self
        table.delegate = self
        table.showsVerticalScrollIndicator = false
        table.showsHorizontalScrollIndicator = false
        table.separatorStyle = .none
        return table
    }()
    
    open private(set) lazy var indicatorView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.style = .large
        return indicator
    }()
    
    open private(set) lazy var noResultView: LMChatNoResultView = {
        let view = LMChatNoResultView().translatesAutoresizingMaskIntoConstraints()
        return view
    }()
    
    
    // MARK: Data Variables
    public var userList: [LMChatParticipantCell.ContentModel] = []
    public var viewModel: LMChatPollResultListViewModel?
    
    
    // MARK: setupViews
    open override func setupViews() {
        super.setupViews()
        
        view.addSubview(voteView)
        view.addSubview(noResultView)
    }
    
    
    // MARK: setupLayouts
    open override func setupLayouts() {
        super.setupLayouts()
        view.safeAreaPinSubView(subView: voteView)
        view.safeAreaPinSubView(subView: noResultView)
    }
    
    
    // MARK: setupAppearance
    open override func setupAppearance() {
        super.setupAppearance()
        
        voteView.backgroundColor = Appearance.shared.colors.clear
        view.backgroundColor = Appearance.shared.colors.clear
    }
    
    // MARK: viewDidLoad
    open override func viewDidLoad() {
        super.viewDidLoad()
        viewModel?.fetchUserList()
    }
}


// MARK: TableView
extension LMChatPollResultListScreen: UITableViewDataSource, UITableViewDelegate {
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        userList.count
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let data = userList[safe: indexPath.row],
            let cell = tableView.dequeueReusableCell(LMUIComponents.shared.participantListCell) {
            cell.configure(with: data)
            return cell
        }
        
        return UITableViewCell()
    }
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let participant = userList[safe: indexPath.row] else { return }
        LMChatCore.shared.coreCallback?.userProfileViewHandle(withRoute: LMStringConstant.shared.profileRoute + (participant.id ?? ""))
    }
}


// MARK: LMChatPollResultListViewModelProtocol
extension LMChatPollResultListScreen: LMChatPollResultListViewModelProtocol {
    public func reloadResults(with userList: [LMChatParticipantCell.ContentModel]) {
        noResultView.isHidden = !userList.isEmpty
        voteView.backgroundView = nil
        
        self.userList = userList
        voteView.reloadData()
    }
    
    public func showLoader() {
        userList.removeAll(keepingCapacity: true)
        voteView.reloadData()
        
        voteView.backgroundView = indicatorView
        indicatorView.addConstraint(centerX: (voteView.centerXAnchor, 0),
                                    centerY: (voteView.centerYAnchor, 0))
        indicatorView.startAnimating()
    }
    
    public func showHideTableFooter(isShow: Bool) {
        voteView.showHideFooterLoader(isShow: isShow)
    }
}
