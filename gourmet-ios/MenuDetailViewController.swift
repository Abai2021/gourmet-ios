//
//  MenuDetailViewController.swift
//  gourmet-ios
//
//  Created by Cascade on 2025/3/30.
//

import UIKit

class MenuDetailViewController: UIViewController {
    
    private let menuItem: SideMenuItem
    
    private let centerLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let gradientLayer = CAGradientLayer()
    
    init(menuItem: SideMenuItem) {
        self.menuItem = menuItem
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置标题
        title = menuItem.rawValue
        
        // 设置返回按钮
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeButtonTapped)
        )
        
        // 添加中心标签
        view.addSubview(centerLabel)
        
        // 设置约束
        NSLayoutConstraint.activate([
            centerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // 根据菜单项设置标签文本
        setupContent()
        
        // 设置渐变背景
        setupGradientBackground()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }
    
    private func setupContent() {
        switch menuItem {
        case .userAgreement:
            centerLabel.text = "用户协议内容"
        case .version:
            centerLabel.text = "当前版本: 1.0.0"
        case .contactUs:
            centerLabel.text = "联系邮箱: support@gourmet.com"
        case .editProfile:
            centerLabel.text = "编辑用户信息"
        case .logout:
            // 退出登录不会显示在此视图中，但需要添加此情况以使 switch 完整
            centerLabel.text = ""
        }
    }
    
    private func setupGradientBackground() {
        // 根据菜单项选择不同的渐变色
        var topColor: CGColor
        var bottomColor: CGColor
        
        switch menuItem {
        case .userAgreement:
            topColor = UIColor(red: 0.4, green: 0.6, blue: 0.8, alpha: 1.0).cgColor
            bottomColor = UIColor(red: 0.2, green: 0.4, blue: 0.7, alpha: 1.0).cgColor
        case .version:
            topColor = UIColor(red: 0.5, green: 0.7, blue: 0.3, alpha: 1.0).cgColor
            bottomColor = UIColor(red: 0.3, green: 0.5, blue: 0.2, alpha: 1.0).cgColor
        case .contactUs:
            topColor = UIColor(red: 0.8, green: 0.4, blue: 0.6, alpha: 1.0).cgColor
            bottomColor = UIColor(red: 0.6, green: 0.2, blue: 0.4, alpha: 1.0).cgColor
        case .editProfile:
            topColor = UIColor(red: 0.7, green: 0.5, blue: 0.9, alpha: 1.0).cgColor
            bottomColor = UIColor(red: 0.5, green: 0.3, blue: 0.7, alpha: 1.0).cgColor
        case .logout:
            topColor = UIColor(red: 0.4, green: 0.6, blue: 0.8, alpha: 1.0).cgColor
            bottomColor = UIColor(red: 0.2, green: 0.4, blue: 0.7, alpha: 1.0).cgColor
        }
        
        gradientLayer.colors = [topColor, bottomColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        
        // 插入渐变层到底部
        view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
}
