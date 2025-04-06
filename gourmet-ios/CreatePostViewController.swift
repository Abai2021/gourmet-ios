//
//  CreatePostViewController.swift
//  gourmet-ios
//
//  Created by Cascade on 2025/4/4.
//

import UIKit
import Alamofire

// 确保 Post 和 ParentPost 结构体在这里也可见
struct PostReference {
    let id: Int
    let parent_id: Int
    let content: String
    let user: PostUser
}

// MARK: - 代理协议
protocol CreatePostViewControllerDelegate: AnyObject {
    func didCreatePost()
}

class CreatePostViewController: UIViewController {
    
    // MARK: - 属性
    weak var delegate: CreatePostViewControllerDelegate?
    private var parentPost: PostReference?
    private var isPosting = false
    
    // MARK: - UI 组件
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .clear
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let parentPostView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        view.layer.cornerRadius = 12
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let parentPostLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let textView: UITextView = {
         let textView = UITextView()
        textView.textColor = UIColor.black
        textView.backgroundColor = UIColor.white
        textView.font = UIFont.systemFont(ofSize: 18)
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        // textContainer.addSubview(textView)
        textView.textColor = .black // 添加文本颜色
        textView.backgroundColor = .white // 设置背景色
        return textView
    }()
    
    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "分享你的健康生活..."
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .lightGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let characterCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .lightGray
        label.text = "0/200"
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var postButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("发布", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(postButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - 初始化
    init(parentPost: PostReference? = nil) {
        self.parentPost = parentPost
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 生命周期方法
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置视图
        title = parentPost == nil ? "发布推文" : "回复推文"
        view.backgroundColor = .white
        
        setupUI()
        setupKeyboardObservers()
        
        // 如果有父推文，显示父推文内容
        if let parentPost = parentPost {
            parentPostView.isHidden = false
            parentPostLabel.text = "@\(parentPost.user.nickname): \(parentPost.content)"
        }
        
        // 添加导航栏右侧按钮
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "发布", style: .done, target: self, action: #selector(postButtonTapped))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textView.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        textView.resignFirstResponder()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - UI 设置
    private func setupUI() {
        // 设置导航栏
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(cancelButtonTapped))
        
        // 添加视图
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(parentPostView)
        parentPostView.addSubview(parentPostLabel)
        
        contentView.addSubview(textView)
        // textView.addSubview(placeholderLabel)
        contentView.addSubview(characterCountLabel)
        contentView.addSubview(postButton)
        postButton.addSubview(loadingIndicator)
        
        // 设置约束
        let contentViewHeightConstraint = contentView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        contentViewHeightConstraint.priority = .defaultLow
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            contentViewHeightConstraint,
            
            parentPostView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            parentPostView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            parentPostView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            parentPostLabel.topAnchor.constraint(equalTo: parentPostView.topAnchor, constant: 12),
            parentPostLabel.leadingAnchor.constraint(equalTo: parentPostView.leadingAnchor, constant: 12),
            parentPostLabel.trailingAnchor.constraint(equalTo: parentPostView.trailingAnchor, constant: -12),
            parentPostLabel.bottomAnchor.constraint(equalTo: parentPostView.bottomAnchor, constant: -12),
            
            textView.topAnchor.constraint(equalTo: parentPostView.isHidden ? contentView.topAnchor : parentPostView.bottomAnchor, constant: 16),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 150),
            
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 12),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 8),
            placeholderLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor, constant: -8),
            
            characterCountLabel.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 8),
            characterCountLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            postButton.topAnchor.constraint(equalTo: characterCountLabel.bottomAnchor, constant: 16),
            postButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            postButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            postButton.heightAnchor.constraint(equalToConstant: 50),
            postButton.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: postButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: postButton.centerYAnchor)
        ])
        
        // 设置文本视图代理
        textView.delegate = self
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - 键盘处理
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            scrollView.contentInset.bottom = keyboardSize.height
            scrollView.verticalScrollIndicatorInsets.bottom = keyboardSize.height
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
    
    // MARK: - 操作处理
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func postButtonTapped() {
        // 检查内容是否为空
        guard let content = textView.text?.trimmingCharacters(in: .whitespacesAndNewlines), !content.isEmpty else {
            showError(message: "请输入内容")
            return
        }
        
        // 检查内容长度
        guard content.count <= 200 else {
            showError(message: "内容不能超过200个字符")
            return
        }
        
        // 检查是否已经在发布中
        guard !isPosting else { return }
        
        isPosting = true
        loadingIndicator.startAnimating()
        postButton.setTitle("", for: .normal)
        
        // 构建请求参数
        let parameters: [String: Any] = [
            "parent_id": parentPost?.id ?? 0,
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
                
                self.isPosting = false
                self.loadingIndicator.stopAnimating()
                self.postButton.setTitle("发布", for: .normal)
                
                switch response.result {
                case .success(let postResponse):
                    if postResponse.success {
                        // 通知代理发布成功
                        self.delegate?.didCreatePost()
                        self.dismiss(animated: true)
                    } else {
                        self.showError(message: "发布失败")
                    }
                    
                case .failure:
                    self.showError(message: "发布失败，请稍后重试")
                }
            }
    }
    
    // MARK: - 辅助方法
    private func showError(message: String) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextViewDelegate
extension CreatePostViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
        
        let count = textView.text.count
        characterCountLabel.text = "\(count)/200"
        
        if count > 200 {
            characterCountLabel.textColor = .systemRed
        } else {
            characterCountLabel.textColor = .lightGray
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.textColor = .black
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        textView.textColor = .black
    }
}
