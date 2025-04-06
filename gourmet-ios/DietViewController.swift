//
//  DietViewController.swift
//  gourmet-ios
//
//  Created by Cascade on 2025/3/30.
//

import UIKit
import Alamofire

// MARK: - 调试辅助函数
func debugLog(_ items: Any..., file: String = #file, function: String = #function, line: Int = #line) {
    #if DEBUG
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    let timestamp = dateFormatter.string(from: Date())
    let fileURL = URL(fileURLWithPath: file)
    let fileName = fileURL.lastPathComponent
    let outputItems = items.map { "\($0)" }.joined(separator: " ")
    
    print("\(timestamp) [\(fileName):\(line)] \(function): \(outputItems)")
    #endif
}

// MARK: - APIConst 定义
struct APIConst {
    static let BaseUrl = "https://gourmet.pfcent.com"
}

// MARK: - 数据模型

// 饮食记录返回数据模型
struct DietRecordResponse: Codable {
    let success: Bool
    let data: [DietRecord]?
    let requestId: String
    
    enum CodingKeys: String, CodingKey {
        case success
        case data
        case requestId = "request_id"
    }
}

// 日期加载方向枚举
enum LoadDirection {
    case past    // 加载过去的日期
    case future  // 加载未来的日期
}

// 饮食记录
struct DietRecord: Codable, Identifiable {
    let id: Int
    let date: String
    let mealType: Int
    let foods: [FoodItem]
    
    enum CodingKeys: String, CodingKey {
        case id
        case date
        case mealType = "meal_type"
        case foods
    }
    
    // 获取餐类型的名称
    var mealTypeName: String {
        switch mealType {
        case 1:
            return "早餐"
        case 2:
            return "午餐"
        case 3:
            return "晚餐"
        case 4:
            return "零食"
        default:
            return "其他"
        }
    }
}

// 食物项
struct FoodItem: Codable, Identifiable {
    let id: Int
    let foodId: Int
    let name: String
    let image: String
    let amount: Int
    let unit: String
    let calories: Int
    let protein: Double
    let fat: Double
    let carbohydrate: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case foodId = "food_id"
        case name
        case image
        case amount
        case unit
        case calories
        case protein
        case fat
        case carbohydrate
    }
}

// 营养摄入汇总
struct NutritionSummary {
    var totalCalories: Int = 0
    var totalProtein: Double = 0
    var totalFat: Double = 0
    var totalCarbohydrate: Double = 0
    
    mutating func add(foodItem: FoodItem) {
        totalCalories += foodItem.calories
        totalProtein += foodItem.protein
        totalFat += foodItem.fat
        totalCarbohydrate += foodItem.carbohydrate
    }
}

// MARK: - FoodItemCellDelegate 协议

protocol FoodItemCellDelegate: AnyObject {
    func didTapDeleteButton(for foodItem: FoodItem, in record: DietRecord)
}

// MARK: - FoodItemCell 定义

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
            // 使用普通的URLSession加载图片
            URLSession.shared.dataTask(with: imageURL) { [weak self] data, response, error in
                guard let self = self, let data = data, error == nil else {
                    DispatchQueue.main.async {
                        if let self = self {
                            self.foodImageView.image = UIImage(systemName: "photo")
                        }
                    }
                    return
                }
                
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.foodImageView.image = image
                    }
                } else {
                    DispatchQueue.main.async {
                        self.foodImageView.image = UIImage(systemName: "photo")
                    }
                }
            }.resume()
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
        
        // 取消可能存在的图片加载任务
        foodImageView.image = nil
        nameLabel.text = nil
        amountLabel.text = nil
        caloriesLabel.text = nil
        proteinLabel.text = nil
        fatLabel.text = nil
        carbLabel.text = nil
    }
}

// MARK: - AddFoodViewController相关协议和类
protocol AddFoodViewControllerDelegate: AnyObject {
    func didAddFoodRecord()
}

class AddFoodViewController: UIViewController {
    weak var delegate: AddFoodViewControllerDelegate?
    
    // MARK: - 属性
    private var selectedDate: Date
    private var foods: [SearchFood] = []
    private var selectedFood: SearchFood?
    private var selectedMealType: Int = 1 // 默认早餐
    private var foodAmount: Double = 100.0 // 默认100g
    
    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    private let foodDetailView = UIView()
    private let amountSlider = UISlider()
    private let caloriesLabel = UILabel()
    private let amountLabel = UILabel()
    private let mealTypeSegmentedControl = UISegmentedControl(items: ["早餐", "午餐", "晚餐", "零食"])
    private let addButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let emptyStateLabel = UILabel()
    
    // MARK: - 初始化
    init(date: Date) {
        self.selectedDate = date
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "添加食物"
        
        setupViews()
        setupConstraints()
    }
    
