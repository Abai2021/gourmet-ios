//
//  SideMenuViewController.swift
//  gourmet-ios
//
//  Created by Cascade on 2025/3/30.
//

import UIKit
import AuthenticationServices
import Alamofire
import SwiftyJSON

// 用户默认值键
struct UserDefaultsKeys {
    static let user = "com.gourmet.user"
    static let token = "com.gourmet.user.token"
    static let tokenExpiry = "com.gourmet.user.token.expiry"
}

// 用户模型
struct User: Codable {
    var id: Int
    var nickname: String
    var avatar: String?
    var email: String?
    var gender: Int
    var region: String?
    var uuid: String?
    
    // 为了兼容性，添加一些计算属性
    var name: String { return nickname }
    
    static var current: User?
    
    // 保存用户到 UserDefaults
    func save() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self) {
            UserDefaults.standard.set(encoded, forKey: UserDefaultsKeys.user)
        }
    }
    
    // 从 UserDefaults 加载用户
    static func load() -> User? {
        if let userData = UserDefaults.standard.data(forKey: UserDefaultsKeys.user) {
            let decoder = JSONDecoder()
            if let user = try? decoder.decode(User.self, from: userData) {
                User.current = user
                return user
            }
        }
        return nil
    }
    
    // 清除用户信息
    static func logout() {
        User.current = nil
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.user)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.token)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.tokenExpiry)
    }
    
    // 检查 token 是否有效
    static func isTokenValid() -> Bool {
        guard let tokenExpiryString = UserDefaults.standard.string(forKey: UserDefaultsKeys.tokenExpiry),
              let token = UserDefaults.standard.string(forKey: UserDefaultsKeys.token),
              !token.isEmpty else {
            return false
        }
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let expiryDate = dateFormatter.date(from: tokenExpiryString) else {
            return false
        }
        
        return expiryDate > Date()
    }
}

// 错误响应模型
struct ErrorResponse: Codable {
    let success: Bool
    let message: String
    let status_code: Int
    let request_id: String
}

// 登录响应模型
struct LoginResponse: Codable {
    let success: Bool
    let data: LoginData
    let request_id: String
    
    struct LoginData: Codable {
        let access_token: String
        let avatar: String
        let email: String
        let expired_at: String
        let gender: Int
        let id: Int
        let nickname: String
        let provider: String
        let region: String
    }
}

// 用户信息响应模型
struct UserInfoResponse: Codable {
    let success: Bool
    let data: UserData
    let request_id: String
    
    struct UserData: Codable {
        let uuid: String
        let nickname: String
        let avatar: String
        let gender: Int
        let region: String
    }
}

// 简化的登录服务
class LoginService {
    // API 常量
    private struct API {
        static let baseURL = "https://gourmet.pfcent.com"
        static let login = baseURL + "/api/v1/auths/apple"
        static let userInfo = baseURL + "/api/v1/users"
    }
    
    // 登录方法
    static func login(withAuthCode authCode: String, completion: @escaping (User?, Error?) -> Void) {
        let parameters: [String: Any] = [
            "authorization_code": authCode,
            "device_id": UIDevice.current.identifierForVendor?.uuidString ?? ""
        ]
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
//            "User-Agent": "Gourmet iOS",
            "X-BUNDLE-ID": "com.abai.test"
        ]
        
