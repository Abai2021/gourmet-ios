//
//  NavigationBarView.swift
//  gourmet-ios
//
//  Created by Cascade on 2025/3/30.
//

import UIKit

protocol NavigationBarDelegate: AnyObject {
    func didTapAvatarButton()
}

class NavigationBarView: UIView {
    
    weak var delegate: NavigationBarDelegate?
    
    // 健康主题绿色
    static let healthyGreen = UIColor(red: 76/255, green: 125/255, blue: 80/255, alpha: 1.0) // Material Design Green 500
    
    // 头像按钮
    private lazy var avatarButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 18
        button.layer.masksToBounds = true
        button.backgroundColor = .lightGray // 默认背景色
        button.setImage(UIImage(systemName: "person.crop.circle.fill"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(avatarButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // 标题标签
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Gourmet"
        label.font = UIFont(name: "Chalkduster", size: 24) // 使用艺术字体
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()
    
    // 分隔线
    private lazy var separatorLine: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = NavigationBarView.healthyGreen
        
        // 添加子视图
        addSubview(avatarButton)
        addSubview(titleLabel)
        addSubview(separatorLine)
        
        // 设置约束
        NSLayoutConstraint.activate([
            // 头像按钮约束
            avatarButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            avatarButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            avatarButton.widthAnchor.constraint(equalToConstant: 36),
            avatarButton.heightAnchor.constraint(equalToConstant: 36),
            
            // 标题标签约束
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            // 分隔线约束
            separatorLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
    
    // 设置头像图片
    func setAvatar(_ image: UIImage?) {
        if let image = image {
            avatarButton.setImage(image, for: .normal)
        }
    }
    
    @objc private func avatarButtonTapped() {
        delegate?.didTapAvatarButton()
    }
}