    // MARK: - 视图设置
    private func setupViews() {
        // 设置导航栏
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelButtonTapped)
        )
        
        // 设置搜索栏
        searchBar.placeholder = "搜索食物..."
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置表格视图
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "FoodCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .singleLine
        tableView.isHidden = true
        
        // 设置空状态标签
        emptyStateLabel.text = "请输入关键词搜索食物"
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.textColor = .gray
        emptyStateLabel.font = UIFont.systemFont(ofSize: 16)
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置食物详情视图
        foodDetailView.translatesAutoresizingMaskIntoConstraints = false
        foodDetailView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        foodDetailView.layer.cornerRadius = 12
        foodDetailView.isHidden = true
        
        // 设置食物数量滑块
        amountSlider.minimumValue = 10
        amountSlider.maximumValue = 500
        amountSlider.value = 100
        amountSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        amountSlider.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置卡路里标签
        caloriesLabel.text = "热量: 0 kcal"
        caloriesLabel.textAlignment = .center
        caloriesLabel.font = UIFont.boldSystemFont(ofSize: 18)
        caloriesLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置数量标签
        amountLabel.text = "数量: 100g"
        amountLabel.textAlignment = .center
        amountLabel.font = UIFont.systemFont(ofSize: 16)
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置膳食类型选择器
        mealTypeSegmentedControl.selectedSegmentIndex = 0 // 默认选择早餐
        mealTypeSegmentedControl.addTarget(self, action: #selector(mealTypeChanged), for: .valueChanged)
        mealTypeSegmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置添加按钮
        addButton.setTitle("添加食物", for: .normal)
        addButton.setTitleColor(.white, for: .normal)
        addButton.backgroundColor = UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1.0)
        addButton.layer.cornerRadius = 8
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置加载指示器
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加子视图
        view.addSubview(searchBar)
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)
        view.addSubview(foodDetailView)
        view.addSubview(loadingIndicator)
        
        foodDetailView.addSubview(caloriesLabel)
        foodDetailView.addSubview(amountLabel)
        foodDetailView.addSubview(amountSlider)
        foodDetailView.addSubview(mealTypeSegmentedControl)
        foodDetailView.addSubview(addButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 搜索栏约束
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // 表格视图约束
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // 空状态标签约束
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // 食物详情视图约束
            foodDetailView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            foodDetailView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            foodDetailView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            
            // 卡路里标签约束
            caloriesLabel.topAnchor.constraint(equalTo: foodDetailView.topAnchor, constant: 16),
            caloriesLabel.leadingAnchor.constraint(equalTo: foodDetailView.leadingAnchor, constant: 16),
            caloriesLabel.trailingAnchor.constraint(equalTo: foodDetailView.trailingAnchor, constant: -16),
            
            // 数量标签约束
            amountLabel.topAnchor.constraint(equalTo: caloriesLabel.bottomAnchor, constant: 8),
            amountLabel.leadingAnchor.constraint(equalTo: foodDetailView.leadingAnchor, constant: 16),
            amountLabel.trailingAnchor.constraint(equalTo: foodDetailView.trailingAnchor, constant: -16),
            
            // 数量滑块约束
            amountSlider.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 16),
            amountSlider.leadingAnchor.constraint(equalTo: foodDetailView.leadingAnchor, constant: 16),
            amountSlider.trailingAnchor.constraint(equalTo: foodDetailView.trailingAnchor, constant: -16),
            
            // 膳食类型选择器约束
            mealTypeSegmentedControl.topAnchor.constraint(equalTo: amountSlider.bottomAnchor, constant: 16),
            mealTypeSegmentedControl.leadingAnchor.constraint(equalTo: foodDetailView.leadingAnchor, constant: 16),
            mealTypeSegmentedControl.trailingAnchor.constraint(equalTo: foodDetailView.trailingAnchor, constant: -16),
            
            // 添加按钮约束
            addButton.topAnchor.constraint(equalTo: mealTypeSegmentedControl.bottomAnchor, constant: 16),
            addButton.leadingAnchor.constraint(equalTo: foodDetailView.leadingAnchor, constant: 16),
            addButton.trailingAnchor.constraint(equalTo: foodDetailView.trailingAnchor, constant: -16),
            addButton.heightAnchor.constraint(equalToConstant: 44),
            addButton.bottomAnchor.constraint(equalTo: foodDetailView.bottomAnchor, constant: -16),
            
            // 加载指示器约束
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - 操作响应
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func sliderValueChanged() {
        foodAmount = Double(amountSlider.value)
        updateFoodDetail()
    }
    
    @objc private func mealTypeChanged() {
        selectedMealType = mealTypeSegmentedControl.selectedSegmentIndex + 1
    }
    
    @objc private func addButtonTapped() {
        guard let food = selectedFood else { return }
        
        // 显示加载指示器
        loadingIndicator.startAnimating()
        
        // 准备食物数据
        let calories = calculateCalories(for: food, amount: foodAmount)
        let createFoodItem = CreateFoodItem(
            foodId: food.id,
            amount: foodAmount,
            unit: "g",
            calories: calories,
            protein: nil,
            fat: nil,
            carbohydrate: nil
        )
        
        // 格式化日期
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: selectedDate)
        
        // 调用API创建记录
        DietAPI.shared.createDietRecord(
            date: dateString,
            mealType: selectedMealType,
            foods: [createFoodItem]
        ) { [weak self] result in
            guard let self = self else { return }
            
            // 停止加载指示器
            self.loadingIndicator.stopAnimating()
            
            switch result {
            case .success(_):
                print("成功添加食物记录")
                // 通知委托
                self.delegate?.didAddFoodRecord()
                // 关闭视图
                self.dismiss(animated: true)
                
            case .failure(let error):
                print("添加食物记录失败: \(error.localizedDescription)")
                self.showError(message: "添加食物记录失败: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 辅助方法
    
    private func searchFoods(keyword: String) {
        guard !keyword.isEmpty else {
            foods = []
            tableView.isHidden = true
            emptyStateLabel.isHidden = false
            emptyStateLabel.text = "请输入关键词搜索食物"
            return
        }
        
        // 显示加载指示器
        loadingIndicator.startAnimating()
        tableView.isHidden = true
        emptyStateLabel.isHidden = true
        
        // 调用API搜索食物
        DietAPI.shared.searchFoods(keyword: keyword) { [weak self] result in
            guard let self = self else { return }
            
            // 停止加载指示器
            self.loadingIndicator.stopAnimating()
            
            switch result {
            case .success(let foods):
                self.foods = foods
                
                // 更新UI
                if foods.isEmpty {
                    self.tableView.isHidden = true
                    self.emptyStateLabel.isHidden = false
                    self.emptyStateLabel.text = "未找到相关食物"
                } else {
                    self.tableView.isHidden = false
                    self.emptyStateLabel.isHidden = true
                    self.tableView.reloadData()
                }
                
            case .failure(let error):
                print("搜索食物失败: \(error.localizedDescription)")
                self.tableView.isHidden = true
                self.emptyStateLabel.isHidden = false
                self.emptyStateLabel.text = "搜索失败: \(error.localizedDescription)"
            }
        }
    }
    
    private func selectFood(_ food: SearchFood) {
        selectedFood = food
        foodDetailView.isHidden = false
        updateFoodDetail()
    }
    
    private func updateFoodDetail() {
        guard let food = selectedFood else { return }
        
        // 更新数量标签
        amountLabel.text = "数量: \(Int(foodAmount))g"
        
        // 计算并更新卡路里
        let calories = calculateCalories(for: food, amount: foodAmount)
        caloriesLabel.text = "热量: \(calories) kcal"
    }
    
    private func calculateCalories(for food: SearchFood, amount: Double) -> Int {
        // 计算公式: (标准热量 / 100) * 实际克数
        let calories = Int(Double(food.standardCalories) * amount / 100.0)
        return calories
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(
            title: "错误",
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: "确定",
            style: .default
        ))
        
        present(alert, animated: true)
    }
}

// MARK: - UISearchBarDelegate

extension AddFoodViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // 延迟搜索以避免频繁请求
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(delayedSearch), object: nil)
        perform(#selector(delayedSearch), with: nil, afterDelay: 0.5)
    }
    
    @objc private func delayedSearch() {
        if let searchText = searchBar.text {
            searchFoods(keyword: searchText)
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchText = searchBar.text {
            searchFoods(keyword: searchText)
        }
        searchBar.resignFirstResponder()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension AddFoodViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return foods.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FoodCell", for: indexPath)
        let food = foods[indexPath.row]
        
        // 配置单元格
        var content = cell.defaultContentConfiguration()
        content.text = food.name
        content.secondaryText = "\(food.standardCalories)千卡/100g"
        
        // 设置图标
        if #available(iOS 14.0, *) {
            content.image = UIImage(systemName: "fork.knife")
            content.imageProperties.tintColor = .systemGray
        }
        
        cell.contentConfiguration = content
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let food = foods[indexPath.row]
        selectFood(food)
    }
}