        AF.request(API.login, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    // 尝试解析成功响应
                    if let loginResponse = try? JSONDecoder().decode(LoginResponse.self, from: data),
                       loginResponse.success {
                        // 成功响应
                        let userData = loginResponse.data
                        
                        // 保存 token 和过期时间
                        UserDefaults.standard.set(userData.access_token, forKey: UserDefaultsKeys.token)
                        UserDefaults.standard.set(userData.expired_at, forKey: UserDefaultsKeys.tokenExpiry)
                        
                        // 创建用户对象
                        let user = User(
                            id: 0,
                            nickname: userData.nickname,
                            avatar: userData.avatar.isEmpty ? nil : userData.avatar,
                            email: nil,
                            gender: userData.gender,
                            region: userData.region.isEmpty ? nil : userData.region,
                            uuid: nil
                        )
                        
                        // 保存当前用户
                        User.current = user
                        user.save()
                        
                        completion(user, nil)
                    } else {
                        // 尝试解析错误响应
                        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                            let error = NSError(
                                domain: "com.gourmet.error",
                                code: errorResponse.status_code,
                                userInfo: [
                                    NSLocalizedDescriptionKey: errorResponse.message,
                                    "request_id": errorResponse.request_id
                                ]
                            )
                            completion(nil, error)
                        } else {
                            // 无法解析响应
                            let error = NSError(
                                domain: "com.gourmet.error",
                                code: 0,
                                userInfo: [NSLocalizedDescriptionKey: "无法解析服务器响应"]
                            )
                            completion(nil, error)
                        }
                    }
                    
                case .failure(let error):
                    completion(nil, error)
                }
            }
    }
    
    // 获取用户信息
    static func getUserInfo(completion: @escaping (User?, Error?) -> Void) {
        guard let token = UserDefaults.standard.string(forKey: UserDefaultsKeys.token) else {
            let error = NSError(domain: "com.gourmet.error", code: 401, userInfo: [NSLocalizedDescriptionKey: "未登录"])
            completion(nil, error)
            return
        }
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(token)",
            "User-Agent": "Gourmet iOS",
            "Accept": "*/*",
            "Connection": "keep-alive"
        ]
        
        AF.request(API.userInfo, method: .get, headers: headers)
            .validate()
            .responseData { response in
                switch response.result {
                case .success(let data):
                    // 尝试解析成功响应
                    if let userInfoResponse = try? JSONDecoder().decode(UserInfoResponse.self, from: data),
                       userInfoResponse.success {
                        // 成功响应
                        let userData = userInfoResponse.data
                        
                        // 创建用户对象
                        let user = User(
                            id: 0,
                            nickname: userData.nickname,
                            avatar: userData.avatar.isEmpty ? nil : userData.avatar,
                            email: nil,
                            gender: userData.gender,
                            region: userData.region.isEmpty ? nil : userData.region,
                            uuid: userData.uuid
                        )
                        
                        // 保存当前用户
                        User.current = user
                        user.save()
                        
                        completion(user, nil)
                    } else {
                        // 尝试解析错误响应
                        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                            let error = NSError(
                                domain: "com.gourmet.error",
                                code: errorResponse.status_code,
                                userInfo: [
                                    NSLocalizedDescriptionKey: errorResponse.message,
                                    "request_id": errorResponse.request_id
                                ]
                            )
                            completion(nil, error)
                        } else {
                            // 无法解析响应
                            let error = NSError(
                                domain: "com.gourmet.error",
                                code: 0,
                                userInfo: [NSLocalizedDescriptionKey: "无法解析服务器响应"]
                            )
                            completion(nil, error)
                        }
                    }
                    
                case .failure(let error):
                    // 检查是否是 401 错误
                    if let afError = error.asAFError,
                       let response = afError.responseCode,
                       response == 401 {
                        // 401 错误，提示用户重新登录
                        User.logout()
                        
                        let error = NSError(domain: "com.gourmet.error", code: 401, userInfo: [NSLocalizedDescriptionKey: "登录已过期，请重新登录"])
                        completion(nil, error)
                    } else {
                        completion(nil, error)
                    }
                }
            }
    }
}

protocol SideMenuDelegate: AnyObject {
    func didSelectMenuItem(_ menuItem: SideMenuItem)
}

enum SideMenuItem: String, CaseIterable {
    case userAgreement = "用户协议"
    case version = "版本信息"
    case contactUs = "联系我们"
    case editProfile = "编辑用户信息"
    case logout = "退出登录"
    
