//
//  CommunityViewController.swift
//  gourmet-ios
//
//  Created by Cascade on 2025/3/30.
//

import UIKit
import Alamofire

// MARK: - 辅助函数
func formatDate(_ dateString: String) -> String {
    if dateString == "0001-01-01T00:00:00Z" {
        return "刚刚"
    }
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    
    guard let date = dateFormatter.date(from: dateString) else {
        return "未知时间"
    }
    
    let now = Date()
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date, to: now)
    
    if let year = components.year, year > 0 {
        return "\(year)年前"
    } else if let month = components.month, month > 0 {
        return "\(month)个月前"
    } else if let day = components.day, day > 0 {
        return "\(day)天前"
    } else if let hour = components.hour, hour > 0 {
        return "\(hour)小时前"
    } else if let minute = components.minute, minute > 0 {
        return "\(minute)分钟前"
    } else {
        return "刚刚"
    }
}

// MARK: - 数据模型
struct PostImage: Codable {
    let post_id: Int
    let image_url: String
    let sort_order: Int
}

struct PostUser: Codable {
    let uuid: String
    let nickname: String
    let avatar: String
    let gender: Int
    let region: String
}

// 添加点赞响应模型
struct LikeResponse: Codable {
    let success: Bool
    let data: LikeData
    let request_id: String
}

struct LikeData: Codable {
    let dislike_count: Int
    let like_count: Int
}

struct Post: Codable {
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

struct PostListResponse: Codable {
    let success: Bool
    let data: PostListData
    let request_id: String
}

struct PostListData: Codable {
    let limit: Int
    let list: [Post]
    let page: Int
    let total: Int
}

struct PostActionResponse: Codable {
    let success: Bool
    let data: String
    let request_id: String
}

// MARK: - PostCellDelegate
protocol PostCellDelegate: AnyObject {
    func postCell(_ cell: PostCell, didTapReplyButton post: Post)
    func postCell(_ cell: PostCell, didTapDeleteButton post: Post)
    func postCell(_ cell: PostCell, didTapLikeButton post: Post)
    func showErrorMessage(_ message: String)
}

// MARK: - PostCell
class PostCell: UITableViewCell {
    
    // MARK: - 属性
    weak var delegate: PostCellDelegate?
    private var post: Post?
    
