import UIKit
import Foundation

protocol AddFoodViewControllerDelegate: AnyObject {
    func didAddFoodRecord()
}

class AddFoodViewController: UIViewController {
    
    // MARK: - 属性
    
    weak var delegate: AddFoodViewControllerDelegate?
    
    private var selectedDate: Date
    private var foods: [Food] = []
    private var selectedFood: Food?
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
        
        setupViews()
        setupConstraints()
    }
    
    // MARK: - 视图设置
    
    private func setupViews() {
        title = "添加食物"
        view.backgroundColor = .white
        
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
        tableView.register(FoodSearchCell.self, forCellReuseIdentifier: FoodSearchCell.identifier)
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
        FoodAPI.shared.createDietRecord(
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
        FoodAPI.shared.searchFoods(keyword: keyword) { [weak self] result in
            guard let self = self,
                  let data = result else {
                self.loadingIndicator.stopAnimating()
                return
            }
            
            // 停止加载指示器
            self.loadingIndicator.stopAnimating()
            
            switch data {
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
    
    private func selectFood(_ food: Food) {
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
    
    private func calculateCalories(for food: Food, amount: Double) -> Int {
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
        let cell = tableView.dequeueReusableCell(withIdentifier: FoodSearchCell.identifier, for: indexPath) as! FoodSearchCell
        let food = foods[indexPath.row]
        cell.configure(with: food)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let food = foods[indexPath.row]
        selectFood(food)
    }
}

// MARK: - 食物搜索单元格

class FoodSearchCell: UITableViewCell {
    static let identifier = "FoodSearchCell"
    
    private let foodImageView = UIImageView()
    private let nameLabel = UILabel()
    private let caloriesLabel = UILabel()
    private let categoryLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // 设置食物图片
        foodImageView.contentMode = .scaleAspectFit
        foodImageView.clipsToBounds = true
        foodImageView.layer.cornerRadius = 8
        foodImageView.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置名称标签
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置热量标签
        caloriesLabel.font = UIFont.systemFont(ofSize: 14)
        caloriesLabel.textColor = .darkGray
        caloriesLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置类别标签
        categoryLabel.font = UIFont.systemFont(ofSize: 12)
        categoryLabel.textColor = .gray
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加子视图
        contentView.addSubview(foodImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(caloriesLabel)
        contentView.addSubview(categoryLabel)
        
        // 设置约束
        NSLayoutConstraint.activate([
            foodImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            foodImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            foodImageView.widthAnchor.constraint(equalToConstant: 60),
            foodImageView.heightAnchor.constraint(equalToConstant: 60),
            
            nameLabel.leadingAnchor.constraint(equalTo: foodImageView.trailingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            caloriesLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            caloriesLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            
            categoryLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            categoryLabel.topAnchor.constraint(equalTo: caloriesLabel.bottomAnchor, constant: 4),
            categoryLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with food: Food) {
        nameLabel.text = food.name
        caloriesLabel.text = "热量: \(food.standardCalories) 千卡/100g"
        
        // 设置类别
        if let firstCategory = food.category.first {
            categoryLabel.text = firstCategory.name
        } else {
            categoryLabel.text = "未分类"
        }
        
        // 加载图片
        if !food.imageUrl.isEmpty {
            loadImage(from: food.imageUrl)
        } else {
            foodImageView.image = UIImage(systemName: "fork.knife")
            foodImageView.tintColor = .gray
        }
    }
    
    private func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else {
            foodImageView.image = UIImage(systemName: "fork.knife")
            foodImageView.tintColor = .gray
            return
        }
        
        // 使用URLSession加载图片
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil,
                  let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self.foodImageView.image = UIImage(systemName: "fork.knife")
                    self.foodImageView.tintColor = .gray
                }
                return
            }
            
            DispatchQueue.main.async {
                self.foodImageView.image = image
            }
        }.resume()
    }
}
