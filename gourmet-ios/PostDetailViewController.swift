//
//  PostDetailViewController.swift
//  gourmet-ios
//
//  Created by Cascade on 2025/4/4.
//

import UIKit
import Alamofire

// 确保 ParentPost 结构体在这里也可见
struct ParentPost: Codable {
    let id: Int
    let created_at: String
    let parent_id: Int
    let content: String
    let like_count: Int
    let dislike_count: Int
    let favorite_count: Int
    let view_count: Int
    let images: [PostImage]?
    let user: PostUser
}

class PostDetailViewController: UIViewController, UITextViewDelegate {
    
    // MARK: - 属性
    private let post: ParentPost
    private var replies: [ParentPost] = []
    private var currentPage = 1
    private var isLoading = false
    private var hasMoreData = true
    
    // MARK: - UI 组件
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        tableView.register(PostCell.self, forCellReuseIdentifier: "PostCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        refreshControl.tintColor = .systemBlue
        return refreshControl
    }()
    
    private lazy var replyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "square.and.pencil"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 30
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.2
        button.addTarget(self, action: #selector(replyButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - 初始化
    init(post: ParentPost) {
        self.post = post
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 生命周期方法
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置视图
        title = "推文详情"
        view.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        
        setupUI()
        loadReplies()
    }
    
    // MARK: - UI 设置
    private func setupUI() {
        // 添加 TableView
        view.addSubview(tableView)
        tableView.refreshControl = refreshControl
        
        // 添加回复按钮
        view.addSubview(replyButton)
        
        // 添加加载指示器
        view.addSubview(loadingIndicator)
        
        // 设置约束
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            replyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            replyButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            replyButton.widthAnchor.constraint(equalToConstant: 60),
            replyButton.heightAnchor.constraint(equalToConstant: 60),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - 数据加载
    @objc private func refreshData() {
        currentPage = 1
        hasMoreData = true
        loadReplies()
    }
    
    private func loadReplies() {
        guard !isLoading, hasMoreData else { return }
        
        isLoading = true
        
        if replies.isEmpty && !refreshControl.isRefreshing {
            loadingIndicator.startAnimating()
        }
        
        // 构建 URL
        var urlComponents = URLComponents(string: "https://gourmet.pfcent.com/api/v1/community/posts")!
        urlComponents.queryItems = [
            URLQueryItem(name: "page", value: "\(currentPage)"),
            URLQueryItem(name: "limit", value: "20"),
            URLQueryItem(name: "post_id", value: "\(post.id)")
        ]
        
        guard let url = urlComponents.url else {
            self.isLoading = false
            self.refreshControl.endRefreshing()
            self.loadingIndicator.stopAnimating()
            return
        }
        
        // 构建请求头
        var headers: HTTPHeaders = [
            "User-Agent": "Gourmet iOS"
        ]
        
        // 如果有 token，添加到请求头
        if let token = UserDefaults.standard.string(forKey: UserDefaultsKeys.token) {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        // 发送请求
        AF.request(url, method: .get, headers: headers)
            .responseDecodable(of: PostListResponse.self) { [weak self] response in
                guard let self = self else { return }
                
                self.isLoading = false
                self.refreshControl.endRefreshing()
                self.loadingIndicator.stopAnimating()
                
                switch response.result {
                case .success(let postResponse):
                    if self.currentPage == 1 {
                        self.replies = postResponse.data.list
                    } else {
                        self.replies.append(contentsOf: postResponse.data.list)
                    }
                    
                    self.hasMoreData = self.replies.count < postResponse.data.total
                    self.currentPage += 1
                    self.tableView.reloadData()
                    
                case .failure(let error):
                    print("Error loading replies: \(error)")
                    self.showError(message: "加载失败，请稍后重试")
                }
            }
    }
    
    // MARK: - 操作处理
    @objc private func replyButtonTapped() {
        // 检查用户是否登录
        guard User.isTokenValid() else {
            showError(message: "请先登录")
            return
        }
        
        let composeVC = UIViewController()
        setupComposeUI(for: composeVC, title: "发布评论", cancelSelector: #selector(dismissCompose), postSelector: #selector(postCompose))
    }
    
    private func deletePost(at indexPath: IndexPath) {
        let post = indexPath.section == 0 ? self.post : replies[indexPath.row]
        
        // 检查用户是否有权限删除
        guard let currentUser = User.load(),
              currentUser.uuid == post.user.uuid else {
            showError(message: "您没有权限删除此推文")
            return
        }
        
        // 显示确认对话框
        let alert = UIAlertController(title: "确认删除", message: "确定要删除这条推文吗？", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            self?.performDeletePost(post.id, at: indexPath)
        })
        
        present(alert, animated: true)
    }
    
    private func performDeletePost(_ postId: Int, at indexPath: IndexPath) {
        // 构建 URL
        let urlString = "https://gourmet.pfcent.com/api/v1/users/post/\(postId)"
        guard let url = URL(string: urlString) else {
            self.isLoading = false
            self.refreshControl.endRefreshing()
            self.loadingIndicator.stopAnimating()
            return
        }
        
        // 构建请求头
        var headers: HTTPHeaders = [
            "User-Agent": "Gourmet iOS"
        ]
        
        // 添加 token 到请求头
        if let token = UserDefaults.standard.string(forKey: UserDefaultsKeys.token) {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        // 发送请求
        AF.request(url, method: .delete, headers: headers)
            .responseDecodable(of: PostActionResponse.self) { [weak self] response in
                guard let self = self else { return }
                
                switch response.result {
                case .success(let deleteResponse):
                    if deleteResponse.success {
                        if indexPath.section == 0 {
                            // 如果删除的是主推文，返回上一页
                            self.navigationController?.popViewController(animated: true)
                        } else {
                            // 从数据源和表格视图中删除
                            self.replies.remove(at: indexPath.row)
                            self.tableView.deleteRows(at: [indexPath], with: .fade)
                        }
                    } else {
                        self.showError(message: "删除失败")
                    }
                    
                case .failure:
                    self.showError(message: "删除失败，请稍后重试")
                }
            }
    }
    
    // MARK: - 辅助方法
    private func showError(message: String) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - 帮助方法
    private func setupComposeUI(for viewController: UIViewController, title: String, 
                               cancelSelector: Selector, postSelector: Selector) {
        
        viewController.title = title
        viewController.view.backgroundColor = .white
        
        // 添加导航栏按钮
        let cancelButton = UIBarButtonItem(title: "取消", style: .plain, target: self, action: cancelSelector)
        viewController.navigationItem.leftBarButtonItem = cancelButton
        
        let postButton = UIBarButtonItem(title: "发布", style: .done, target: self, action: postSelector)
        viewController.navigationItem.rightBarButtonItem = postButton
        
        // 创建文本视图
        let textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 18)
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.tag = 100 // 用于在提交方法中找到这个视图
        textView.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.textColor = .black
        textView.backgroundColor = .white
        
        // 创建占位符标签
        let placeholderLabel = UILabel()
        placeholderLabel.text = "分享你的健康生活..."
        placeholderLabel.font = UIFont.systemFont(ofSize: 18)
        placeholderLabel.textColor = .lightGray
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.tag = 101 // 用于在文本变化时隐藏
        
        // 创建字符计数标签
        let countLabel = UILabel()
        countLabel.font = UIFont.systemFont(ofSize: 14)
        countLabel.textColor = .lightGray
        countLabel.text = "0/200"
        countLabel.textAlignment = .right
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.tag = 102 // 用于在文本变化时更新
        
        // 添加视图
        viewController.view.addSubview(textView)
        viewController.view.addSubview(placeholderLabel)
        viewController.view.addSubview(countLabel)
        
        // 设置约束
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor, constant: -16),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 200),
            textView.bottomAnchor.constraint(equalTo: countLabel.topAnchor, constant: -8),
            
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 16),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 20),
            placeholderLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor),
            
            countLabel.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor, constant: -16),
            countLabel.bottomAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
        
        // 设置文本视图代理
        textView.delegate = self
        
        // 创建导航控制器并显示
        let navController = UINavigationController(rootViewController: viewController)
        present(navController, animated: true) {
            // 在显示后自动聚焦到文本视图
            textView.becomeFirstResponder()
        }
    }
    
    @objc private func dismissCompose() {
        dismiss(animated: true)
    }
    
    @objc private func postCompose() {
        // 获取文本视图
        guard let navController = presentedViewController as? UINavigationController,
              let composeVC = navController.topViewController,
              let textView = composeVC.view.viewWithTag(100) as? UITextView else {
            return
        }
        
        // 获取文本内容
        guard let content = textView.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !content.isEmpty else {
            return
        }
        
        // 发布评论
        postReply(content: content, parentId: post.id)
        
        // 关闭编辑界面
        dismiss(animated: true)
    }
    
    private func postReply(content: String, parentId: Int) {
        // 构建请求参数
        let parameters: [String: Any] = [
            "parent_id": parentId,
            "content": content,
            "images": [""]
        ]
        
        // 构建请求头
        var headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "User-Agent": "Gourmet iOS"
        ]
        
        // 添加 token 到请求头
        if let token = UserDefaults.standard.string(forKey: UserDefaultsKeys.token) {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        // 发送请求
        AF.request("https://gourmet.pfcent.com/api/v1/users/post", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseDecodable(of: PostActionResponse.self) { [weak self] response in
                guard let self = self else { return }
                
                switch response.result {
                case .success(let postResponse):
                    if postResponse.success {
                        // 刷新数据
                        self.refreshData()
                    } else {
                        self.showError(message: "发布失败")
                    }
                    
                case .failure:
                    self.showError(message: "发布失败，请稍后重试")
                }
            }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        // 隐藏占位符标签
        if let placeholderLabel = textView.superview?.viewWithTag(101) as? UILabel {
            placeholderLabel.isHidden = !textView.text.isEmpty
        }
        
        // 更新字符计数标签
        if let countLabel = textView.superview?.viewWithTag(102) as? UILabel {
            countLabel.text = "\(textView.text.count)/200"
        }
        
        // 确保文本颜色始终为黑色
        textView.textColor = .black
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        // 确保文本颜色为黑色
        textView.textColor = .black
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        // 确保文本颜色为黑色
        textView.textColor = .black
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension PostDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : replies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostCell
        
        if indexPath.section == 0 {
            cell.configure(with: post)
        } else {
            let reply = replies[indexPath.row]
            cell.configure(with: reply)
        }
        
        cell.delegate = self
        
        // 如果接近底部，加载更多数据
        if indexPath.section == 1 && indexPath.row == replies.count - 3 && !isLoading && hasMoreData {
            loadReplies()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 1 ? "回复" : nil
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            header.textLabel?.textColor = .darkGray
        }
    }
}

// MARK: - PostCellDelegate
extension PostDetailViewController: PostCellDelegate {
    func postCell(_ cell: PostCell, didTapDeleteButton post: ParentPost) {
        if let indexPath = tableView.indexPath(for: cell) {
            deletePost(at: indexPath)
        }
    }
    
    func postCell(_ cell: PostCell, didTapReplyButton post: ParentPost) {
        // 检查用户是否登录
        guard User.isTokenValid() else {
            showError(message: "请先登录")
            return
        }
        
        // 创建一个简单的 UIAlertController 来代替 CreatePostViewController
        let alertController = UIAlertController(title: "回复推文", message: nil, preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "分享你的健康生活..."
            textField.returnKeyType = .done
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        
        let postAction = UIAlertAction(title: "发布", style: .default) { [weak self] _ in
            guard let self = self,
                  let textField = alertController.textFields?.first,
                  let content = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !content.isEmpty else {
                return
            }
            
            self.postReply(content: content, parentId: post.id)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(postAction)
        
        present(alertController, animated: true)
    }
}