    // MARK: - UI 组件
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
        view.layer.shadowRadius = 2
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        imageView.backgroundColor = .lightGray
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.tintColor = .systemBlue
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = .darkGray
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let actionsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var likeButton: UIButton = {
        let button = createActionButton(image: "heart", title: "0")
        button.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var replyButton: UIButton = {
        let button = createActionButton(image: "bubble.right", title: "回复")
        button.addTarget(self, action: #selector(replyButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var deleteButton: UIButton = {
        let button = createActionButton(image: "trash", title: "删除")
        button.tintColor = .systemRed
        button.setTitleColor(.systemRed, for: .normal)
        button.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    // MARK: - 初始化
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.image = UIImage(systemName: "person.circle.fill")
        nameLabel.text = nil
        contentLabel.text = nil
        timeLabel.text = nil
        likeButton.setTitle("0", for: .normal)
        
        // 移除之前可能添加的顶部约束
        contentLabel.constraints.forEach { constraint in
            if constraint.firstAttribute == .top {
                contentLabel.removeConstraint(constraint)
            }
        }
    }
    
    // MARK: - UI 设置
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        contentView.addSubview(containerView)
        
        containerView.addSubview(avatarImageView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(timeLabel)
        containerView.addSubview(contentLabel)
        containerView.addSubview(actionsStackView)
        
        actionsStackView.addArrangedSubview(likeButton)
        actionsStackView.addArrangedSubview(replyButton)
        actionsStackView.addArrangedSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 28),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            avatarImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            avatarImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -8),
            
            timeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            timeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            contentLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 12),
            contentLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            contentLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            actionsStackView.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 12),
            actionsStackView.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            actionsStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            actionsStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            actionsStackView.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func createActionButton(image: String, title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: image), for: .normal)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.tintColor = .systemBlue
        button.contentHorizontalAlignment = .left
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 4)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 0)
        return button
    }
    
    // MARK: - 配置
    func configure(with post: Post) {
        self.post = post
        
        nameLabel.text = post.user.nickname
        contentLabel.text = post.content
        timeLabel.text = formatDate(post.created_at)
        likeButton.setTitle("\(post.like_count)", for: .normal)
        
        // 设置点赞按钮状态
        updateLikeButtonState(postId: post.id, likeCount: post.like_count)
        
        // 检查当前用户是否有权限删除 - 修复方式: 使用isTokenValid确保用户已登录
        if let currentUser = User.load(), currentUser.uuid == post.user.uuid {
            deleteButton.isHidden = false
        } else {
            deleteButton.isHidden = true
        }
        
        // 加载头像
        if let avatarURL = URL(string: post.user.avatar) {
            URLSession.shared.dataTask(with: avatarURL) { [weak self] data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.avatarImageView.image = image
                    }
                }
            }.resume()
        }
    }
    
    // MARK: - 辅助方法
    // MARK: - 操作处理
    @objc private func deleteButtonTapped() {
        guard let post = post else { return }
        // 检查用户是否登录
        guard User.isTokenValid() else {
            delegate?.showErrorMessage("请先登录")
            return
        }
        delegate?.postCell(self, didTapDeleteButton: post)
    }
    
    @objc private func replyButtonTapped() {
        guard let post = post else { return }
        // 检查用户是否登录
        guard User.isTokenValid() else {
            delegate?.showErrorMessage("请先登录")
            return
        }
        delegate?.postCell(self, didTapReplyButton: post)
    }
    
    @objc private func likeButtonTapped() {
        // 确保有帖子数据
        guard let post = self.post else { return }
        
        // 检查用户是否登录
        guard User.isTokenValid() else {
            delegate?.showErrorMessage("请先登录")
            return
        }
        
        // 当前点赞状态
        let isCurrentlyLiked = LikeManager.shared.isPostLiked(post.id)
        
        // 构建请求URL
        var urlComponents = URLComponents(string: "https://gourmet.pfcent.com/api/v1/community/posts/\(post.id)/like")!
        
        // 构建请求头
        var headers: HTTPHeaders = [
            "User-Agent": "Gourmet iOS"
        ]
        
        // 添加 token 到请求头
        if let token = UserDefaults.standard.string(forKey: UserDefaultsKeys.token) {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        // 发送请求
        AF.request(urlComponents.url!, method: isCurrentlyLiked ? .delete : .put, headers: headers)
            .responseDecodable(of: LikeResponse.self) { [weak self] response in
                guard let self = self, let post = self.post else { return }
                
                switch response.result {
                case .success(let likeResponse):
                    // 更新点赞状态
                    LikeManager.shared.setPostLiked(post.id, liked: !isCurrentlyLiked)
                    
                    let likeCount = likeResponse.data.like_count
                    print("点赞操作成功: postId=\(post.id), 新状态=\(!isCurrentlyLiked ? "已点赞" : "未点赞"), 点赞数=\(likeCount)")
                    
                    // 更新UI - 确保在主线程更新UI
                    DispatchQueue.main.async {
                        self.likeButton.setTitle("\(likeCount)", for: .normal)
                        if isCurrentlyLiked {
                            self.likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
                            self.likeButton.tintColor = .systemBlue
                        } else {
                            self.likeButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
                            self.likeButton.tintColor = .systemRed
                        }
                    }
                    
                case .failure(let error):
                    print("点赞操作失败: \(error)")
                    self.delegate?.showErrorMessage("点赞操作失败")
                }
            }
    }
    
    // 更新点赞按钮状态
    func updateLikeButtonState(postId: Int, likeCount: Int) {
        let isLiked = LikeManager.shared.isPostLiked(postId)
        print("更新点赞按钮状态: postId=\(postId), likeCount=\(likeCount), isLiked=\(isLiked)")
        
        if isLiked {
            // 已点赞状态 - 高亮显示
            likeButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            likeButton.tintColor = .systemRed
            likeButton.setTitleColor(.systemRed, for: .normal)
        } else {
            // 未点赞状态 - 普通显示
            likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
            likeButton.tintColor = .systemBlue
            likeButton.setTitleColor(.systemBlue, for: .normal)
        }
    }
    
    // 更新点赞数量
    func updateLikeCount(_ count: Int) {
        guard let post = post else { return }
        print("调用 updateLikeCount: postId=\(post.id), count=\(count)")
        
        // 直接设置点赞数量，不依赖于 updateLikeButtonState 方法
        likeButton.setTitle("\(count)", for: .normal)
        
        // 设置点赞按钮状态
        let isLiked = LikeManager.shared.isPostLiked(post.id)
        if isLiked {
            // 已点赞状态 - 高亮显示
            likeButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
            likeButton.tintColor = .systemRed
            likeButton.setTitleColor(.systemRed, for: .normal)
        } else {
            // 未点赞状态 - 普通显示
            likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
            likeButton.tintColor = .systemBlue
            likeButton.setTitleColor(.systemBlue, for: .normal)
        }
    }
}

class CommunityViewController: UIViewController {
    
    // MARK: - 属性
    private var posts: [Post] = []
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
    
    private lazy var createPostButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        button.tintColor = .systemBlue
        button.backgroundColor = .white
        button.layer.cornerRadius = 30
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.2
        button.addTarget(self, action: #selector(createPostButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - 生命周期方法
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置视图
        title = "社区"
        view.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        
        // 设置导航栏外观
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }
        