// MARK: - DietAPI 定义

class DietAPI {
    static let shared = DietAPI()
    
    private init() {}
    
    // 获取指定日期的饮食记录
    func fetchDietRecords(date: String, completion: @escaping (Result<[DietRecord], Error>) -> Void) {
        let urlString = "\(APIConst.BaseUrl)/api/v1/directs?date=\(date)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "com.gourmet.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var headers: HTTPHeaders = [
            "Accept": "*/*",
            "Accept-Encoding": "gzip, deflate, br",
            "Connection": "keep-alive",
            "User-Agent": "GourmetApp/1.0"
        ]
        
        // 添加认证头
        if let token = UserDefaults.standard.string(forKey: UserDefaultsKeys.token) {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        AF.request(url, method: .get, headers: headers)
            .validate()
            .responseDecodable(of: DietRecordResponse.self) { response in
                switch response.result {
                case .success(let dietResponse):
                    if dietResponse.success {
                        completion(.success(dietResponse.data ?? []))
                    } else {
                        completion(.failure(NSError(domain: "com.gourmet.error", code: -2, userInfo: [NSLocalizedDescriptionKey: "API returned success=false"])))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    // 删除指定的食物项
    func deleteFoodItem(recordId: Int, foodItemId: Int, completion: @escaping (Result<[DietRecord], Error>) -> Void) {
        let urlString = "\(APIConst.BaseUrl)/api/v1/directs?record_id=\(recordId)&food_item_id=\(foodItemId)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "com.gourmet.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var headers: HTTPHeaders = [
            "Accept": "*/*",
            "Accept-Encoding": "gzip, deflate, br",
            "Connection": "keep-alive",
            "User-Agent": "GourmetApp/1.0"
        ]
        
        // 添加认证头
        if let token = UserDefaults.standard.string(forKey: UserDefaultsKeys.token) {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        AF.request(url, method: .delete, headers: headers)
            .validate()
            .responseDecodable(of: DietRecordResponse.self) { response in
                switch response.result {
                case .success(let dietResponse):
                    if dietResponse.success {
                        completion(.success(dietResponse.data ?? []))
                    } else {
                        completion(.failure(NSError(domain: "com.gourmet.error", code: -2, userInfo: [NSLocalizedDescriptionKey: "API returned success=false"])))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    // 创建饮食记录
    func createDietRecord(date: String, mealType: Int, foods: [CreateFoodItem], completion: @escaping (Result<[DietRecord], Error>) -> Void) {
        let urlString = "\(APIConst.BaseUrl)/api/v1/directs"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "com.gourmet.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var headers: HTTPHeaders = [
            "Accept": "*/*",
            "Accept-Encoding": "gzip, deflate, br",
            "Connection": "keep-alive",
            "User-Agent": "GourmetApp/1.0",
            "Content-Type": "application/json"
        ]
        
        // 添加认证头
        if let token = UserDefaults.standard.string(forKey: UserDefaultsKeys.token) {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        let parameters: [String: Any] = [
            "date": date,
            "meal_type": mealType,
            "foods": foods.map { [
                "food_id": $0.foodId,
                "amount": $0.amount,
                "unit": $0.unit,
                "calories": $0.calories,
                "protein": $0.protein ?? 0.0,
                "fat": $0.fat ?? 0.0,
                "carbohydrate": $0.carbohydrate ?? 0.0
            ] }
        ]
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .responseDecodable(of: DietRecordResponse.self) { response in
                switch response.result {
                case .success(let dietResponse):
                    if dietResponse.success {
                        completion(.success(dietResponse.data ?? []))
                    } else {
                        completion(.failure(NSError(domain: "com.gourmet.error", code: -2, userInfo: [NSLocalizedDescriptionKey: "API returned success=false"])))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
    
    // 搜索食物
    func searchFoods(keyword: String, completion: @escaping (Result<[SearchFood], Error>) -> Void) {
        let urlString = "\(APIConst.BaseUrl)/api/v1/foods/search?keyword=\(keyword)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "com.gourmet.error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var headers: HTTPHeaders = [
            "Accept": "*/*",
            "Accept-Encoding": "gzip, deflate, br",
            "Connection": "keep-alive",
            "User-Agent": "GourmetApp/1.0"
        ]
        
        // 添加认证头
        if let token = UserDefaults.standard.string(forKey: UserDefaultsKeys.token) {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        AF.request(url, method: .get, headers: headers)
            .validate()
            .responseDecodable(of: FoodResponse.self) { response in
                switch response.result {
                case .success(let foodResponse):
                    if foodResponse.success {
                        completion(.success(foodResponse.data.list))
                    } else {
                        completion(.failure(NSError(domain: "com.gourmet.error", code: -2, userInfo: [NSLocalizedDescriptionKey: "API returned success=false"])))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}

// MARK: - FoodResponse

struct FoodResponse: Codable {
    let success: Bool
    let data: FoodResponseData
    
    enum CodingKeys: String, CodingKey {
        case success
        case data
    }
}

// MARK: - FoodResponseData

struct FoodResponseData: Codable {
    let keyword: String
    let limit: Int
    let list: [SearchFood]
    let page: Int
    let total: Int
    
    // 添加initializer以处理可能缺失的字段
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        keyword = try container.decodeIfPresent(String.self, forKey: .keyword) ?? ""
        limit = try container.decodeIfPresent(Int.self, forKey: .limit) ?? 20
        list = try container.decode([SearchFood].self, forKey: .list)
        page = try container.decodeIfPresent(Int.self, forKey: .page) ?? 1
        total = try container.decodeIfPresent(Int.self, forKey: .total) ?? 0
    }
    
    enum CodingKeys: String, CodingKey {
        case keyword
        case limit
        case list
        case page
        case total
    }
}

// MARK: - SearchFood

struct SearchFood: Codable, Identifiable {
    let id: Int
    let name: String
    let evaluation: String?
    let imageUrl: String?
    let standardCalories: Int
    let category: [FoodCategory]?
    
    // 添加初始化方法以处理API返回的内容
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        evaluation = try container.decodeIfPresent(String.self, forKey: .evaluation)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        standardCalories = try container.decode(Int.self, forKey: .standardCalories)
        category = try container.decodeIfPresent([FoodCategory].self, forKey: .category)
    }
    
    // 实现encode方法满足Encodable协议
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(evaluation, forKey: .evaluation)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encode(standardCalories, forKey: .standardCalories)
        try container.encodeIfPresent(category, forKey: .category)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case evaluation
        case imageUrl = "image_url"
        case standardCalories = "standard_calories"
        case category
    }
}

// MARK: - FoodCategory

//struct FoodCategory: Codable {
//    let id: Int
//    let name: String
//}

// MARK: - CreateFoodItem

struct CreateFoodItem: Codable {
    let foodId: Int
    let amount: Double
    let unit: String
    let calories: Int
    let protein: Double?
    let fat: Double?
    let carbohydrate: Double?
    
    enum CodingKeys: String, CodingKey {
        case foodId = "food_id"
        case amount
        case unit
        case calories
        case protein
        case fat
        case carbohydrate
    }
}

class DietViewController: UIViewController, AddFoodViewControllerDelegate {
    
    // MARK: - 属性
    
    // 用户界面元素
    private var tableView: UITableView!
    private var dateScrollView: UIScrollView!
    private var dateStackView: UIStackView!
    private var emptyStateView: UIView!
    private var loadingIndicator: UIActivityIndicatorView!
    private var addFoodButton: UIButton!
    private var calorieCounterView: UIView!
    private var calorieCounterLabel: UILabel!
    
    // 数据和状态
    private var selectedDate: Date = Date()
    private var visibleDates: [Date] = []
    private var currentDateIndex: Int = 0
    private var dietRecords: [DietRecord] = []
    private var recordSections: [[DietRecord]] = [[], [], [], []]
    private var isLoading = false
    private let dateRange: Int = 180 // 前后可查看的日期范围（天）
    
    // 控制状态
    private var initialScrollDone = false
    
    // 格式化器
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    // MARK: - 生命周期方法
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("DietViewController - viewDidLoad 开始")
        
        // 初始化界面
        setupViews()
        
        // 添加刷新控件
        setupPullToRefresh()
        
        print("DietViewController - viewDidLoad 结束")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("DietViewController - viewWillAppear")
        
        // 检查用户登录状态
        checkLoginStatus()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        print("DietViewController - viewDidLayoutSubviews")
        
        // 确保日期滚动视图正确配置
        configureDateScrollView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("DietViewController - viewDidAppear")
        
        // 再次确认日期滚动视图已正确显示
        print("日期滚动视图尺寸: \(dateScrollView.frame)")
        print("日期堆栈视图尺寸: \(dateStackView.frame)")
        print("日期按钮数量: \(dateStackView.arrangedSubviews.count)")
        
        // 强制更新日期按钮
        if dateStackView.arrangedSubviews.isEmpty {
            print("重新创建日期按钮")
            setupDatePicker()
        }
    }
    
    // MARK: - 界面设置
    
    private func setupViews() {
        print("设置视图开始")
        title = "饮食记录"
        view.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        
        // 创建并配置日期滚动视图
        dateScrollView = {
            let scrollView = UIScrollView()
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.backgroundColor = .white
            scrollView.delegate = self
            scrollView.decelerationRate = .fast
            scrollView.layer.shadowColor = UIColor.black.cgColor
            scrollView.layer.shadowOffset = CGSize(width: 0, height: 2)
            scrollView.layer.shadowRadius = 3
            scrollView.layer.shadowOpacity = 0.1
            return scrollView
        }()
        
        // 创建并配置日期堆栈视图
        dateStackView = {
            let stackView = UIStackView()
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .horizontal
            stackView.distribution = .fillEqually
            stackView.spacing = 12
            return stackView
        }()
        
        // 创建并配置表格视图
        tableView = {
            let tableView = UITableView()
            tableView.translatesAutoresizingMaskIntoConstraints = false
            tableView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
            tableView.separatorStyle = .none
            tableView.delegate = self
            tableView.dataSource = self
            tableView.register(FoodItemCell.self, forCellReuseIdentifier: FoodItemCell.identifier)
            tableView.sectionHeaderTopPadding = 0
            tableView.tableFooterView = UIView()
            tableView.allowsSelection = false
            return tableView
        }()
        
        // 创建并配置空状态视图
        emptyStateView = {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.isHidden = true
            
            let imageView = UIImageView(image: UIImage(systemName: "fork.knife.circle"))
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = .gray
            
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = "今天还没有饮食记录"
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 18)
            label.textColor = .gray
            
            view.addSubview(imageView)
            view.addSubview(label)
            
            NSLayoutConstraint.activate([
                imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
                imageView.widthAnchor.constraint(equalToConstant: 80),
                imageView.heightAnchor.constraint(equalToConstant: 80),
                
                label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
                label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
            ])
            
            return view
        }()
        
        // 创建并配置加载指示器
        loadingIndicator = {
            let indicator = UIActivityIndicatorView(style: .medium)
            indicator.translatesAutoresizingMaskIntoConstraints = false
            indicator.hidesWhenStopped = true
            return indicator
        }()
        
        // 创建并配置添加食物按钮
        addFoodButton = {
            let button = UIButton(type: .system)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
            button.tintColor = UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1.0)
            button.backgroundColor = .white
            button.layer.cornerRadius = 28
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOffset = CGSize(width: 0, height: 2)
            button.layer.shadowRadius = 3
            button.layer.shadowOpacity = 0.3
            button.addTarget(self, action: #selector(addFoodButtonTapped), for: .touchUpInside)
            
            // 设置按钮大小
            button.widthAnchor.constraint(equalToConstant: 56).isActive = true
            button.heightAnchor.constraint(equalToConstant: 56).isActive = true
            
            return button
        }()
        
        // 创建并配置卡路里计数器视图
        calorieCounterView = {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.backgroundColor = UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1.0)
            view.layer.cornerRadius = 35
            
            // 添加卡路里标签
            calorieCounterLabel = UILabel()
            calorieCounterLabel.translatesAutoresizingMaskIntoConstraints = false
            calorieCounterLabel.textColor = .white
            calorieCounterLabel.font = UIFont.boldSystemFont(ofSize: 16)
            calorieCounterLabel.textAlignment = .center
            calorieCounterLabel.text = "0\nkcal"
            calorieCounterLabel.numberOfLines = 2
            
            view.addSubview(calorieCounterLabel)
            
            NSLayoutConstraint.activate([
                calorieCounterLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                calorieCounterLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
            
            // 设置视图大小
            view.widthAnchor.constraint(equalToConstant: 70).isActive = true
            view.heightAnchor.constraint(equalToConstant: 70).isActive = true
            
            return view
        }()
        
        // 添加子视图
        view.addSubview(dateScrollView)
        dateScrollView.addSubview(dateStackView)
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        view.addSubview(loadingIndicator)
        view.addSubview(addFoodButton)
        view.addSubview(calorieCounterView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            // 日期滚动视图约束 - 修复高度
            dateScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            dateScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dateScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dateScrollView.heightAnchor.constraint(equalToConstant: 80),
            
            // 日期堆栈视图约束 
            dateStackView.topAnchor.constraint(equalTo: dateScrollView.topAnchor, constant: 10),
            dateStackView.leadingAnchor.constraint(equalTo: dateScrollView.leadingAnchor, constant: 16),
            dateStackView.bottomAnchor.constraint(equalTo: dateScrollView.bottomAnchor, constant: -10),
            dateStackView.heightAnchor.constraint(equalToConstant: 60),
            
            // 卡路里计数器视图约束
            calorieCounterView.topAnchor.constraint(equalTo: dateScrollView.bottomAnchor, constant: 10),
            calorieCounterView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // 表格视图约束
            tableView.topAnchor.constraint(equalTo: calorieCounterView.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // 空状态视图约束
            emptyStateView.topAnchor.constraint(equalTo: calorieCounterView.bottomAnchor, constant: 10),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // 加载指示器约束
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // 添加食物按钮约束
            addFoodButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addFoodButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        
        print("设置视图完成")
    }
    
    private func setupPullToRefresh() {
        print("设置下拉刷新")
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    @objc private func refreshData(_ sender: UIRefreshControl) {
        print("触发下拉刷新")
        // 刷新当前选中日期的饮食记录
        loadDietRecords(for: selectedDate)
        
        // 延迟停止刷新动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            sender.endRefreshing()
        }
    }
    
    private func setupDatePicker() {
        print("setupDatePicker 开始")
        // 清除现有的日期按钮
        dateStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 初始化日期数据
        initializeDateRange()
        
        // 创建日期按钮
        updateVisibleDateButtons()
        
        print("日期按钮数量: \(dateStackView.arrangedSubviews.count)")
        print("setupDatePicker 完成")
    }
    
    private func initializeDateRange() {
        print("初始化日期范围")
        // 生成日期范围列表，包括今天以及前后一定范围的日期
        let calendar = Calendar.current
        let today = Date()
        visibleDates = []
        
        // 添加今天之前的日期
        for day in 1...15 {
            if let date = calendar.date(byAdding: .day, value: -day, to: today) {
                visibleDates.insert(date, at: 0)
            }
        }
        
        // 添加今天
        visibleDates.append(today)
        
        // 添加今天之后的日期
        for day in 1...15 {
            if let date = calendar.date(byAdding: .day, value: day, to: today) {
                visibleDates.append(date)
            }
        }
        
        currentDateIndex = 15  // 今天的索引
        print("今天在日期数组中的索引: \(currentDateIndex), 总共日期数: \(visibleDates.count)")
        
        // 更新选中日期
        selectedDate = today
    }
    
    // 更新可见的日期按钮
    private func updateVisibleDateButtons() {
        print("更新可见日期按钮")
        // 清除现有按钮
        dateStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 创建新的日期按钮
        let calendar = Calendar.current
        
        for (index, date) in visibleDates.enumerated() {
            let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
            let dateButton = createDateButton(for: date, isSelected: isSelected, index: index)
            dateStackView.addArrangedSubview(dateButton)
            
            // 打印前几个日期按钮的信息（用于调试）
            if index < 3 || (index >= currentDateIndex - 1 && index <= currentDateIndex + 1) || index > visibleDates.count - 3 {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                print("添加日期按钮[\(index)]: \(formatter.string(from: date)), isSelected=\(isSelected)")
            }
        }
        
        print("创建了 \(dateStackView.arrangedSubviews.count) 个日期按钮")
    }
    
    private func createDateButton(for date: Date, isSelected: Bool, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置按钮宽度和高度
        button.widthAnchor.constraint(equalToConstant: 80).isActive = true
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        // 设置按钮样式
        button.backgroundColor = isSelected ? UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1.0) : .white
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1.0).cgColor
        
        // 获取日期组件
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)
        
        // 文本颜色
        let textColor = isSelected ? UIColor.white : UIColor.black
        
        // 日期格式化器
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"
        
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "E"
        
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "M月"
        
        // 创建总的NSAttributedString
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 2
        
        let attributedString = NSMutableAttributedString()
        
        // 1. 添加日期（今天或数字）
        let dayText = isToday ? "今天" : dayFormatter.string(from: date)
        attributedString.append(NSAttributedString(
            string: dayText,
            attributes: [
                .font: UIFont.systemFont(ofSize: 16, weight: .medium),
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
            ]
        ))
        
        // 2. 添加星期
        let weekdayText = weekdayFormatter.string(from: date)
        attributedString.append(NSAttributedString(
            string: "\n\(weekdayText)",
            attributes: [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
            ]
        ))
        
        // 3. 总是添加月份标注，使用灰色
        let monthText = monthFormatter.string(from: date)
        attributedString.append(NSAttributedString(
            string: "\n\(monthText)",
            attributes: [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: isSelected ? UIColor.white.withAlphaComponent(0.8) : UIColor.gray,
                .paragraphStyle: paragraphStyle
            ]
        ))
        
        // 设置按钮标题
        button.setAttributedTitle(attributedString, for: .normal)
        
        // 设置按钮标签（用于标识日期）
        button.tag = index
        
        // 添加点击事件
        button.addTarget(self, action: #selector(dateButtonTapped(_:)), for: .touchUpInside)
        
        return button
    }
    
    private func configureDateScrollView() {
        print("配置日期滚动视图")
        // 设置滚动视图的内容尺寸
        let buttonWidth: CGFloat = 80 // 每个日期按钮的宽度
        let spacing: CGFloat = 12 // 按钮之间的间距
        let buttonsCount = dateStackView.arrangedSubviews.count
        
        print("日期按钮数量: \(buttonsCount)")
        
        if buttonsCount == 0 {
            print("无日期按钮，重新设置")
            setupDatePicker()
            return
        }
        
        let totalWidth = CGFloat(buttonsCount) * buttonWidth + CGFloat(buttonsCount - 1) * spacing
        
        print("日期滚动视图内容尺寸: 宽度=\(totalWidth)")
        dateScrollView.contentSize = CGSize(width: totalWidth, height: dateScrollView.frame.height)
        
        // 仅在初始设置时滚动到当前日期
        // viewDidLayoutSubviews会多次调用，如果每次都设置位置会导致滚动问题
        if !self.initialScrollDone {
            if currentDateIndex >= 0 && currentDateIndex < dateStackView.arrangedSubviews.count {
                // 使用延迟执行确保布局已完成
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    guard let self = self else { return }
                    print("执行初始滚动到当前日期")
                    self.scrollToDate(at: self.currentDateIndex)
                    self.initialScrollDone = true
                }
            } else {
                print("错误: currentDateIndex (\(currentDateIndex)) 超出范围 (0..\(dateStackView.arrangedSubviews.count-1))")
                self.initialScrollDone = true
            }
        }
        
        // 打印日期滚动视图的一些属性
        print("日期滚动视图frame: \(dateScrollView.frame)")
        print("日期滚动视图contentSize: \(dateScrollView.contentSize)")
        print("日期滚动视图contentOffset: \(dateScrollView.contentOffset)")
    }
    
    private func scrollToDate(at index: Int) {
        print("滚动到日期索引: \(index)")
        guard index >= 0 && index < dateStackView.arrangedSubviews.count else {
            print("无效的索引: \(index)")
            return
        }
        
        // 重要：强制布局刷新，确保所有视图都已经有了正确的frame
        dateScrollView.layoutIfNeeded()
        dateStackView.layoutIfNeeded()
        
        let button = dateStackView.arrangedSubviews[index]
        let buttonCenter = button.center
        let buttonFrameInStackView = button.frame
        
        // 计算按钮在滚动视图中的位置
        // 注意：button.convert可能不准确，特别是在layoutSubviews还没完成时
        // 使用按钮在堆栈视图中的位置加上堆栈视图的偏移量
        let buttonX = buttonFrameInStackView.origin.x + dateStackView.frame.origin.x
        
        // 计算目标位置：让按钮居中
        let screenWidth = dateScrollView.bounds.width
        let targetX = buttonX - (screenWidth - buttonFrameInStackView.width) / 2
        
        // 确保滚动范围在有效区域内
        let minX: CGFloat = 0
        let maxX = max(0, dateScrollView.contentSize.width - screenWidth)
        let safeX = min(max(targetX, minX), maxX)
        
        print("====== 滚动详情日志 ======")
        print("按钮在堆栈视图中的位置: x=\(buttonFrameInStackView.origin.x), width=\(buttonFrameInStackView.width)")
        print("堆栈视图在滚动视图中的位置: x=\(dateStackView.frame.origin.x)")
        print("计算的按钮在滚动视图中的位置: x=\(buttonX)")
        print("屏幕宽度: \(screenWidth)")
        print("目标滚动位置: \(targetX), 安全滚动位置: \(safeX)")
        print("当前滚动位置: \(dateScrollView.contentOffset.x)")
        print("滚动视图内容大小: \(dateScrollView.contentSize.width)")
        
        // 使用动画滚动到目标位置
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            self?.dateScrollView.contentOffset = CGPoint(x: safeX, y: 0)
        }, completion: { [weak self] finished in
            // 确认滚动已完成，并记录新位置
            print("滚动动画完成: \(finished)")
            print("滚动后的位置: \(self?.dateScrollView.contentOffset.x ?? 0)")
        })
    }

    private func updateSelectedDate(_ date: Date) {
        print("更新选中日期: \(dateFormatter.string(from: date))")
        
        // 更新选中日期
        selectedDate = date
        
        // 找到对应的索引
        let calendar = Calendar.current
        var selectedIndex = -1
        
        for (index, visibleDate) in visibleDates.enumerated() {
            if calendar.isDate(visibleDate, inSameDayAs: date) {
                selectedIndex = index
                break
            }
        }
        
        // 更新按钮状态
        updateDateButtonsState(for: date)
        
        // 如果找到了索引，确保它在屏幕中间
        if selectedIndex >= 0 {
            // 延迟调用滚动，确保UI更新完成
            DispatchQueue.main.async { [weak self] in
                self?.scrollToDate(at: selectedIndex)
            }
        }
        
        // 加载数据
        loadDietRecords(for: date)
    }
    
    private func updateDateButtonsState(for date: Date) {
        // 更新选中状态
        selectedDate = date
        
        let calendar = Calendar.current
        for (index, subview) in dateStackView.arrangedSubviews.enumerated() {
            if let button = subview as? UIButton {
                let buttonDate = visibleDates[index]
                let isSelected = calendar.isDate(buttonDate, inSameDayAs: date)
                
                // 更新按钮外观
                button.backgroundColor = isSelected ? UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1.0) : .white
                
                // 更新按钮标题的颜色
                if let attributedTitle = button.attributedTitle(for: .normal) {
                    let mutableTitle = NSMutableAttributedString(attributedString: attributedTitle)
                    let textColor = isSelected ? UIColor.white : UIColor.black
                    let monthColor = isSelected ? UIColor.white.withAlphaComponent(0.8) : UIColor.gray
                    
                    // 更新日期颜色
                    mutableTitle.addAttribute(.foregroundColor, value: textColor, range: NSRange(location: 0, length: attributedTitle.length))
                    
                    // 如果有月份标签，单独更新它的颜色
                    let string = attributedTitle.string
                    if let range = string.range(of: "\n.*月", options: .regularExpression) {
                        let nsRange = NSRange(range, in: string)
                        mutableTitle.addAttribute(.foregroundColor, value: monthColor, range: nsRange)
                    }
                    
                    button.setAttributedTitle(mutableTitle, for: .normal)
                }
            }
        }
    }
    
    private func loadMoreDates(direction: LoadDirection) {
        print("加载更多日期: \(direction)")
        let calendar = Calendar.current
        
        switch direction {
        case .past:
            // 加载更早的日期
            if let firstDate = visibleDates.first {
                // 添加10天前的日期
                for i in (1...10).reversed() {
                    if let date = calendar.date(byAdding: .day, value: -i, to: firstDate) {
                        visibleDates.insert(date, at: 0)
                    }
                }
                currentDateIndex += 10  // 更新当前选中日期索引
                print("加载10天之前的日期，当前总日期数: \(visibleDates.count)")
                
                // 更新界面
                updateVisibleDateButtons()
            }
            
        case .future:
            // 加载更晚的日期
            if let lastDate = visibleDates.last {
                // 添加10天后的日期
                for i in 1...10 {
                    if let date = calendar.date(byAdding: .day, value: i, to: lastDate) {
                        visibleDates.append(date)
                    }
                }
                print("加载10天之后的日期，当前总日期数: \(visibleDates.count)")
                
                // 更新界面
                updateVisibleDateButtons()
            }
        }
        
        // 重新配置滚动视图
        configureDateScrollView()
    }
    
    private func checkLoginStatus() {
        print("检查登录状态")
        // 判断用户是否已登录，使用全局登录状态
        if !User.isTokenValid() {
            print("用户未登录，显示登录提示")
            // 显示登录提示
            showLoginAlert()
        } else {
            print("用户已登录，加载饮食记录")
            // 已登录，加载数据
            loadDietRecords(for: selectedDate)
        }
    }
    
    private func showLoginAlert() {
        print("显示登录提示")
        let alert = UIAlertController(
            title: "需要登录",
            message: "查看饮食记录需要先登录账号。",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "去登录", style: .default, handler: { [weak self] _ in
            self?.navigateToLogin()
        }))
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { [weak self] _ in
            // 返回到上一个标签页
            if let tabBarController = self?.tabBarController {
                tabBarController.selectedIndex = 0
            }
        }))
        
        present(alert, animated: true)
    }
    
    private func navigateToLogin() {
        print("导航到登录页面")
        // 显示侧边栏（假设登录是在侧边栏中）
        if let tabBarController = self.tabBarController,
           let sideMenuDelegate = tabBarController as? NavigationBarDelegate {
            sideMenuDelegate.didTapAvatarButton()
        }
    }
}

// MARK: - 按钮点击事件

extension DietViewController {
    @objc private func dateButtonTapped(_ sender: UIButton) {
        print("按钮被点击: \(sender.tag)")
        
        // 获取点击的日期
        let selectedIndex = sender.tag
        if selectedIndex >= 0 && selectedIndex < visibleDates.count {
            let selectedDate = visibleDates[selectedIndex]
            
            // 先更新UI状态
            updateDateButtonsState(for: selectedDate)
            
            // 滚动到所选日期 - 添加延迟确保按钮状态更新后再滚动
            DispatchQueue.main.async { [weak self] in
                self?.scrollToDate(at: selectedIndex)
            }
            
            // 加载数据
            loadDietRecords(for: selectedDate)
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension DietViewController: UITableViewDataSource, UITableViewDelegate {
    // 返回分组数量
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4 // 早餐、午餐、晚餐、零食
    }
    
    // 返回每组行数
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let mealType = section + 1
        let mealRecords = dietRecords.filter { $0.mealType == mealType }
        
        // 如果没有记录，返回0行
        if mealRecords.isEmpty {
            return 0
        }
        
        // 计算这个餐类型下的食物总数
        return mealRecords.reduce(0) { $0 + $1.foods.count }
    }
    
    // 设置单元格
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FoodItemCell.identifier, for: indexPath) as! FoodItemCell
        
        // 获取对应餐类型的记录
        let mealType = indexPath.section + 1
        let mealRecords = dietRecords.filter { $0.mealType == mealType }
        
        // 找到对应的食物项
        var foodIndex = indexPath.row
        var recordIndex = 0
        
        while recordIndex < mealRecords.count {
            let record = mealRecords[recordIndex]
            if foodIndex < record.foods.count {
                let foodItem = record.foods[foodIndex]
                cell.configure(with: foodItem, in: record)
                cell.delegate = self
                return cell
            }
            
            foodIndex -= record.foods.count
            recordIndex += 1
        }
        
        return cell
    }
    
    // 返回组头视图
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let mealType = section + 1
        let mealRecords = dietRecords.filter { $0.mealType == mealType }
        
        // 创建组头视图
        let headerView = UIView()
        headerView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        
        // 添加标题标签
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .black
        
        // 设置标题文本
        switch mealType {
        case 1: titleLabel.text = "早餐"
        case 2: titleLabel.text = "午餐"
        case 3: titleLabel.text = "晚餐"
        case 4: titleLabel.text = "零食"
        default: titleLabel.text = "其他"
        }
        
        // 添加提示标签（当没有数据时）
        let emptyLabel = UILabel()
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.font = UIFont.systemFont(ofSize: 14)
        emptyLabel.textColor = .gray
        emptyLabel.text = mealRecords.isEmpty || mealRecords.allSatisfy { $0.foods.isEmpty } ? "没有记录" : ""
        
        // 添加子视图
        headerView.addSubview(titleLabel)
        headerView.addSubview(emptyLabel)
        
        // 设置约束
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 12),
            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -12),
            
            emptyLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            emptyLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: headerView.trailingAnchor, constant: -16)
        ])
        
        return headerView
    }
    
    // 返回组头高度
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
}

// MARK: - FoodItemCellDelegate

extension DietViewController: FoodItemCellDelegate {
    func didTapDeleteButton(for foodItem: FoodItem, in record: DietRecord) {
        // 显示确认对话框
        let alert = UIAlertController(
            title: "删除食物",
            message: "确定要删除\(foodItem.name)吗？",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            self?.deleteFoodItem(for: foodItem, in: record)
        })
        