    var iconName: String? {
        switch self {
        case .userAgreement:
            return "doc.text"
        case .version:
            return "info.circle"
        case .contactUs:
            return "envelope"
        case .editProfile:
            return "pencil.circle"
        case .logout:
            return "arrow.right.square"
        }
    }
    
    var title: String {
        switch self {
        case .userAgreement:
            return "用户协议"
        case .version:
            return "版本信息"
        case .contactUs:
            return "联系我们"
        case .editProfile:
            return "编辑用户信息"
        case .logout:
            return "退出登录"
        }
    }
}

class SideMenuViewController: UIViewController {
    
    weak var delegate: SideMenuDelegate?
    
    // 颜色常量
    private struct Colors {
        static let background = UIColor.systemBackground
        static let userInfoBackground = UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1.0)
        static let primaryText = UIColor.label
        static let secondaryText = UIColor.secondaryLabel
        static let accent = UIColor.systemBlue
        static let separator = UIColor.separator
    }
    
    // 用户信息视图
    private lazy var userInfoView: UIView = {
        let view = UIView()
        view.backgroundColor = Colors.userInfoBackground
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加阴影效果
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        view.layer.masksToBounds = false
        
        return view
    }()
    
    // 用户头像
    private lazy var userAvatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 30
        imageView.backgroundColor = Colors.userInfoBackground
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.tintColor = Colors.accent
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加边框
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = Colors.accent.cgColor
        
        return imageView
    }()
    
    // 用户名标签
    private lazy var userNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = Colors.primaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // 用户 ID 标签
    private lazy var userIdLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = Colors.secondaryText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // 存储用户信息
    private var isLoggedIn = false
    private var userName: String?
    private var userEmail: String?
    
    // 菜单表格视图
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MenuCell")
        tableView.backgroundColor = Colors.background
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 20, right: 0)
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupNotifications()
        
        // 添加长按手势用于注销
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        userInfoView.addGestureRecognizer(longPressGesture)
        
        // 检查登录状态并加载用户信息
        checkLoginStatus()
    }
    
    // 检查登录状态
    private func checkLoginStatus() {
        if User.isTokenValid() {
            // 用户已登录且 Token 有效，获取用户信息
            fetchUserInfo()
        } else if let user = User.load() {
            // 有本地用户信息但 token 无效，显示用户信息但标记需要重新登录
            isLoggedIn = true
            userName = user.nickname
            userEmail = user.uuid
            updateUserInfoDisplay()
            
            // 刷新表格视图以显示退出登录按钮
            tableView.reloadData()
            
            // 提示用户重新登录
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let alert = UIAlertController(title: "登录已过期", message: "请重新登录", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "确定", style: .default))
                self.present(alert, animated: true)
            }
        } else {
            // 没有用户信息，确保登录状态为 false
            isLoggedIn = false
            userName = nil
            userEmail = nil
            updateUserInfoDisplay()
            tableView.reloadData()
        }
    }
    
    // 获取用户信息
    private func fetchUserInfo() {
        // 显示加载指示器
        let loadingAlert = UIAlertController(title: nil, message: "正在获取用户信息...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        loadingAlert.view.addSubview(loadingIndicator)
        present(loadingAlert, animated: true)
        
        LoginService.getUserInfo { [weak self] user, error in
            // 关闭加载指示器
            DispatchQueue.main.async {
                loadingAlert.dismiss(animated: true) {
                    if let error = error {
                        // 获取用户信息失败
                        if (error as NSError).code == 401 {
                            // 401 错误，提示用户重新登录
                            let alert = UIAlertController(title: "登录已过期", message: "请重新登录", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "确定", style: .default))
                            self?.present(alert, animated: true)
                        } else {
                            // 其他错误
                            let alert = UIAlertController(title: "获取用户信息失败", message: error.localizedDescription, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "确定", style: .default))
                            self?.present(alert, animated: true)
                        }
                    } else if let user = user {
                        // 获取用户信息成功
                        self?.isLoggedIn = true
                        self?.userName = user.name
                        self?.userEmail = user.email
                        self?.updateUserInfoDisplay()
                        
                        // 刷新表格视图以显示退出登录按钮
                        self?.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    deinit {
        // 移除通知观察者
        NotificationCenter.default.removeObserver(self, name: Notification.Name("com.gourmet.userLoggedIn"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("com.gourmet.userLoggedOut"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUserInfoDisplay()
    }
    
    private func setupView() {
        view.backgroundColor = Colors.background
        
        // 添加子视图
        view.addSubview(userInfoView)
        userInfoView.addSubview(userAvatarImageView)
        userInfoView.addSubview(userNameLabel)
        userInfoView.addSubview(userIdLabel)
        view.addSubview(tableView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            // 用户信息视图约束
            userInfoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            userInfoView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            userInfoView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            userInfoView.heightAnchor.constraint(equalToConstant: 120),
            
            // 用户头像约束
            userAvatarImageView.leadingAnchor.constraint(equalTo: userInfoView.leadingAnchor, constant: 20),
            userAvatarImageView.centerYAnchor.constraint(equalTo: userInfoView.centerYAnchor),
            userAvatarImageView.widthAnchor.constraint(equalToConstant: 60),
            userAvatarImageView.heightAnchor.constraint(equalToConstant: 60),
            
            // 用户名标签约束
            userNameLabel.leadingAnchor.constraint(equalTo: userAvatarImageView.trailingAnchor, constant: 15),
            userNameLabel.topAnchor.constraint(equalTo: userInfoView.topAnchor, constant: 30),
            userNameLabel.trailingAnchor.constraint(equalTo: userInfoView.trailingAnchor, constant: -20),
            
            // 用户 ID 标签约束
            userIdLabel.leadingAnchor.constraint(equalTo: userAvatarImageView.trailingAnchor, constant: 15),
            userIdLabel.topAnchor.constraint(equalTo: userNameLabel.bottomAnchor, constant: 5),
            userIdLabel.trailingAnchor.constraint(equalTo: userInfoView.trailingAnchor, constant: -20),
            
            // 菜单表格约束
            tableView.topAnchor.constraint(equalTo: userInfoView.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        // 添加点击手势用于登录
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleLoginTap))
        userInfoView.addGestureRecognizer(tapGesture)
        userInfoView.isUserInteractionEnabled = true
    }
    
    private func setupNotifications() {
        // 注册通知
        NotificationCenter.default.addObserver(self, selector: #selector(userLoggedIn), name: Notification.Name("com.gourmet.userLoggedIn"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(userLoggedOut), name: Notification.Name("com.gourmet.userLoggedOut"), object: nil)
    }
    
    // 通知回调
    @objc private func userLoggedIn() {
        // 加载用户信息
        if let user = User.load() {
            isLoggedIn = true
            userName = user.name
            userEmail = user.email
            updateUserInfoDisplay()
            
            // 刷新表格视图以显示退出登录按钮
            tableView.reloadData()
        }
    }
    
    @objc private func userLoggedOut() {
        // 清除用户信息
        isLoggedIn = false
        userName = nil
        userEmail = nil
        updateUserInfoDisplay()
        
        // 刷新表格视图以隐藏退出登录按钮
        tableView.reloadData()
    }
    
    // 更新用户信息显示
    private func updateUserInfoDisplay() {
        if isLoggedIn, let name = userName {
            userNameLabel.text = name
            
            if let user = User.load(), let uuid = user.uuid, !uuid.isEmpty {
                userIdLabel.text = "UUID: \(uuid)"
            } else if let email = userEmail, !email.isEmpty {
                userIdLabel.text = email
            } else {
                userIdLabel.text = "Apple 用户"
            }
            
            if let user = User.load(), let avatar = user.avatar, !avatar.isEmpty, let url = URL(string: avatar) {
                // 这里可以添加图片加载库，如 SDWebImage 或 Kingfisher
                // 简单起见，这里不实现图片加载
                userAvatarImageView.image = UIImage(systemName: "person.circle.fill")
            } else {
                userAvatarImageView.image = UIImage(systemName: "person.circle.fill")
            }
        } else {
            userNameLabel.text = "点击登录"
            userIdLabel.text = "使用 Apple 账号登录"
            userAvatarImageView.image = UIImage(systemName: "person.circle.fill")
        }
    }
    
    @objc private func handleLoginTap() {
        if isLoggedIn {
            // 已登录，不做任何操作
            return
        }
        
        // 显示加载指示器
        let loadingAlert = UIAlertController(title: nil, message: "正在登录...", preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = .medium
        loadingIndicator.startAnimating()
        loadingAlert.view.addSubview(loadingIndicator)
        present(loadingAlert, animated: true)
        
        // 生成随机授权码 (模拟 Apple 授权码)
        let randomAuthCode = generateRandomAuthCode()
        
        // 调用登录接口
        LoginService.login(withAuthCode: randomAuthCode) { [weak self] user, error in
            // 关闭加载指示器
            DispatchQueue.main.async {
                loadingAlert.dismiss(animated: true) {
                    if let error = error {
                        // 登录失败
                        let errorMessage = error.localizedDescription
                        let alert = UIAlertController(title: "登录失败", message: errorMessage, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "确定", style: .default))
                        self?.present(alert, animated: true)
                    } else if let user = user {
                        // 登录成功
                        self?.handleLoginSuccess(user: user)
                    }
                }
            }
        }
    }
    
    // 生成随机授权码 (模拟 Apple 授权码)
    private func generateRandomAuthCode() -> String {
        // 生成一个类似于 Apple 授权码的随机字符串
        let length = 32
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    private func handleLoginSuccess(user: User) {
        // 保存用户信息
        isLoggedIn = true
        userName = user.name
        userEmail = user.email
        
        // 更新UI
        updateUserInfoDisplay()
        
        // 发送登录成功通知
        let notificationName = Notification.Name("com.gourmet.userLoggedIn")
        NotificationCenter.default.post(name: notificationName, object: nil, userInfo: ["user": user])
        
        // 显示提示
        let alert = UIAlertController(title: "登录成功", message: "欢迎回来，\(user.name)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
        
        // 刷新表格视图以显示退出登录按钮
        tableView.reloadData()
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began && isLoggedIn {
            // 显示注销确认对话框
            let alert = UIAlertController(title: "注销", message: "确定要退出登录吗？", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            alert.addAction(UIAlertAction(title: "确定", style: .destructive) { [weak self] _ in
                self?.logout()
            })
            present(alert, animated: true)
        }
    }
    
    private func logout() {
        // 清除用户信息
        isLoggedIn = false
        userName = nil
        userEmail = nil
        
        // 清除保存的用户信息
        User.logout()
        
        // 更新UI
        updateUserInfoDisplay()
        
        // 发送注销通知
        let notificationName = Notification.Name("com.gourmet.userLoggedOut")
        NotificationCenter.default.post(name: notificationName, object: nil)
        
        // 显示提示
        let alert = UIAlertController(title: "已注销", message: "您已成功退出登录", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
        
        // 刷新表格视图
        tableView.reloadData()
    }
}

extension SideMenuViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 如果用户未登录，不显示退出登录按钮和编辑用户信息按钮
        if !isLoggedIn && section == 0 {
            return SideMenuItem.allCases.count - 2
        }
        return section == 0 ? SideMenuItem.allCases.count - 2 : 2
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // 如果用户已登录，添加一个额外的部分用于退出登录按钮和编辑用户信息按钮
        return isLoggedIn ? 2 : 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuCell", for: indexPath)
        
        // 根据section选择不同的菜单项
        let menuItem: SideMenuItem
        if indexPath.section == 0 {
            // 主菜单项（除了退出登录和编辑用户信息）
            let filteredItems = SideMenuItem.allCases.filter { $0 != .logout && $0 != .editProfile }
            menuItem = filteredItems[indexPath.row]
        } else {
            // 用户相关操作（编辑用户信息和退出登录）
            let userItems = [SideMenuItem.editProfile, SideMenuItem.logout]
            menuItem = userItems[indexPath.row]
            
            // 为退出登录按钮设置红色
            if menuItem == .logout {
                var content = cell.defaultContentConfiguration()
                content.text = menuItem.title
                content.textProperties.font = UIFont.systemFont(ofSize: 16, weight: .medium)
                content.textProperties.color = UIColor.systemRed
                
                if let iconName = menuItem.iconName {
                    content.image = UIImage(systemName: iconName)
                    content.imageProperties.tintColor = UIColor.systemRed
                }
                
                cell.contentConfiguration = content
                cell.backgroundColor = Colors.background
                cell.selectionStyle = .none
                
                let selectedView = UIView()
                selectedView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
                selectedView.layer.cornerRadius = 8
                cell.selectedBackgroundView = selectedView
                
                return cell
            }
        }
        
        // 配置常规菜单项单元格
        var content = cell.defaultContentConfiguration()
        content.text = menuItem.title
        content.textProperties.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        content.textProperties.color = Colors.primaryText
        
        // 设置图标
        if let iconName = menuItem.iconName {
            content.image = UIImage(systemName: iconName)
            content.imageProperties.tintColor = Colors.accent
        }
        
        // 应用配置
        cell.contentConfiguration = content
        
        // 设置背景和选中样式
        cell.backgroundColor = Colors.background
        cell.selectionStyle = .none
        
        // 添加自定义选中指示器
        let selectedView = UIView()
        selectedView.backgroundColor = Colors.accent.withAlphaComponent(0.1)
        selectedView.layer.cornerRadius = 8
        cell.selectedBackgroundView = selectedView
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let menuItem: SideMenuItem
        
        if indexPath.section == 0 {
            let filteredItems = SideMenuItem.allCases.filter { $0 != .logout && $0 != .editProfile }
            menuItem = filteredItems[indexPath.row]
        } else {
            let userItems = [SideMenuItem.editProfile, SideMenuItem.logout]
            menuItem = userItems[indexPath.row]
            
            // 如果选择了退出登录，执行退出操作
            if menuItem == .logout {
                handleLogout()
                return
            }
            
            // 如果选择了编辑用户信息，执行编辑操作
            if menuItem == .editProfile {
                handleEditProfile()
                return
            }
        }
        
        delegate?.didSelectMenuItem(menuItem)
        
        // 添加点击反馈
        UIView.animate(withDuration: 0.2, animations: {
            tableView.cellForRow(at: indexPath)?.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                tableView.cellForRow(at: indexPath)?.transform = .identity
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 {
            let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 40))
            headerView.backgroundColor = Colors.background
            
            let separatorView = UIView(frame: CGRect(x: 16, y: 0, width: tableView.bounds.width - 32, height: 1))
            separatorView.backgroundColor = Colors.separator.withAlphaComponent(0.5)
            headerView.addSubview(separatorView)
            
            return headerView
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 1 ? 40 : 0
    }
    
    // 处理退出登录
    private func handleLogout() {
        let alert = UIAlertController(title: "退出登录", message: "确定要退出当前账号吗？", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "确定", style: .destructive) { [weak self] _ in
            // 执行退出登录操作
            User.logout()
            
            // 发送退出登录通知
            NotificationCenter.default.post(name: Notification.Name("com.gourmet.userLoggedOut"), object: nil)
            
            // 更新UI
            self?.isLoggedIn = false
            self?.userName = nil
            self?.userEmail = nil
            self?.updateUserInfoDisplay()
            
            // 刷新表格视图
            self?.tableView.reloadData()
        })
        
        present(alert, animated: true)
    }
    
    private func handleEditProfile() {
        // 只有在用户登录状态下才能编辑用户信息
        guard isLoggedIn else {
            let alert = UIAlertController(title: "提示", message: "请先登录", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            present(alert, animated: true)
            return
        }
        
        // 创建一个弹窗用于编辑用户昵称
        let alert = UIAlertController(title: "编辑用户信息", message: "请输入新的昵称", preferredStyle: .alert)
        
        // 添加文本输入框
        alert.addTextField { textField in
            textField.placeholder = "昵称"
            textField.text = self.userName
        }
        
        // 添加取消按钮
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        // 添加确定按钮
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            guard let self = self,
                  let nickname = alert.textFields?.first?.text,
                  !nickname.isEmpty else {
                return
            }
            
            // 显示加载指示器
            let loadingAlert = UIAlertController(title: nil, message: "正在更新用户信息...", preferredStyle: .alert)
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.style = .medium
            loadingIndicator.startAnimating()
            loadingAlert.view.addSubview(loadingIndicator)
            self.present(loadingAlert, animated: true)
            
            // 调用服务器接口更新用户信息
            self.updateUserProfile(nickname: nickname) { success, error in
                // 关闭加载指示器
                DispatchQueue.main.async {
                    loadingAlert.dismiss(animated: true) {
                        if success {
                            // 更新成功
                            let successAlert = UIAlertController(title: "成功", message: "用户信息更新成功", preferredStyle: .alert)
                            successAlert.addAction(UIAlertAction(title: "确定", style: .default))
                            self.present(successAlert, animated: true)
                        } else {
                            // 更新失败
                            let errorAlert = UIAlertController(title: "失败", message: error ?? "用户信息更新失败", preferredStyle: .alert)
                            errorAlert.addAction(UIAlertAction(title: "确定", style: .default))
                            self.present(errorAlert, animated: true)
                        }
                    }
                }
            }
        })
        
        // 显示弹窗
        present(alert, animated: true)
    }
}

// MARK: - updateUserProfile
extension SideMenuViewController {
    private func updateUserProfile(nickname: String, completion: @escaping (Bool, String?) -> Void) {
        // 检查 token 是否有效
        guard User.isTokenValid(),
              let token = UserDefaults.standard.string(forKey: UserDefaultsKeys.token) else {
            completion(false, "登录已过期，请重新登录")
            return
        }
        
        // 构建请求 URL
        let urlString = "https://gourmet.pfcent.com/api/v1/users"
        guard let url = URL(string: urlString) else {
            completion(false, "无效的 URL")
            return
        }
        
        // 构建请求参数
        let parameters: [String: Any] = [
            "nickname": nickname
        ]
        
        // 构建请求头
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(token)",
            "User-Agent": "Gourmet iOS",
            "X-BUNDLE-ID": "com.abai.test"
        ]
        
        // 发送请求
        AF.request(url, method: .put, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .responseData { response in
                switch response.result {
                case .success(let data):
                    // 尝试解析响应
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let success = json["success"] as? Bool,
                       success,
                       let userData = json["data"] as? [String: Any],
                       let nickname = userData["nickname"] as? String {
                        
                        // 更新本地用户信息
                        if let user = User.load() {
                            var updatedUser = user
                            updatedUser.nickname = nickname
                            updatedUser.save()
                            
                            // 更新 UI 显示
                            self.userName = nickname
                            self.updateUserInfoDisplay()
                            
                            // 刷新表格视图
                            self.tableView.reloadData()
                        }
                        
                        completion(true, nil)
                    } else if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let message = json["message"] as? String {
                        completion(false, message)
                    } else {
                        completion(false, "响应解析失败")
                    }
                case .failure(let error):
                    completion(false, error.localizedDescription)
                }
            }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension SideMenuViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}
