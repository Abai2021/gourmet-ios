//
//  FoodCategoryCell.swift
//  gourmet-ios
//
//  Created by Cascade on 2025/4/1.
//

import UIKit

class FoodCategoryCell: UICollectionViewCell {
    static let reuseIdentifier = "FoodCategoryCell"
    
    // 标签
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // 渐变层
    private let gradientLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = contentView.bounds
        layer.cornerRadius = 12
        clipsToBounds = true
    }
    
    private func setupView() {
        // 添加阴影
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.1
        
        // 添加渐变层
        contentView.layer.insertSublayer(gradientLayer, at: 0)
        
        // 添加标签
        contentView.addSubview(nameLabel)
        
        // 设置约束
        NSLayoutConstraint.activate([
            nameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
        ])
    }
    
    func configure(with category: FoodCategory) {
        nameLabel.text = category.name
        setRandomGradientColors()
    }
    
    private func setRandomGradientColors() {
        // 生成随机的淡色渐变色
        let colors = generateRandomPastelColors()
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
    }
    
    private func generateRandomPastelColors() -> [UIColor] {
        // 生成随机的淡色
        let hue1 = CGFloat.random(in: 0...1)
        let hue2 = (hue1 + CGFloat.random(in: 0.1...0.3)).truncatingRemainder(dividingBy: 1.0)
        
        let color1 = UIColor(hue: hue1, saturation: 0.4, brightness: 0.9, alpha: 1.0)
        let color2 = UIColor(hue: hue2, saturation: 0.4, brightness: 0.9, alpha: 1.0)
        
        return [color1, color2]
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
    }
}