        present(alert, animated: true)
    }
    
    func didAddFoodRecord() {
        // 刷新当前日期的饮食记录
        loadDietRecords(for: selectedDate)
    }
}

extension DietViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 滚动到边缘时加载更多日期
        if scrollView.contentOffset.x + scrollView.bounds.width >= scrollView.contentSize.width * 0.8 {
            loadMoreDates(direction: .future)
        } else if scrollView.contentOffset.x <= scrollView.bounds.width * 0.2 {
            loadMoreDates(direction: .past)
        }
    }
}

extension DietViewController {
    private func deleteFoodItem(for foodItem: FoodItem, in record: DietRecord) {
        print("删除食物项: 记录ID=\(record.id), 食物项ID=\(foodItem.id)")
        guard User.isTokenValid() else {
            print("用户未登录，中止删除")
            showLoginAlert()
            return
        }
        
        // 显示加载指示器
        loadingIndicator.startAnimating()
        
        // 调用API删除食物项
        DietAPI.shared.deleteFoodItem(recordId: record.id, foodItemId: foodItem.id) { [weak self] result in
            guard let self = self else { return }
            
            // 停止加载指示器
            self.loadingIndicator.stopAnimating()
            
            switch result {
            case .success(let updatedRecords):
                // 更新数据
                self.dietRecords = updatedRecords
                
                // 检查是否有数据
                let isEmpty = updatedRecords.isEmpty || updatedRecords.allSatisfy { $0.foods.isEmpty }
                self.emptyStateView.isHidden = !isEmpty
                self.tableView.isHidden = isEmpty
                
                // 刷新表格
                self.tableView.reloadData()
                
            case .failure(let error):
                // 显示错误提示
                let errorAlert = UIAlertController(
                    title: "错误",
                    message: "删除食物项失败: \(error.localizedDescription)",
                    preferredStyle: .alert
                )
                
                errorAlert.addAction(UIAlertAction(
                    title: "确定",
                    style: .default
                ))
                
                self.present(errorAlert, animated: true)
            }
        }
    }
}

