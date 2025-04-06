//
//  FoodItemCell.swift
//  gourmet-ios
//
//  Created by Cascade on 2025/4/6.
//

import UIKit
import Alamofire
import AlamofireImage

protocol FoodItemCellDelegate: AnyObject {
    func didTapDeleteButton(for foodItem: FoodItem, in record: DietRecord)
}

class FoodItemCell: UITableViewCell {
    static let identifier = "FoodItemCell"
    
    weak var delegate: FoodItemCellDelegate?
    private var foodItem: FoodItem?
    private var record: DietRecord?
    
    // 食物图片
    private lazy var foodImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        return imageView
    }()
    
    // 食物名称
    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        return label
    }()
    
    // 食物数量
    private lazy var amountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        return label
    }()
    
    // 卡路里
    private lazy var caloriesLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = UIColor(red: 240/255, green: 120/255, blue: 80/255, alpha: 1.0)
        return label
    }()
    
    // 删除按钮
    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        let configuration = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        button.setImage(UIImage(systemName: "trash", withConfiguration: configuration), for: .normal)
        button.tintColor = .systemRed
        button.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // 营养信息容器
    private lazy var nutritionStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        return stackView
    }()
    
    // 蛋白质标签
    private lazy var proteinLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .darkGray
        return label
    }()
    
    // 脂肪标签
    private lazy var fatLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .darkGray
        return label
    }()
    
    // 碳水化合物标签
    private lazy var carbLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .darkGray
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // 设置Cell背景色
        backgroundColor = .white
        
        // 添加子视图
        contentView.addSubview(foodImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(amountLabel)
        contentView.addSubview(caloriesLabel)
        contentView.addSubview(deleteButton)
        
        // 添加营养信息
        nutritionStackView.addArrangedSubview(proteinLabel)
        nutritionStackView.addArrangedSubview(fatLabel)
        nutritionStackView.addArrangedSubview(carbLabel)
        contentView.addSubview(nutritionStackView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            // 食物图片约束
            foodImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            foodImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            foodImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),
            foodImageView.widthAnchor.constraint(equalToConstant: 60),
            foodImageView.heightAnchor.constraint(equalToConstant: 60),
            
            // 食物名称约束
            nameLabel.leadingAnchor.constraint(equalTo: foodImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: deleteButton.leadingAnchor, constant: -12),
            
            // 食物数量约束
            amountLabel.leadingAnchor.constraint(equalTo: foodImageView.trailingAnchor, constant: 12),
            amountLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            amountLabel.trailingAnchor.constraint(lessThanOrEqualTo: caloriesLabel.leadingAnchor, constant: -8),
            
            // 卡路里约束
            caloriesLabel.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -16),
            caloriesLabel.centerYAnchor.constraint(equalTo: amountLabel.centerYAnchor),
            
            // 删除按钮约束
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            deleteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 44),
            deleteButton.heightAnchor.constraint(equalToConstant: 44),
            
            // 营养信息约束
            nutritionStackView.leadingAnchor.constraint(equalTo: foodImageView.trailingAnchor, constant: 12),
            nutritionStackView.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 4),
            nutritionStackView.trailingAnchor.constraint(lessThanOrEqualTo: deleteButton.leadingAnchor, constant: -12),
            nutritionStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    // 配置单元格
    func configure(with foodItem: FoodItem, in record: DietRecord) {
        self.foodItem = foodItem
        self.record = record
        
        nameLabel.text = foodItem.name
        amountLabel.text = "\(foodItem.amount) \(foodItem.unit)"
        caloriesLabel.text = "\(foodItem.calories) 千卡"
        
        proteinLabel.text = "蛋白质: \(String(format: "%.1f", foodItem.protein))g"
        fatLabel.text = "脂肪: \(String(format: "%.1f", foodItem.fat))g"
        carbLabel.text = "碳水: \(String(format: "%.1f", foodItem.carbohydrate))g"
        
        // 加载食物图片
        if let imageURL = URL(string: foodItem.image) {
            foodImageView.af.setImage(
                withURL: imageURL,
                placeholderImage: UIImage(systemName: "photo"),
                imageTransition: .crossDissolve(0.2)
            )
        } else {
            foodImageView.image = UIImage(systemName: "photo")
        }
    }
    
    @objc private func deleteButtonTapped() {
        guard let foodItem = foodItem, let record = record else { return }
        delegate?.didTapDeleteButton(for: foodItem, in: record)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        foodImageView.af.cancelImageRequest()
        foodImageView.image = nil
        nameLabel.text = nil
        amountLabel.text = nil
        caloriesLabel.text = nil
        proteinLabel.text = nil
        fatLabel.text = nil
        carbLabel.text = nil
    }
}
