//
//  SideMenuViewController.swift
//  gourmet-ios
//
//  Created by Cascade on 2025/3/30.
//

import UIKit

protocol SideMenuDelegate: AnyObject {
    func didSelectMenuItem(_ menuItem: SideMenuItem)
}

enum SideMenuItem: String, CaseIterable {
    case userAgreement = "用户协议"
    case version = "版本信息"
    case contactUs = "联系我们"
    
    var iconName: String {
        switch self {
        case .userAgreement:
            return "doc.text"
        case .version:
            return "info.circle"
        case .contactUs:
            return "envelope"
        }
    }
}

class SideMenuViewController: UIViewController {
    
    weak var delegate: SideMenuDelegate?
    
    // 用户信息视图
    private lazy var userInfoView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0)
        view.layer.cornerRadius = 0
        return view
    }()
    
    // 用户头像
    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 40
        imageView.layer.masksToBounds = true
        imageView.backgroundColor = .white
        imageView.image = UIImage(systemName: "person.crop.circle.fill")
        imageView.tintColor = .lightGray
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    // 用户昵称
    private lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "用户昵称"
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .white
        return label
    }()
    
    // 用户ID
    private lazy var userIdLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "UID: 123456789"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .white.withAlphaComponent(0.8)
        return label
    }()
    
    // 菜单表格
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MenuCell")
        tableView.backgroundColor = .white
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.tableFooterView = UIView()
        return tableView
    }()
    
    // 菜单项数据
    private let menuItems = SideMenuItem.allCases
    
    // 渐变层
    private var gradientLayer: CAGradientLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // 更新渐变层的尺寸
        if let gradientLayer = gradientLayer {
            gradientLayer.frame = userInfoView.bounds
        }
    }
    
    private func setupView() {
        view.backgroundColor = .white
        
        // 添加子视图
        view.addSubview(userInfoView)
        userInfoView.addSubview(avatarImageView)
        userInfoView.addSubview(usernameLabel)
        userInfoView.addSubview(userIdLabel)
        view.addSubview(tableView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            // 用户信息视图约束
            userInfoView.topAnchor.constraint(equalTo: view.topAnchor),
            userInfoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            userInfoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            userInfoView.heightAnchor.constraint(equalToConstant: 200),
            
            // 头像约束
            avatarImageView.centerXAnchor.constraint(equalTo: userInfoView.centerXAnchor),
            avatarImageView.topAnchor.constraint(equalTo: userInfoView.topAnchor, constant: 40),
            avatarImageView.widthAnchor.constraint(equalToConstant: 80),
            avatarImageView.heightAnchor.constraint(equalToConstant: 80),
            
            // 用户昵称约束
            usernameLabel.centerXAnchor.constraint(equalTo: userInfoView.centerXAnchor),
            usernameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 12),
            
            // 用户ID约束
            userIdLabel.centerXAnchor.constraint(equalTo: userInfoView.centerXAnchor),
            userIdLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 4),
            
            // 菜单表格约束
            tableView.topAnchor.constraint(equalTo: userInfoView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 添加渐变色背景到用户信息视图
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0).cgColor,
            UIColor(red: 0.1, green: 0.4, blue: 0.8, alpha: 1.0).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.frame = userInfoView.bounds
        userInfoView.layer.insertSublayer(gradientLayer, at: 0)
        self.gradientLayer = gradientLayer
    }
    
    // 设置用户信息
    func setUserInfo(avatar: UIImage?, username: String, userId: String) {
        if let avatar = avatar {
            avatarImageView.image = avatar
        }
        usernameLabel.text = username
        userIdLabel.text = "UID: \(userId)"
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension SideMenuViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuCell", for: indexPath)
        let menuItem = menuItems[indexPath.row]
        
        cell.textLabel?.text = menuItem.rawValue
        cell.imageView?.image = UIImage(systemName: menuItem.iconName)
        cell.imageView?.tintColor = .systemBlue
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let menuItem = menuItems[indexPath.row]
        delegate?.didSelectMenuItem(menuItem)
    }
}