extension DietViewController {
    private func loadDietRecords(for date: Date = Date()) {
        // 设置当前选中日期
        selectedDate = date
        
        print("============= 开始加载饮食记录 =============")
        print("当前用户登录状态: \(User.isTokenValid() ? "已登录" : "未登录")")
        
        guard User.isTokenValid() else {
            print("未登录，无法加载饮食记录")
            showLoginAlert()
            return
        }
        
        // 显示加载中
        isLoading = true
        tableView.isHidden = true
        emptyStateView.isHidden = true
        loadingIndicator.startAnimating()
        
        // 格式化日期
        let dateString = dateFormatter.string(from: selectedDate)
        
        // 调用API获取数据
        DietAPI.shared.fetchDietRecords(date: dateString) { [weak self] result in
            guard let self = self else { return }
            
            self.isLoading = false
            self.loadingIndicator.stopAnimating()
            
            switch result {
            case .success(let records):
                print("成功加载\(records.count)条记录")
                
                // 更新数据
                self.dietRecords = records
                
                // 按膳食类型分组
                self.reorganizeRecords()
                
                // 计算总卡路里并更新UI
                self.updateCalorieCounter()
                
                // 更新界面
                let isEmpty = records.isEmpty || records.allSatisfy { $0.foods.isEmpty }
                self.emptyStateView.isHidden = !isEmpty
                self.tableView.isHidden = isEmpty
                self.tableView.reloadData()
                
            case .failure(let error):
                print("加载饮食记录失败: \(error.localizedDescription)")
                
                // 显示错误状态
                self.emptyStateView.isHidden = false
                self.tableView.isHidden = true
                
                // 显示错误提示
                let errorAlert = UIAlertController(
                    title: "错误",
                    message: "加载饮食记录失败: \(error.localizedDescription)",
                    preferredStyle: .alert
                )
                
                errorAlert.addAction(UIAlertAction(
                    title: "确定",
                    style: .default
                ))
                
                self.present(errorAlert, animated: true)
            }
        }
    }
    
