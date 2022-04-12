import UIKit


typealias CompletionForAnimation = ((Bool) -> Void)?

protocol UserView {
    var internetService: UserInternetService? { get set }
    func reload()
    func animateResponseError(with error: String)
    func animateGoodConnection()
}

final class ViewController: UIViewController, UserView {
    
    var internetService: UserInternetService?
    
    private let commonTable: UITableView = {
        let tbl = UITableView()
        tbl.register(MyTableViewCell.self, forCellReuseIdentifier: MyTableViewCell.id)
        return tbl
    }()
    
    private let stackViewForGhostLoadingViews: UIStackView = {
        let stack = UIStackView()
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.axis = .vertical
        stack.spacing = 10
        return stack
    }()
    
    var responseErrorNotificationLabel: UILabel = {
        let responseErrorView = UILabel()
        responseErrorView.backgroundColor = .systemRed
        responseErrorView.layer.cornerRadius = 8
        responseErrorView.translatesAutoresizingMaskIntoConstraints = false
        responseErrorView.textAlignment = .center
        responseErrorView.numberOfLines = 0
        responseErrorView.font = .systemFont(ofSize: 20, weight: .heavy)
        responseErrorView.layer.masksToBounds = true
        responseErrorView.adjustsFontSizeToFitWidth = true
        responseErrorView.textColor = .white
        return responseErrorView
    }()
    
    private func makeNewGhostView(with name: String) -> UIView {
        let name = UIView()
        name.backgroundColor = Colors.valueForLoading
        name.layer.cornerRadius = 8
        name.alpha = 0
        return name
    }
    
    func reload() {
        commonTable.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setKostylgesture()
        configureRefreshControl()
        configureNavigationBar()
        setupUI()
    }
    
    // MARK: Configure navigation bar
    // I don't know why - my bar item buttons are not clickable wtf (sure i did everything right and for now deleted action for it and set nil - look down) ... If u know - let me know please, but for now - i'll do this not elegant thing
    private let kostylForRightBarButtonItem: UIButton = {
        let btn = UIButton()
        btn.backgroundColor = .clear
        return btn
    }()
    
    private func setKostylgesture() {
        let gesture = UILongPressGestureRecognizer(
            target: self,
            action: #selector(searchAction))
        gesture.minimumPressDuration = 0
        kostylForRightBarButtonItem.addGestureRecognizer(gesture)
    }
    
    @objc private func searchAction(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            UIView.animate(withDuration: 0.5,
                           delay: 0,
                           usingSpringWithDamping: 0.5,
                           initialSpringVelocity: 0.1,
                           options: .curveEaseIn,
                           animations: { [self] in
                if navigationItem.searchController != nil {
                    navigationItem.searchController = nil
                } else {
                    setSearchVC()
                    navigationItem.hidesSearchBarWhenScrolling = false
                }
            })
        }
    }
    