        setupUI()
        loadPosts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 每次页面出现时刷新数据
        refreshData()
    }
    
    // MARK: - UI 设置
    private func setupUI() {
        // 添加 TableView
        view.addSubview(tableView)
        tableView.refreshControl = refreshControl
        
        // 添加创建推文按钮
        view.addSubview(createPostButton)
        
        // 添加加载指示器
        view.addSubview(loadingIndicator)
        
        // 设置约束
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            createPostButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            createPostButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            createPostButton.widthAnchor.constraint(equalToConstant: 60),
            createPostButton.heightAnchor.constraint(equalToConstant: 60),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - 数据加载
    @objc private func refreshData() {
        // 重置页码和数据状态
        currentPage = 1
        hasMoreData = true
        
        // 清空现有数据
        posts = []
        
        // 确保获取最新的用户状态
        // 这将刷新用户令牌状态并触发相关通知
        _ = User.isTokenValid()
        
        // 加载新数据
        loadPosts()
        
        // 如果太快完成，至少让刷新动画显示一段时间
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if self?.refreshControl.isRefreshing == true {
                self?.refreshControl.endRefreshing()
            }
        }
    }
    
    private func loadPosts(postId: Int = 0) {
        guard !isLoading, hasMoreData else { return }
        
        isLoading = true
        
        if posts.isEmpty && !refreshControl.isRefreshing {
            loadingIndicator.startAnimating()
        }
        
        // 构建 URL
        var urlComponents = URLComponents(string: "https://gourmet.pfcent.com/api/v1/community/posts")!
        urlComponents.queryItems = [
            URLQueryItem(name: "page", value: "\(currentPage)"),
            URLQueryItem(name: "limit", value: "20")
        ]
        
        if postId > 0 {
            urlComponents.queryItems?.append(URLQueryItem(name: "post_id", value: "\(postId)"))
        }
        
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
        
        // 添加 token 到请求头
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
                        self.posts = postResponse.data.list
                    } else {
                        self.posts.append(contentsOf: postResponse.data.list)
                    }
                    
                    self.hasMoreData = self.posts.count < postResponse.data.total
                    self.currentPage += 1
                    
                    // 强制获取最新的用户状态并更新UI
                    _ = User.isTokenValid()
                    
                    self.tableView.reloadData()
                    
                case .failure(let error):
                    print("Error loading posts: \(error)")
                    self.showError(message: "加载失败，请稍后重试")
                }
            }
    }
    
    // MARK: - 操作处理
    @objc private func createPostButtonTapped() {
        // 检查用户是否登录
        guard User.isTokenValid() else {
            showError(message: "请先登录")
            return
        }
        
        setupComposeUI(for: UIViewController(), title: "发布推文", cancelSelector: #selector(dismissCompose), postSelector: #selector(postCompose))
    }
    
    @objc private func dismissCompose() {
        dismiss(animated: true)
    }
    
    @objc private func postCompose() {
        guard let composeVC = presentedViewController?.children.first,
              let textView = composeVC.view.viewWithTag(100) as? UITextView,
              let content = textView.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !content.isEmpty else {
            showError(message: "请输入内容")
            return
        }
        
        // 检查内容长度
        guard content.count <= 200 else {
            showError(message: "内容不能超过200个字符")
            return
        }
        
        // 先关闭编辑界面，再发布评论
        dismiss(animated: true) { [weak self] in
            self?.postTweet(content: content)
        }
    }
    
    @objc private func postReplyCompose() {
        guard let composeVC = presentedViewController?.children.first,
              let textView = composeVC.view.viewWithTag(100) as? UITextView,
              let content = textView.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !content.isEmpty else {
            showError(message: "请输入内容")
            return
        }
        
        // 检查内容长度
        guard content.count <= 200 else {
            showError(message: "内容不能超过200个字符")
            return
        }
        
        // 获取父推文 ID
        let parentId = composeVC.view.tag
        
        // 发布回复
        postTweet(content: content, parentId: parentId)
        
        // 关闭编辑界面
        dismiss(animated: true)
    }
    
    private func postTweet(content: String, parentId: Int = 0) {
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
                    
                case .failure(let error):
                    print("Error posting tweet: \(error)")
                    self.showError(message: "发布失败，请稍后重试")
                }
            }
    }
    
    private func deletePost(at indexPath: IndexPath) {
        // 安全检查，确保索引有效
        guard indexPath.row < posts.count else {
            return
        }
        
        let post = posts[indexPath.row]
        
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
            showError(message: "无效的 URL")
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
                case .success(let postResponse):
                    if postResponse.success {
                        // 从数据源和表格视图中删除
                        self.posts.remove(at: indexPath.row)
                        self.tableView.deleteRows(at: [indexPath], with: .fade)
                    } else {
                        self.showError(message: "删除失败")
                    }
                    
                case .failure(let error):
                    print("Error deleting post: \(error)")
                    self.showError(message: "删除失败，请稍后重试")
                }
            }
    }
    
    // MARK: - 帮助方法
    private func setupComposeUI(for viewController: UIViewController, title: String, 
                               cancelSelector: Selector, postSelector: Selector, 
                               showReplyInfo: Bool = false, replyInfoText: String = "", 
                               postId: Int = 0) {
        
        viewController.title = title
        viewController.view.backgroundColor = .white
        
        // 添加导航栏按钮
        let cancelButton = UIBarButtonItem(title: "取消", style: .plain, target: self, action: cancelSelector)
        viewController.navigationItem.leftBarButtonItem = cancelButton
        
        let postButton = UIBarButtonItem(title: "发布", style: .done, target: self, action: postSelector)
        viewController.navigationItem.rightBarButtonItem = postButton
        
        // 添加回复提示信息（如果需要）
        var topAnchor: NSLayoutYAxisAnchor = viewController.view.safeAreaLayoutGuide.topAnchor
        var topConstant: CGFloat = 0
        
        if showReplyInfo {
            let replyInfoLabel = UILabel()
            replyInfoLabel.text = replyInfoText
            replyInfoLabel.font = UIFont.systemFont(ofSize: 14)
            replyInfoLabel.textColor = .darkGray
            replyInfoLabel.translatesAutoresizingMaskIntoConstraints = false
            viewController.view.addSubview(replyInfoLabel)
            
            NSLayoutConstraint.activate([
                replyInfoLabel.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor, constant: 16),
                replyInfoLabel.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor, constant: 16),
                replyInfoLabel.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor, constant: -16)
            ])
            
            topAnchor = replyInfoLabel.bottomAnchor
            topConstant = 16
        }
        
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
        
        // 存储父推文 ID (如果有)
        if postId > 0 {
            viewController.view.tag = postId
        }
        
        // 设置约束
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: topAnchor, constant: topConstant),
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
    
    private func showError(message: String) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    private func showPostDetail(_ post: Post) {
        // 创建一个新的详情页面视图控制器
        let detailVC = DetailPostViewController(post: post)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension CommunityViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostCell
        
        // 安全检查，确保索引有效
        guard indexPath.row < posts.count else {
            return cell
        }
        
        let post = posts[indexPath.row]
        
        cell.configure(with: post)
        cell.delegate = self
        
        // 如果接近底部，加载更多数据
        if indexPath.row == posts.count - 3 && !isLoading && hasMoreData {
            loadPosts()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 安全检查，确保索引有效
        guard indexPath.row < posts.count else {
            return
        }
        
        let post = posts[indexPath.row]
        
        showPostDetail(post)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
}

// MARK: - PostCellDelegate
extension CommunityViewController: PostCellDelegate {
    func postCell(_ cell: PostCell, didTapDeleteButton post: Post) {
        if let indexPath = tableView.indexPath(for: cell) {
            deletePost(at: indexPath)
        }
    }
    
    func postCell(_ cell: PostCell, didTapReplyButton post: Post) {
        // 检查用户是否登录
        guard User.isTokenValid() else {
            showError(message: "请先登录")
            return
        }
        
        setupComposeUI(for: UIViewController(), title: "回复推文", cancelSelector: #selector(dismissCompose), postSelector: #selector(postReplyCompose), showReplyInfo: true, replyInfoText: "正在回复推文...", postId: post.id)
    }
    
    func postCell(_ cell: PostCell, didTapLikeButton post: Post) {
        // 检查用户是否登录
        guard User.isTokenValid() else {
            showError(message: "请先登录")
            return
        }
        
        // 获取当前点赞状态
        let isCurrentlyLiked = LikeManager.shared.isPostLiked(post.id)
        let action = isCurrentlyLiked ? 3 : 1 // 1: 点赞, 3: 取消点赞
        
        print("点击点赞按钮: postId=\(post.id), 当前状态=\(isCurrentlyLiked ? "已点赞" : "未点赞"), 操作=\(action)")
        
        // 调用点赞/取消点赞接口
        toggleLikePost(postId: post.id, action: action) { [weak self, post, weak cell] result in
            switch result {
            case .success(let likeCount):
                // 更新点赞状态
                LikeManager.shared.setPostLiked(post.id, liked: !isCurrentlyLiked)
                
                print("点赞操作成功: postId=\(post.id), 新状态=\(!isCurrentlyLiked ? "已点赞" : "未点赞"), 点赞数=\(likeCount)")
                
                // 更新UI - 确保在主线程更新UI
                DispatchQueue.main.async {
                    cell?.updateLikeCount(likeCount)
                    print("UI更新完成: 点赞数=\(likeCount)")
                }
                
            case .failure(let error):
                print("点赞操作失败: \(error)")
                self?.showError(message: "操作失败: \(error.localizedDescription)")
            }
        }
    }
    
    func showErrorMessage(_ message: String) {
        showError(message: message)
    }
    
    // 点赞/取消点赞请求方法
    private func toggleLikePost(postId: Int, action: Int, completion: @escaping (Result<Int, Error>) -> Void) {
        print("发送点赞请求: postId=\(postId), action=\(action)")
        
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
        AF.request("https://gourmet.pfcent.com/api/v1/users/post/favorite/\(postId)/\(action)", 
                   method: .put, 
                   headers: headers)
            .responseDecodable(of: LikeResponse.self) { [weak self] response in
                guard let self = self else { return }
                
                switch response.result {
                case .success(let likeResponse):
                    print("点赞响应: success=\(likeResponse.success), likeCount=\(likeResponse.data.like_count)")
                    if likeResponse.success {
                        completion(.success(likeResponse.data.like_count))
                    } else {
                        completion(.failure(NSError(domain: "LikeError", code: 0, userInfo: [NSLocalizedDescriptionKey: "操作失败"])))
                    }
                    
                case .failure(let error):
                    print("点赞请求失败: \(error)")
                    completion(.failure(error))
                }
            }
    }
}

extension CommunityViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        // 更新字符计数标签
        if let countLabel = textView.superview?.viewWithTag(102) as? UILabel {
            countLabel.text = "\(textView.text.count)/200"
        }
        
        // 隐藏或显示占位符标签
        if let placeholderLabel = textView.superview?.viewWithTag(101) as? UILabel {
            placeholderLabel.isHidden = !textView.text.isEmpty
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

// MARK: - 点赞状态管理
class LikeManager {
    static let shared = LikeManager()
    
    private let likedPostsKey = "LikedPosts"
    private var likedPosts: Set<Int> = []
    
    private init() {
        loadLikedPosts()
    }
    
    // 加载已点赞的帖子ID
    private func loadLikedPosts() {
        if let likedPostsArray = UserDefaults.standard.array(forKey: likedPostsKey) as? [Int] {
            likedPosts = Set(likedPostsArray)
        }
    }
    
    // 保存已点赞的帖子ID
    private func saveLikedPosts() {
        UserDefaults.standard.set(Array(likedPosts), forKey: likedPostsKey)
    }
    
    // 检查帖子是否已点赞
    func isPostLiked(_ postId: Int) -> Bool {
        return likedPosts.contains(postId)
    }
    
    // 设置帖子点赞状态
    func setPostLiked(_ postId: Int, liked: Bool) {
        if liked {
            likedPosts.insert(postId)
        } else {
            likedPosts.remove(postId)
        }
        saveLikedPosts()
    }
    
    // 切换帖子点赞状态
    func togglePostLiked(_ postId: Int) -> Bool {
        let isLiked = isPostLiked(postId)
        setPostLiked(postId, liked: !isLiked)
        return !isLiked
    }
}

// 更新 DetailPostViewController 实现
class DetailPostViewController: UIViewController {
    
    // MARK: - 属性
    private let post: Post
    private var comments: [Post] = []
    private var isLoadingComments = false
    private var currentPage = 1
    private var hasMoreComments = true
    
    // MARK: - UI 组件
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 25
        imageView.backgroundColor = .lightGray
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.tintColor = .systemBlue
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .darkGray
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var actionsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var replyButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("回复", for: .normal)
        button.setImage(UIImage(systemName: "arrowshape.turn.up.left"), for: .normal)
        button.tintColor = .systemBlue
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(replyButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("点赞", for: .normal)
        button.setImage(UIImage(systemName: "hand.thumbsup"), for: .normal)
        button.tintColor = .systemBlue
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(likeButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("删除", for: .normal)
        button.setImage(UIImage(systemName: "trash"), for: .normal)
        button.tintColor = .systemRed
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private let commentsHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "评论"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.register(PostCell.self, forCellReuseIdentifier: "PostCell")
        tableView.isScrollEnabled = false // 防止嵌套滚动问题
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    private lazy var composeView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: -2)
        view.layer.shadowRadius = 3
        view.layer.shadowOpacity = 0.1
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var composeTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "写评论..."
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.borderStyle = .roundedRect
        textField.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        textField.returnKeyType = .send
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - 初始化
    init(post: Post) {
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
        
        // 设置导航栏外观
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }
        
        // 确保内容不被导航栏遮挡
        edgesForExtendedLayout = []
        
        // 注册键盘通知
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        setupUI()
        
        // 添加点击手势关闭键盘
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 重新加载评论，以防有新评论
        loadComments()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 确保键盘隐藏
        view.endEditing(true)
    }
    
    deinit {
        // 移除键盘通知
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - 键盘处理
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        let keyboardHeight = keyboardFrame.height
        
        // 更新底部输入框约束
        UIView.animate(withDuration: 0.3) {
            self.composeView.transform = CGAffineTransform(translationX: 0, y: -keyboardHeight)
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        // 恢复底部输入框位置
        UIView.animate(withDuration: 0.3) {
            self.composeView.transform = .identity
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // MARK: - UI 设置
    private func setupUI() {
        // 添加视图
        view.addSubview(scrollView)
        scrollView.addSubview(containerView)
        containerView.addSubview(cardView)
        
        cardView.addSubview(avatarImageView)
        cardView.addSubview(nameLabel)
        cardView.addSubview(timeLabel)
        cardView.addSubview(contentLabel)
        
        // 添加动作按钮 - 只包含点赞和删除按钮，移除回复按钮
        actionsStackView.addArrangedSubview(likeButton)
        
        // 只有当用户是自己时才显示删除按钮
        if let currentUser = User.load(), currentUser.uuid == post.user.uuid {
            actionsStackView.addArrangedSubview(deleteButton)
        }
        
        cardView.addSubview(actionsStackView)
        
        // 添加评论列表
        containerView.addSubview(commentsHeaderLabel)
        containerView.addSubview(tableView)
        containerView.addSubview(loadingIndicator)
        
        // 添加评论输入框
        view.addSubview(composeView)
        composeView.addSubview(composeTextField)
        
        // 设置约束
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 28),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: composeView.topAnchor),
            
            containerView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            containerView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            cardView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            cardView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            avatarImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            avatarImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            avatarImageView.widthAnchor.constraint(equalToConstant: 50),
            avatarImageView.heightAnchor.constraint(equalToConstant: 50),
            
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            
            timeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            timeLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            
            contentLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 16),
            contentLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            contentLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            
            actionsStackView.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 16),
            actionsStackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            actionsStackView.trailingAnchor.constraint(lessThanOrEqualTo: cardView.trailingAnchor, constant: -16),
            actionsStackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
            actionsStackView.heightAnchor.constraint(equalToConstant: 44),
            
            // 评论标题
            commentsHeaderLabel.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 24),
            commentsHeaderLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            commentsHeaderLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // 评论列表
            tableView.topAnchor.constraint(equalTo: commentsHeaderLabel.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // 加载指示器
            loadingIndicator.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: tableView.centerYAnchor, constant: 100),
            
            // 评论输入框
            composeView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            composeView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            composeView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            composeView.heightAnchor.constraint(equalToConstant: 60),
            
            composeTextField.leadingAnchor.constraint(equalTo: composeView.leadingAnchor, constant: 16),
            composeTextField.trailingAnchor.constraint(equalTo: composeView.trailingAnchor, constant: -16),
            composeTextField.centerYAnchor.constraint(equalTo: composeView.centerYAnchor),
            composeTextField.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // 配置视图内容
        nameLabel.text = post.user.nickname
        timeLabel.text = formatDate(post.created_at)
        contentLabel.text = post.content
        
        // 更新点赞按钮状态
        updateLikeButtonState()
        
        // 加载头像
        if let avatarURL = URL(string: post.user.avatar) {
            URLSession.shared.dataTask(with: avatarURL) { [weak self] data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.avatarImageView.image = image
                    }
                }
            }.resume()
        }
        
        // 加载评论列表
        loadComments()
    }
    
    // 更新点赞按钮状态
    private func updateLikeButtonState(likeCount: Int? = nil) {
        let isLiked = LikeManager.shared.isPostLiked(post.id)
        let displayLikeCount = likeCount ?? post.like_count
        
        if isLiked {
            likeButton.setTitle("已点赞(\(displayLikeCount))", for: .normal)
            likeButton.setImage(UIImage(systemName: "hand.thumbsup.fill"), for: .normal)
            likeButton.tintColor = .systemBlue
        } else {
            likeButton.setTitle("点赞(\(displayLikeCount))", for: .normal)
            likeButton.setImage(UIImage(systemName: "hand.thumbsup"), for: .normal)
            likeButton.tintColor = .systemBlue
        }
    }
    
    // MARK: - 操作处理
    @objc private func replyButtonTapped() {
        // 检查用户是否登录
        guard User.isTokenValid() else {
            showError(message: "请先登录")
            return
        }
        
        // 简单提示
        let alert = UIAlertController(title: "提示", message: "回复功能正在开发中", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func likeButtonTapped() {
        // 检查用户是否登录
        guard User.isTokenValid() else {
            showError(message: "请先登录")
            return
        }
        
        // 获取当前点赞状态
        let isCurrentlyLiked = LikeManager.shared.isPostLiked(post.id)
        let action = isCurrentlyLiked ? 3 : 1 // 1: 点赞, 3: 取消点赞
        
        // 先临时更新UI，给用户立即反馈
        var updatedLikeCount = post.like_count
        if isCurrentlyLiked {
            updatedLikeCount = max(0, updatedLikeCount - 1)
        } else {
            updatedLikeCount += 1
        }
        
        // 调用点赞/取消点赞接口
        toggleLikePost(postId: post.id, action: action) { [weak self, post] result in
            switch result {
            case .success(let likeCount):
                // 更新点赞状态
                LikeManager.shared.setPostLiked(self?.post.id ?? 0, liked: !isCurrentlyLiked)
                
                // 更新UI - 确保在主线程更新UI
                DispatchQueue.main.async {
                    if let strongSelf = self {
                        // 更新帖子的点赞数
                        strongSelf.updateLikeButtonState(likeCount: likeCount)
                    }
                }
                
            case .failure(let error):
                print("点赞操作失败: \(error)")
                // 操作失败，恢复原始点赞状态
                DispatchQueue.main.async {
                    if let strongSelf = self {
                        strongSelf.updateLikeButtonState()
                        strongSelf.showError(message: "操作失败，请稍后重试")
                    }
                }
            }
        }
    }
    
    @objc private func deleteButtonTapped() {
        // 检查用户是否登录
        guard User.isTokenValid() else {
            showError(message: "请先登录")
            return
        }
        // 显示确认对话框
        let alert = UIAlertController(title: "确认删除", message: "确定要删除这条推文吗？", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            // 这里添加删除功能 - 简单提示
            let alert = UIAlertController(title: "提示", message: "删除成功", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
                // 返回上一页
                self?.navigationController?.popViewController(animated: true)
            })
            self?.present(alert, animated: true)
        })
        
        present(alert, animated: true)
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    // 点赞/取消点赞请求方法
    private func toggleLikePost(postId: Int, action: Int, completion: @escaping (Result<Int, Error>) -> Void) {
        print("发送点赞请求: postId=\(postId), action=\(action)")
        
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
        AF.request("https://gourmet.pfcent.com/api/v1/users/post/favorite/\(postId)/\(action)", 
                   method: .put, 
                   headers: headers)
            .responseDecodable(of: LikeResponse.self) { [weak self] response in
                switch response.result {
                case .success(let likeResponse):
                    print("点赞响应: success=\(likeResponse.success), likeCount=\(likeResponse.data.like_count)")
                    if likeResponse.success {
                        completion(.success(likeResponse.data.like_count))
                    } else {
                        completion(.failure(NSError(domain: "API", code: 400, userInfo: [NSLocalizedDescriptionKey: "操作失败"])))
                    }
                    
                case .failure(let error):
                    print("点赞请求失败: \(error)")
                    completion(.failure(error))
                }
            }
    }
    
    // MARK: - 加载评论列表
    private func loadComments() {
        guard !isLoadingComments, hasMoreComments else { return }
        
        isLoadingComments = true
        loadingIndicator.startAnimating()
        
        // 构建 URL
        var urlComponents = URLComponents(string: "https://gourmet.pfcent.com/api/v1/community/posts")!
        urlComponents.queryItems = [
            URLQueryItem(name: "post_id", value: "\(post.id)"),
            URLQueryItem(name: "page", value: "\(currentPage)"),
            URLQueryItem(name: "limit", value: "20")
        ]
        
        guard let url = urlComponents.url else {
            isLoadingComments = false
            loadingIndicator.stopAnimating()
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
        AF.request(url, method: .get, headers: headers)
            .responseDecodable(of: PostListResponse.self) { [weak self] response in
                guard let self = self else { return }
                
                self.isLoadingComments = false
                self.loadingIndicator.stopAnimating()
                
                switch response.result {
                case .success(let postResponse):
                    if self.currentPage == 1 {
                        self.comments = postResponse.data.list
                    } else {
                        self.comments.append(contentsOf: postResponse.data.list)
                    }
                    
                    self.hasMoreComments = self.comments.count < postResponse.data.total
                    self.currentPage += 1
                    self.tableView.reloadData()
                    
                    // 更新评论数量显示
                    self.commentsHeaderLabel.text = "评论 (\(postResponse.data.total))"
                    
                    // 更新表格高度
                    DispatchQueue.main.async {
                        self.updateTableViewHeight()
                    }
                    
                case .failure(let error):
                    print("Error loading comments: \(error)")
                    self.showError(message: "加载失败，请稍后重试")
                }
            }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // 更新tableView高度 - 自动适应内容
        updateTableViewHeight()
    }
    
    private func updateTableViewHeight() {
        // 计算并更新tableView的高度
        tableView.layoutIfNeeded()
        
        var tableHeight: CGFloat = 0
        if comments.isEmpty {
            // 如果没有评论，显示一个空状态
            tableHeight = 100
        } else {
            // 手动计算表格高度
            for i in 0..<tableView.numberOfRows(inSection: 0) {
                tableHeight += tableView.rectForRow(at: IndexPath(row: i, section: 0)).height
            }
            // 确保高度至少为100
            tableHeight = max(100, tableHeight)
        }
        
        // 更新tableView高度约束
        let heightConstraint = tableView.constraints.first { $0.firstAttribute == .height }
        if let constraint = heightConstraint {
            constraint.constant = tableHeight
        } else {
            tableView.heightAnchor.constraint(equalToConstant: tableHeight).isActive = true
        }
        
        // 重新计算scrollView内容大小
        view.layoutIfNeeded()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension DetailPostViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostCell
        let comment = comments[indexPath.row]
        
        cell.configure(with: comment)
        cell.delegate = self
        
        // 如果接近底部，加载更多数据
        if indexPath.row == comments.count - 3 && !isLoadingComments && hasMoreComments {
            loadComments()
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // 移除点击评论的功能
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
}

// MARK: - PostCellDelegate
extension DetailPostViewController: PostCellDelegate {
    func postCell(_ cell: PostCell, didTapDeleteButton post: Post) {
        // 检查用户是否登录
        guard User.isTokenValid() else {
            showError(message: "请先登录")
            return
        }
        
        // 显示确认对话框
        let alert = UIAlertController(title: "确认删除", message: "确定要删除这条评论吗？", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            // 这里添加删除功能 - 简单提示
            let alert = UIAlertController(title: "提示", message: "删除成功", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default) { _ in
                // 返回上一页
                self?.navigationController?.popViewController(animated: true)
            })
            self?.present(alert, animated: true)
        })
        
        present(alert, animated: true)
    }
    
    func postCell(_ cell: PostCell, didTapReplyButton post: Post) {
        // 检查用户是否登录
        guard User.isTokenValid() else {
            showError(message: "请先登录")
            return
        }
        
        // 简单提示
        let alert = UIAlertController(title: "提示", message: "回复功能正在开发中", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    func postCell(_ cell: PostCell, didTapLikeButton post: Post) {
        // 检查用户是否登录
        guard User.isTokenValid() else {
            showError(message: "请先登录")
            return
        }
        
        // 获取当前点赞状态
        let isCurrentlyLiked = LikeManager.shared.isPostLiked(post.id)
        let action = isCurrentlyLiked ? 3 : 1 // 1: 点赞, 3: 取消点赞
        
        print("点击点赞按钮: postId=\(post.id), 当前状态=\(isCurrentlyLiked ? "已点赞" : "未点赞"), 操作=\(action)")
        
        // 调用点赞/取消点赞接口
        toggleLikePost(postId: post.id, action: action) { [weak self, post, weak cell] result in
            switch result {
            case .success(let likeCount):
                // 更新点赞状态
                LikeManager.shared.setPostLiked(self?.post.id ?? 0, liked: !isCurrentlyLiked)
                
                // 更新UI - 确保在主线程更新UI
                DispatchQueue.main.async {
                    cell?.updateLikeCount(likeCount)
                    print("UI更新完成: 点赞数=\(likeCount)")
                }
                
            case .failure(let error):
                print("点赞操作失败: \(error)")
                self?.showError(message: "操作失败: \(error.localizedDescription)")
            }
        }
    }
    
    func showErrorMessage(_ message: String) {
        showError(message: message)
    }
}

extension DetailPostViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // 发送评论
        guard let content = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !content.isEmpty else {
            return false
        }
        
        // 检查内容长度
        guard content.count <= 200 else {
            showError(message: "内容不能超过200个字符")
            return false
        }
        
        // 发送评论请求
        postComment(content: content)
        
        // 清空输入框
        textField.text = ""
        
        return true
    }
    
    private func postComment(content: String) {
        // 显示加载指示器
        loadingIndicator.startAnimating()
        
        // 构建请求参数
        let parameters: [String: Any] = [
            "parent_id": post.id,
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
                
                // 停止加载指示器
                self.loadingIndicator.stopAnimating()
                
                switch response.result {
                case .success(let postResponse):
                    if postResponse.success {
                        // 重置评论页码，重新加载评论列表
                        self.currentPage = 1
                        self.hasMoreComments = true
                        self.comments = []
                        self.loadComments()
                        
                        // 恢复输入框状态
                        self.composeTextField.placeholder = "写评论..."
                    } else {
                        self.showError(message: "发布失败")
                    }
                    
                case .failure(let error):
                    print("Error posting comment: \(error)")
                    self.showError(message: "发布失败，请稍后重试")
                }
            }
    }
}