    // 按膳食类型重新组织记录
    private func reorganizeRecords() {
        // 创建四个餐类型的空数组（早餐、午餐、晚餐、零食）
        recordSections = [[], [], [], []]
        
        // 按餐类型分组记录
        for record in dietRecords {
            let mealTypeIndex = min(max(0, record.mealType - 1), 3)
            recordSections[mealTypeIndex].append(record)
        }
        
        // 打印分组情况
        print("重新组织记录完成:")
        print("- 早餐记录: \(recordSections[0].count)条")
        print("- 午餐记录: \(recordSections[1].count)条")
        print("- 晚餐记录: \(recordSections[2].count)条") 
        print("- 零食记录: \(recordSections[3].count)条")
    }
    
    // 计算总卡路里并更新UI
    private func updateCalorieCounter() {
        let totalCalories = calculateTotalCalories()
        
        // 更新标签
        calorieCounterLabel.text = "\(totalCalories)\nkcal"
        
        // 根据卡路里数量调整颜色
        let color = getColorForCalories(totalCalories)
        calorieCounterView.backgroundColor = color
    }
    
    // 计算总卡路里
    private func calculateTotalCalories() -> Int {
        var total = 0
        
        for record in dietRecords {
            for food in record.foods {
                total += food.calories
            }
        }
        
        return total
    }
    