    private func configureNavigationBar() {
        navigationItem.title = "News ಠ_ಠ"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.backButtonTitle = ""
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search,
                                                            target: self,
                                                            action: nil) // yep
        navigationController?.navigationBar.largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 40,
                                     weight: .heavy),
            .foregroundColor: UIColor.label
        ]
        navigationController?.navigationBar.backgroundColor = .clear
        navigationController?.navigationBar.tintColor = Colors.valueForColor
    }
    
    private func setSearchVC() {
        let searchVC = UISearchController()
        navigationItem.searchController = searchVC
        searchVC.searchBar.keyboardType = .asciiCapable
        searchVC.searchBar.delegate = self
        searchVC.searchBar.placeholder = "Keyword?"
    }
    
    // MARK: Setup UI
    private func setupUI() {
        commonTable.delegate = self
        commonTable.dataSource = self
        commonTable.frame = view.bounds
        commonTable.estimatedRowHeight = 44
        commonTable.rowHeight = UITableView.automaticDimension
        commonTable.showsVerticalScrollIndicator = false 
        for number in 1...7 {
            stackViewForGhostLoadingViews
                .addArrangedSubview(makeNewGhostView(with: "loadingGhostView\(number)"))
        }
        commonTable.addSubview(stackViewForGhostLoadingViews)
        view.addSubview(commonTable)
        view.addSubview(responseErrorNotificationLabel)
        navigationController?.navigationBar.addSubview(kostylForRightBarButtonItem)
        kostylForRightBarButtonItem.frame = CGRect(x: view.bounds.maxX - 60,
                                                   y: 0,
                                                   width: 60,
                                                   height: 50)
        stackViewForGhostLoadingViews.frame = commonTable.bounds
        NSLayoutConstraint.activate([
            responseErrorNotificationLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 10),
            responseErrorNotificationLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -10),
            responseErrorNotificationLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            responseErrorNotificationLabel.heightAnchor.constraint(equalToConstant: 0)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let newsArray = internetService?.newsArray else { return }
        if newsArray.isEmpty {
            animateLoading()
            Task {
                try await internetService?.getData(completion: {
                    DispatchQueue.main.async {
                        self.stopAnimatingAndHide()
                    }
                }, with: nil)
            }
        }
    }
    
    func animateGoodConnection() {
        DispatchQueue.main.async { [weak self] in
            if self?.navigationController?.navigationBar.layer.shadowColor != Colors.valueForButtonColor.cgColor {
                self?.animateNaVbarBackGrColor(completion: nil)
            }
        }
    }
    
    private func animateNaVbarBackGrColor(completion: CompletionForAnimation) {
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       usingSpringWithDamping: 0.1,
                       initialSpringVelocity: 0.1,
                       options: .curveEaseIn,
                       animations: {
            self.navigationController?.navigationBar.setShadow(configureBorder: false)
        }, completion: completion)
    }
    
    // MARK: Skeletons animations
    private func animateLoading() {
        stackViewForGhostLoadingViews.isHidden = false
        UIView.animate(withDuration: 1.0,
                       delay: 0,
                       options: [.autoreverse,.repeat,.curveEaseIn],
                       animations: {
            self.stackViewForGhostLoadingViews.arrangedSubviews.forEach {
                $0.alpha = 1
            }
        }, completion: { finished in
            self.stackViewForGhostLoadingViews.arrangedSubviews.forEach {
                $0.alpha = 0
            }
        })
    }
    
    private func stopAnimatingAndHide() {
        stackViewForGhostLoadingViews.arrangedSubviews.forEach {
            $0.layer.removeAllAnimations()
        }
        stackViewForGhostLoadingViews.isHidden.toggle()
    }
}
// MARK: TableView delegate & dataSource methods
extension ViewController : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return internetService?.newsArray.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MyTableViewCell.id, for: indexPath) as! MyTableViewCell
        let model = internetService?.newsArray[indexPath.row]
        cell.titleLabel.text = model?.title?.configureNewsTitle()
        cell.newsDate.text = model?.publishedAt?.configureTime()
        cell.newsSource.text = model?.source?.name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let topic = internetService?.newsArray[indexPath.row]
        let secondVC = SecondViewController()
        secondVC.topicLabel.text = topic?.description ?? Errors.topicLabelNoInfo.rawValue
        secondVC.newsImage.downLoadImage(from: topic?.urlToImage ?? Errors.error.rawValue, completion: {
            secondVC.counter += 1
        })
        secondVC.moreInfo = topic?.url ?? Errors.error.rawValue
        navigationController?.pushViewController(secondVC, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: Refresh control settings
extension ViewController {
    func configureRefreshControl () {
        commonTable.refreshControl = UIRefreshControl()
        commonTable.refreshControl?.addTarget(self, action:
                                                #selector(handleRefreshControl),
                                              for: .valueChanged)
    }
    
    @objc func handleRefreshControl() {
        internetService?.newsArray.removeAll()
        reload()
        commonTable.refreshControl?.endRefreshing()
        animateLoading()
        Task {
            try await internetService?.getData(completion: {
                DispatchQueue.main.async {
                    self.stopAnimatingAndHide()
                }
            }, with: nil)
        }
    }
}

// MARK: Animate errors
extension ViewController {
    
    func animateResponseError(with error: String) {
        DispatchQueue.main.async { [weak self] in
            self?.responseErrorNotificationLabel.text = error
            self?.setErrorResponseLabelHeightConstraint(to: 100, from: 0)
            UIView.animate(withDuration: 2.0,
                           delay: 0,
                           usingSpringWithDamping: 0.1,
                           initialSpringVelocity: 0.1,
                           options: .curveEaseIn,
                           animations: {
                self?.view.layoutIfNeeded()
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                self?.navigationController?.navigationBar.layer.shadowColor = UIColor.clear.cgColor
            }, completion: { finished in
                self?.animateChanges()
            })
        }
    }
    
    func setErrorResponseLabelHeightConstraint(to oneValue: CGFloat, from anotherValue: CGFloat) {
        responseErrorNotificationLabel.constraints.forEach {
            if $0.constant == anotherValue {
                responseErrorNotificationLabel.removeConstraint($0)
            }
        }
        responseErrorNotificationLabel.heightAnchor.constraint(equalToConstant: oneValue).isActive = true
    }
    
    func animateChanges() {
        setErrorResponseLabelHeightConstraint(to: 0, from: 100)
        UIView.animate(withDuration: 2.0,
                       delay: 5.0,
                       usingSpringWithDamping: 0.1,
                       initialSpringVelocity: 0.1,
                       options: .curveLinear,
                       animations: {
            self.view.layoutIfNeeded()
        })
    }
}

extension UIStackView {
    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        super.point(inside: point, with: event)
        return false
    }
}

// MARK: Search bar delegate settings
extension ViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        internetService?.newsArray.removeAll()
        reload()
        animateLoading()
        Task {
            try await internetService?.getData(completion: {
                DispatchQueue.main.async {
                    self.stopAnimatingAndHide()
                    searchBar.text?.removeAll()
                    self.view.endEditing(true)
                }
            }, with: searchBar.text)
        }
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        guard let text = searchBar.text else { return false }
        if text.isEmpty {
            kostylForRightBarButtonItem.isHidden = true
        }
        return true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        kostylForRightBarButtonItem.isHidden.toggle()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchBar.text = searchBar.text?.filter{ $0.isLetter && $0 != " " }
    }
}