    // 根据卡路里数量获取颜色
    private func getColorForCalories(_ calories: Int) -> UIColor {
        // 定义颜色范围
        let greenColor = UIColor(red: 76/255, green: 175/255, blue: 80/255, alpha: 1.0) // 绿色
        let redColor = UIColor(red: 255/255, green: 76/255, blue: 76/255, alpha: 1.0) // 红色
        
        // 计算颜色过渡比例（0-1）
        let maxCalories: CGFloat = 2000.0 // 2000卡路里时达到最红
        let ratio = min(CGFloat(calories) / maxCalories, 1.0)
        
        // 获取绿色的RGB分量
        var greenR: CGFloat = 0
        var greenG: CGFloat = 0
        var greenB: CGFloat = 0
        var greenA: CGFloat = 0
        greenColor.getRed(&greenR, green: &greenG, blue: &greenB, alpha: &greenA)
        
        // 获取红色的RGB分量
        var redR: CGFloat = 0
        var redG: CGFloat = 0
        var redB: CGFloat = 0
        var redA: CGFloat = 0
        redColor.getRed(&redR, green: &redG, blue: &redB, alpha: &redA)
        
        // 计算颜色插值
        let r = greenR + (redR - greenR) * ratio
        let g = greenG + (redG - greenG) * ratio
        let b = greenB + (redB - greenB) * ratio
        
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
    
    // 添加食物按钮点击事件
    @objc private func addFoodButtonTapped() {
        // 检查登录状态
        guard User.isTokenValid() else {
            showLoginAlert()
            return
        }
        
        // 创建添加食物视图控制器
        let addFoodVC = AddFoodViewController(date: selectedDate)
        addFoodVC.delegate = self
        
        // 创建导航控制器并显示
        let navController = UINavigationController(rootViewController: addFoodVC)
        present(navController, animated: true)
    }
}
