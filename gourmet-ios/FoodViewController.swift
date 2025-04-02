//
//  FoodViewController.swift
//  gourmet-ios
//
//  Created by Cascade on 2025/3/30.
//

import SwiftUI
import UIKit
import Alamofire
import Foundation
import gourmet_ios

// 食物详情视图控制器协议
protocol FoodDetailViewControllerProtocol {
    func configure(with foodId: Int)
}

// 导入 FoodCategory 模型
struct FoodCategoryResponse: Codable {
    let success: Bool
    let data: [FoodCategory]
    let request_id: String
}

struct FoodCategory: Codable {
    let id: Int
    let name: String
}

// 食物模型
struct Food: Codable {
    let id: Int
    let name: String
    let evaluation: String?
    let image_url: String?
    let standard_calories: Int
    let category: [FoodCategory]?
}

// 食物列表响应模型
struct FoodListResponse: Codable {
    let success: Bool
    let data: FoodListData
    let request_id: String
    
    struct FoodListData: Codable {
        let limit: Int
        let list: [Food]
        let page: Int
        let total: Int
    }
}

// 食物分类单元格
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

class FoodViewController: UIViewController {
    
    // MARK: - Properties
    
    private var categories: [FoodCategory] = []
    private var isLoading = false
    
    // MARK: - UI Components
    
    // 搜索栏
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "搜索食物..."
        searchBar.searchBarStyle = .minimal
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        return searchBar
    }()
    
    // 刷新控件
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        return refreshControl
    }()
    
    // 集合视图
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(FoodCategoryCell.self, forCellWithReuseIdentifier: FoodCategoryCell.reuseIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.refreshControl = refreshControl
        return collectionView
    }()
    
    // 加载指示器
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        
        // 只在第一次加载时获取数据
        if categories.isEmpty {
            fetchCategories()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 如果分类列表为空，则加载数据，但不显示加载指示器
        if categories.isEmpty && !isLoading {
            fetchCategories(showLoading: false)
        }
    }
    
    // MARK: - Setup
    
    private func setupView() {
        // 设置标题和背景色
        title = "食物"
        view.backgroundColor = .systemBackground
        
        // 添加子视图
        view.addSubview(searchBar)
        view.addSubview(collectionView)
        view.addSubview(activityIndicator)
        
        // 设置约束
        NSLayoutConstraint.activate([
            // 搜索栏约束
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // 集合视图约束
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // 加载指示器约束
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Data Fetching
    
    private func fetchCategories(showLoading: Bool = true) {
        guard !isLoading else { return }
        
        isLoading = true
        
        if showLoading {
            activityIndicator.startAnimating()
        }
        
        let url = "https://gourmet.pfcent.com/api/v1/foods/categories"
        let headers: HTTPHeaders = [
            "Accept": "*/*",
            "Connection": "keep-alive"
        ]
        
        AF.request(url, method: .get, headers: headers)
            .validate()
            .responseDecodable(of: FoodCategoryResponse.self) { [weak self] response in
                guard let self = self else { return }
                
                self.isLoading = false
                self.activityIndicator.stopAnimating()
                self.refreshControl.endRefreshing()
                
                switch response.result {
                case .success(let categoryResponse):
                    if categoryResponse.success {
                        self.categories = categoryResponse.data
                        self.collectionView.reloadData()
                    } else {
                        self.showError(message: "获取食物分类失败")
                    }
                    
                case .failure(let error):
                    print("Error fetching categories: \(error.localizedDescription)")
                    self.showError(message: "网络错误，请稍后重试")
                }
            }
    }
    
    @objc private func refreshData() {
        fetchCategories()
    }
    
    // MARK: - Helper Methods
    
    private func showError(message: String) {
        let alert = UIAlertController(title: "错误", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension FoodViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FoodCategoryCell.reuseIdentifier, for: indexPath) as? FoodCategoryCell else {
            return UICollectionViewCell()
        }
        
        let category = categories[indexPath.item]
        cell.configure(with: category)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        let category = categories[indexPath.item]
        let foodListVC = FoodListViewController(categoryId: category.id, categoryName: category.name)
        navigationController?.pushViewController(foodListVC, animated: true)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension FoodViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 48) / 2 // 两列，左右边距16，中间间距16
        return CGSize(width: width, height: width * 0.75) // 高度为宽度的0.75倍
    }
}

// MARK: - UISearchBarDelegate
extension FoodViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        guard let searchText = searchBar.text, !searchText.isEmpty else { return }
        
        // 创建搜索结果视图控制器
        let searchVC = FoodSearchViewController(keyword: searchText)
        navigationController?.pushViewController(searchVC, animated: true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // 当用户清空搜索栏时，显示取消按钮
        if searchText.isEmpty {
            searchBar.setShowsCancelButton(true, animated: true)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.text = ""
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
}

// 食物列表视图控制器
class FoodListViewController: UIViewController {
    
    // MARK: - Properties
    
    private let categoryId: Int
    private let categoryName: String
    
    private var foods: [Food] = []
    private var currentPage = 1
    private var totalPages = 1
    private var isLoading = false
    private var hasMoreData = true
    
    // MARK: - UI Components
    
    // 表格视图
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.register(FoodCell.self, forCellReuseIdentifier: "FoodCellIdentifier")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        return tableView
    }()
    
    // 加载指示器
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // 底部加载指示器
    private lazy var footerActivityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 50)
        return indicator
    }()
    
    // 无数据视图
    private lazy var emptyView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView(image: UIImage(named: "food_placeholder"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray3
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "没有找到食物"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(imageView)
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60),
            
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        return view
    }()
    
    // MARK: - Lifecycle
    
    init(categoryId: Int, categoryName: String) {
        self.categoryId = categoryId
        self.categoryName = categoryName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置标题
        title = categoryName
        
        // 设置视图
        view.backgroundColor = .systemBackground
        
        // 设置表格
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        view.addSubview(emptyView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            emptyView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 添加返回按钮
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        
        // 设置导航栏外观
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }
        
        // 设置额外的顶部安全区域边距，避免被自定义导航栏遮挡
        additionalSafeAreaInsets = UIEdgeInsets(top: 44, left: 0, bottom: 0, right: 0)
        
        // 添加下拉刷新
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        // 加载数据
        fetchFoods()
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func refreshData() {
        currentPage = 1
        hasMoreData = true
        foods.removeAll()
        tableView.reloadData()
        fetchFoods()
    }
    
    // MARK: - Data Fetching
    
    private func fetchFoods() {
        guard !isLoading && hasMoreData else { return }
        
        isLoading = true
        
        if foods.isEmpty {
            activityIndicator.startAnimating()
        } else {
            tableView.tableFooterView = footerActivityIndicator
            footerActivityIndicator.startAnimating()
        }
        
        let url = "https://gourmet.pfcent.com/api/v1/foods/category/\(categoryId)?page=\(currentPage)&limit=20"
        let headers: HTTPHeaders = [
            "Accept": "*/*",
            "Connection": "keep-alive"
        ]
        
        AF.request(url, method: .get, headers: headers)
            .validate()
            .responseDecodable(of: FoodListResponse.self) { [weak self] response in
                guard let self = self else { return }
                
                self.isLoading = false
                self.activityIndicator.stopAnimating()
                self.tableView.refreshControl?.endRefreshing()
                self.footerActivityIndicator.stopAnimating()
                self.tableView.tableFooterView = nil
                
                switch response.result {
                case .success(let foodListResponse):
                    if foodListResponse.success {
                        let newFoods = foodListResponse.data.list
                        
                        // 计算总页数
                        let total = foodListResponse.data.total
                        let limit = foodListResponse.data.limit
                        self.totalPages = (total + limit - 1) / limit
                        
                        // 检查是否还有更多数据
                        self.hasMoreData = self.currentPage < self.totalPages
                        
                        // 更新页码
                        self.currentPage += 1
                        
                        // 更新数据源
                        if self.currentPage == 2 {
                            self.foods = newFoods
                        } else {
                            self.foods.append(contentsOf: newFoods)
                        }
                        
                        // 更新 UI
                        self.tableView.reloadData()
                        self.emptyView.isHidden = !self.foods.isEmpty
                    } else {
                        self.showError(message: "获取食物列表失败")
                    }
                    
                case .failure(let error):
                    print("Error fetching foods: \(error.localizedDescription)")
                    self.showError(message: "网络错误，请稍后重试")
                }
            }
    }
    
    // MARK: - Helper Methods
    
    private func showError(message: String) {
        let alert = UIAlertController(title: "错误", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension FoodListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return foods.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FoodCellIdentifier", for: indexPath) as! FoodCell
        
        if indexPath.row < foods.count {
            let food = foods[indexPath.row]
            cell.configure(with: food)
            
            // 如果滚动到最后一行，加载更多数据
            if indexPath.row == foods.count - 1 && !isLoading && hasMoreData {
                fetchFoods()
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row < foods.count {
            let food = foods[indexPath.row]
            let foodDetailVC = FoodDetailViewControllerImpl()
            foodDetailVC.configure(with: food.id)
            navigationController?.pushViewController(foodDetailVC, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100 // 固定高度，也可以使用 UITableView.automaticDimension
    }
}

// 食物单元格
class FoodCell: UITableViewCell {
    static let reuseIdentifier = "FoodCellIdentifier"
    
    // 食物图片
    private let foodImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // 食物名称
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // 食物评价
    private let evaluationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // 分类标签
    private let categoryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .systemBlue
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // 热量标签
    private let caloriesLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = UIColor(red: 0.9, green: 0.4, blue: 0.4, alpha: 1.0)
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        // 添加子视图
        contentView.addSubview(foodImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(evaluationLabel)
        contentView.addSubview(categoryLabel)
        contentView.addSubview(caloriesLabel)
        
        // 设置约束
        NSLayoutConstraint.activate([
            // 食物图片约束
            foodImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            foodImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            foodImageView.widthAnchor.constraint(equalToConstant: 70),
            foodImageView.heightAnchor.constraint(equalToConstant: 70),
            
            // 食物名称约束
            nameLabel.leadingAnchor.constraint(equalTo: foodImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: caloriesLabel.leadingAnchor, constant: -12),
            
            // 食物评价约束
            evaluationLabel.leadingAnchor.constraint(equalTo: foodImageView.trailingAnchor, constant: 12),
            evaluationLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            evaluationLabel.trailingAnchor.constraint(equalTo: caloriesLabel.leadingAnchor, constant: -12),
            
            // 分类标签约束
            categoryLabel.leadingAnchor.constraint(equalTo: foodImageView.trailingAnchor, constant: 12),
            categoryLabel.topAnchor.constraint(equalTo: evaluationLabel.bottomAnchor, constant: 4),
            categoryLabel.trailingAnchor.constraint(equalTo: caloriesLabel.leadingAnchor, constant: -12),
            categoryLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),
            
            // 热量标签约束
            caloriesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            caloriesLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            caloriesLabel.widthAnchor.constraint(equalToConstant: 70)
        ])
    }
    
    func configure(with food: Food) {
        nameLabel.text = food.name
        evaluationLabel.text = food.evaluation?.trimmingCharacters(in: .whitespacesAndNewlines)
        caloriesLabel.text = "\(food.standard_calories) 大卡"
        
        // 设置默认图片
        foodImageView.image = UIImage(named: "food_placeholder")
        
        // 加载图片
        if let imageUrlString = food.image_url, let imageUrl = URL(string: imageUrlString) {
            // 这里应该使用图片加载库，如 SDWebImage 或 Kingfisher
            // 简单起见，我们使用系统的 URLSession
            URLSession.shared.dataTask(with: imageUrl) { [weak self] data, response, error in
                guard let self = self, let data = data, error == nil,
                      let image = UIImage(data: data) else {
                    return
                }
                
                DispatchQueue.main.async {
                    self.foodImageView.image = image
                }
            }.resume()
        }
        
        // 处理新分类结构
        if let categories = food.category, !categories.isEmpty {
            var categoryText = "分类: "
            for (index, category) in categories.enumerated() {
                categoryText += category.name
                if index < categories.count - 1 {
                    categoryText += ", "
                }
            }
            categoryLabel.text = categoryText
            categoryLabel.isHidden = false
        } else {
            categoryLabel.isHidden = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        foodImageView.image = nil
        nameLabel.text = nil
        evaluationLabel.text = nil
        categoryLabel.text = nil
        caloriesLabel.text = nil
    }
}

// 食物详情视图控制器
class FoodDetailViewControllerImpl: UIViewController, FoodDetailViewControllerProtocol {
    
    // MARK: - Properties
    
    private var foodId: Int = 0
    private var foodDetail: FoodDetail?
    private var selectedUnitInfo: FoodUnitInfo?
    private var customAmount: Double = 1.0
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置标题
        title = "食物详情"
        
        // 设置视图
        view.backgroundColor = .systemBackground
        
        // 设置导航栏
        navigationController?.navigationBar.prefersLargeTitles = false
        
        // 添加返回按钮
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        
        // 调整内容区域，避免被导航栏遮挡
        edgesForExtendedLayout = []
        
        // 加载数据
        fetchFoodDetail()
    }
    
    // MARK: - FoodDetailViewControllerProtocol
    
    func configure(with foodId: Int) {
        self.foodId = foodId
        if isViewLoaded {
            fetchFoodDetail()
        }
    }
    
    // MARK: - Data Fetching
    
    private func fetchFoodDetail() {
        let url = "https://gourmet.pfcent.com/api/v1/foods/\(foodId)"
        let headers: HTTPHeaders = [
            "Accept": "*/*",
            "Connection": "keep-alive"
        ]
        
        AF.request(url, method: .get, headers: headers)
            .validate()
            .responseDecodable(of: FoodDetailResponse.self) { [weak self] response in
                guard let self = self else { return }
                
                switch response.result {
                case .success(let foodDetailResponse):
                    if foodDetailResponse.success, let foodDetail = foodDetailResponse.data {
                        // 输出调试信息
                        print("获取食物详情成功: \(foodDetail.name)")
                        print("营养信息数量: \(foodDetail.nutrition?.count ?? 0)")
                        print("单位信息数量: \(foodDetail.food_unit_infos?.count ?? 0)")
                        
                        // 更新 UI
                        self.updateUI(with: foodDetail)
                    } else {
                        self.showError(message: "获取食物详情失败")
                    }
                    
                case .failure(let error):
                    print("Error fetching food detail: \(error.localizedDescription)")
                    self.showError(message: "网络错误，请稍后重试")
                }
            }
    }
    
    // MARK: - Helper Methods
    
    private func updateUI(with foodDetail: FoodDetail) {
        // 更新 UI
        DispatchQueue.main.async {
            // 保存食物详情
            self.foodDetail = foodDetail
            
            // 清除之前的视图
            for subview in self.view.subviews {
                if subview is UIScrollView {
                    subview.removeFromSuperview()
                }
            }
            
            // 设置标题
            self.title = foodDetail.name
            
            // 创建滚动视图
            let scrollView = UIScrollView(frame: self.view.bounds)
            scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.view.addSubview(scrollView)
            
            // 获取安全区域
            let safeAreaInsets = self.view.safeAreaInsets
            
            // 创建内容视图
            let contentView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 1000))
            scrollView.addSubview(contentView)
            
            var lastView: UIView?
            var yOffset: CGFloat = safeAreaInsets.top + 16 // 考虑顶部安全区域
            
            // 添加基本信息
            let nameLabel = UILabel(frame: CGRect(x: 16, y: yOffset, width: contentView.bounds.width - 132, height: 30))
            nameLabel.font = UIFont.boldSystemFont(ofSize: 20)
            nameLabel.text = foodDetail.name
            contentView.addSubview(nameLabel)
            lastView = nameLabel
            
            // 添加返回箭头按钮
            let backButton = UIButton(type: .system)
            backButton.frame = CGRect(x: 16, y: yOffset - 5, width: 30, height: 30)
            backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
            backButton.tintColor = .systemBlue
            backButton.addTarget(self, action: #selector(self.backButtonTapped), for: .touchUpInside)
            contentView.addSubview(backButton)
            
            // 调整名称标签位置，为返回箭头腾出空间
            nameLabel.frame = CGRect(x: 50, y: yOffset, width: contentView.bounds.width - 166, height: 30)
            
            // 加载图片
            let imageView = UIImageView(frame: CGRect(x: contentView.bounds.width - 116, y: yOffset, width: 100, height: 100))
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 8
            imageView.backgroundColor = .lightGray
            contentView.addSubview(imageView)
            
            if let imageUrlString = foodDetail.image_url, let imageUrl = URL(string: imageUrlString) {
                URLSession.shared.dataTask(with: imageUrl) { data, response, error in
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            imageView.image = image
                        }
                    }
                }.resume()
            }
            
            yOffset = nameLabel.frame.maxY + 8
            
            // 评价文本可能很长，需要动态计算高度
            let evaluationLabel = UILabel(frame: CGRect(x: 16, y: yOffset, width: contentView.bounds.width - 132, height: 0))
            evaluationLabel.font = UIFont.systemFont(ofSize: 14)
            evaluationLabel.textColor = .gray
            evaluationLabel.numberOfLines = 0
            evaluationLabel.text = foodDetail.evaluation
            evaluationLabel.sizeToFit()
            evaluationLabel.frame = CGRect(x: 16, y: yOffset, width: contentView.bounds.width - 132, height: evaluationLabel.frame.height)
            contentView.addSubview(evaluationLabel)
            lastView = evaluationLabel
            
            yOffset = max(evaluationLabel.frame.maxY, imageView.frame.maxY) + 16
            
            // 添加热量标签
            let caloriesLabel = UILabel(frame: CGRect(x: 16, y: yOffset, width: contentView.bounds.width - 32, height: 30))
            caloriesLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            caloriesLabel.textColor = .systemRed
            caloriesLabel.text = "标准热量: \(foodDetail.standard_calories) 大卡"
            contentView.addSubview(caloriesLabel)
            lastView = caloriesLabel
            
            yOffset = caloriesLabel.frame.maxY + 16
            
            // 添加分类信息
            if let categories = foodDetail.category, !categories.isEmpty {
                let sectionLabel = UILabel(frame: CGRect(x: 16, y: yOffset, width: contentView.bounds.width - 32, height: 30))
                sectionLabel.font = UIFont.boldSystemFont(ofSize: 18)
                sectionLabel.text = "分类"
                contentView.addSubview(sectionLabel)
                
                yOffset = sectionLabel.frame.maxY + 8
                
                // 创建分类标签
                var categoryXOffset: CGFloat = 16
                for category in categories {
                    let categoryButton = UIButton(type: .system)
                    categoryButton.setTitle(category.name, for: .normal)
                    categoryButton.backgroundColor = .systemBlue
                    categoryButton.setTitleColor(.white, for: .normal)
                    categoryButton.layer.cornerRadius = 15
                    categoryButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
                    categoryButton.sizeToFit()
                    
                    let buttonWidth = categoryButton.frame.width + 20
                    let buttonHeight: CGFloat = 30
                    
                    if categoryXOffset + buttonWidth > contentView.bounds.width - 16 {
                        categoryXOffset = 16
                        yOffset += buttonHeight + 8
                    }
                    
                    categoryButton.frame = CGRect(x: categoryXOffset, y: yOffset, width: buttonWidth, height: buttonHeight)
                    categoryButton.tag = category.id
                    categoryButton.addTarget(self, action: #selector(self.categoryButtonTapped(_:)), for: .touchUpInside)
                    contentView.addSubview(categoryButton)
                    
                    categoryXOffset += buttonWidth + 8
                }
                
                yOffset += 38
            }
            
            // 添加营养信息
            if let nutritionItems = foodDetail.nutrition, !nutritionItems.isEmpty {
                let sectionLabel = UILabel(frame: CGRect(x: 16, y: yOffset, width: contentView.bounds.width - 32, height: 30))
                sectionLabel.font = UIFont.boldSystemFont(ofSize: 18)
                sectionLabel.text = "营养信息"
                contentView.addSubview(sectionLabel)
                
                yOffset = sectionLabel.frame.maxY + 8
                
                let itemsPerRow = 2
                let rowCount = (nutritionItems.count + itemsPerRow - 1) / itemsPerRow
                let rowHeight: CGFloat = 44
                let tableHeight = CGFloat(rowCount) * rowHeight
                let tableView = UITableView(frame: CGRect(x: 16, y: yOffset, width: contentView.bounds.width - 32, height: tableHeight))
                tableView.isScrollEnabled = false
                tableView.rowHeight = rowHeight
                tableView.layer.borderColor = UIColor.lightGray.cgColor
                tableView.layer.borderWidth = 0.5
                tableView.layer.cornerRadius = 8
                tableView.clipsToBounds = true
                
                // 设置表格数据
                tableView.dataSource = self
                tableView.delegate = self
                tableView.register(UITableViewCell.self, forCellReuseIdentifier: "NutritionCellIdentifier")
                tableView.tag = 100 // 用于标识营养表格
                tableView.reloadData()
                
                contentView.addSubview(tableView)
                
                yOffset = tableView.frame.maxY + 16
            }
            
            // 添加单位信息
            if let unitInfos = foodDetail.food_unit_infos, !unitInfos.isEmpty {
                let sectionLabel = UILabel(frame: CGRect(x: 16, y: yOffset, width: contentView.bounds.width - 32, height: 30))
                sectionLabel.font = UIFont.boldSystemFont(ofSize: 18)
                sectionLabel.text = "单位信息"
                contentView.addSubview(sectionLabel)
                
                yOffset = sectionLabel.frame.maxY + 8
                
                // 添加计算器
                let calculatorView = UIView(frame: CGRect(x: 16, y: yOffset, width: contentView.bounds.width - 32, height: 50))
                calculatorView.backgroundColor = .systemGray6
                calculatorView.layer.cornerRadius = 8
                contentView.addSubview(calculatorView)
                
                // 添加标签
                let amountLabel = UILabel(frame: CGRect(x: 10, y: 15, width: 60, height: 20))
                amountLabel.text = "数量:"
                amountLabel.font = UIFont.systemFont(ofSize: 14)
                calculatorView.addSubview(amountLabel)
                
                // 添加输入框
                let amountTextField = UITextField(frame: CGRect(x: 70, y: 10, width: 60, height: 30))
                amountTextField.borderStyle = .roundedRect
                amountTextField.keyboardType = .decimalPad
                amountTextField.text = "1.0"
                amountTextField.font = UIFont.systemFont(ofSize: 14)
                amountTextField.tag = 300 // 用于标识数量输入框
                amountTextField.addTarget(self, action: #selector(self.amountTextFieldChanged(_:)), for: .editingChanged)
                calculatorView.addSubview(amountTextField)
                
                // 添加单位选择器
                let unitButton = UIButton(type: .system)
                unitButton.frame = CGRect(x: 140, y: 10, width: 80, height: 30)
                unitButton.setTitle(unitInfos[0].unit.isEmpty ? "份" : unitInfos[0].unit, for: .normal)
                unitButton.backgroundColor = .systemBlue
                unitButton.setTitleColor(.white, for: .normal)
                unitButton.layer.cornerRadius = 5
                unitButton.tag = 301 // 用于标识单位按钮
                unitButton.addTarget(self, action: #selector(self.unitButtonTapped(_:)), for: .touchUpInside)
                calculatorView.addSubview(unitButton)
                
                // 添加热量显示
                let caloriesResultLabel = UILabel(frame: CGRect(x: 230, y: 15, width: calculatorView.bounds.width - 240, height: 20))
                caloriesResultLabel.textAlignment = .right
                caloriesResultLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
                caloriesResultLabel.textColor = .systemRed
                caloriesResultLabel.text = "\(unitInfos[0].calories) \(unitInfos[0].calories_unit)"
                caloriesResultLabel.tag = 302 // 用于标识热量结果标签
                calculatorView.addSubview(caloriesResultLabel)
                
                yOffset = calculatorView.frame.maxY + 8
                
                // 保存第一个单位信息用于计算
                self.selectedUnitInfo = unitInfos[0]
                self.customAmount = 1.0
                
                // 创建表格
                let rowHeight: CGFloat = 60
                let tableHeight = CGFloat(unitInfos.count) * rowHeight
                let tableView = UITableView(frame: CGRect(x: 16, y: yOffset, width: contentView.bounds.width - 32, height: tableHeight))
                tableView.isScrollEnabled = false
                tableView.rowHeight = rowHeight
                tableView.layer.borderColor = UIColor.lightGray.cgColor
                tableView.layer.borderWidth = 0.5
                tableView.layer.cornerRadius = 8
                tableView.clipsToBounds = true
                
                // 设置表格数据
                tableView.dataSource = self
                tableView.delegate = self
                tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UnitInfoCellIdentifier")
                tableView.tag = 200 // 用于标识单位表格
                tableView.reloadData()
                
                contentView.addSubview(tableView)
                
                yOffset = tableView.frame.maxY + 16
            }
            
            // 添加食材信息
            if let materialInfos = foodDetail.material_infos, 
               (materialInfos.major?.isEmpty == false || materialInfos.seasoning?.isEmpty == false) {
                let sectionLabel = UILabel(frame: CGRect(x: 16, y: yOffset, width: contentView.bounds.width - 32, height: 30))
                sectionLabel.font = UIFont.boldSystemFont(ofSize: 18)
                sectionLabel.text = "食材"
                contentView.addSubview(sectionLabel)
                
                yOffset = sectionLabel.frame.maxY + 8
                
                // 主料
                if let majorItems = materialInfos.major, !majorItems.isEmpty {
                    let majorLabel = UILabel(frame: CGRect(x: 16, y: yOffset, width: contentView.bounds.width - 32, height: 25))
                    majorLabel.font = UIFont.boldSystemFont(ofSize: 16)
                    majorLabel.text = "主料"
                    contentView.addSubview(majorLabel)
                    
                    yOffset = majorLabel.frame.maxY + 4
                    
                    for (index, item) in majorItems.enumerated() {
                        let itemLabel = UILabel(frame: CGRect(x: 16, y: yOffset, width: contentView.bounds.width - 32, height: 20))
                        itemLabel.font = UIFont.systemFont(ofSize: 14)
                        itemLabel.text = "\(item.name): \(item.amount) \(item.unit)"
                        contentView.addSubview(itemLabel)
                        
                        yOffset = itemLabel.frame.maxY + 4
                    }
                    
                    yOffset += 8
                }
                
                // 调料
                if let seasoningItems = materialInfos.seasoning, !seasoningItems.isEmpty {
                    let seasoningLabel = UILabel(frame: CGRect(x: 16, y: yOffset, width: contentView.bounds.width - 32, height: 25))
                    seasoningLabel.font = UIFont.boldSystemFont(ofSize: 16)
                    seasoningLabel.text = "调料"
                    contentView.addSubview(seasoningLabel)
                    
                    yOffset = seasoningLabel.frame.maxY + 4
                    
                    for (index, item) in seasoningItems.enumerated() {
                        let itemLabel = UILabel(frame: CGRect(x: 16, y: yOffset, width: contentView.bounds.width - 32, height: 20))
                        itemLabel.font = UIFont.systemFont(ofSize: 14)
                        itemLabel.text = "\(item.name): \(item.amount) \(item.unit)"
                        contentView.addSubview(itemLabel)
                        
                        yOffset = itemLabel.frame.maxY + 4
                    }
                }
                
                yOffset += 8
            }
            
            // 添加制作步骤
            if let productions = foodDetail.productions, !productions.isEmpty {
                let sectionLabel = UILabel(frame: CGRect(x: 16, y: yOffset, width: contentView.bounds.width - 32, height: 30))
                sectionLabel.font = UIFont.boldSystemFont(ofSize: 18)
                sectionLabel.text = "制作步骤"
                contentView.addSubview(sectionLabel)
                
                yOffset = sectionLabel.frame.maxY + 8
                
                for step in productions.sorted(by: { $0.step < $1.step }) {
                    let stepLabel = UILabel(frame: CGRect(x: 16, y: yOffset, width: 30, height: 20))
                    stepLabel.font = UIFont.boldSystemFont(ofSize: 16)
                    stepLabel.text = "\(step.step)."
                    contentView.addSubview(stepLabel)
                    
                    let contentLabel = UILabel(frame: CGRect(x: 50, y: yOffset, width: contentView.bounds.width - 66, height: 0))
                    contentLabel.font = UIFont.systemFont(ofSize: 14)
                    contentLabel.numberOfLines = 0
                    contentLabel.text = step.content
                    contentLabel.sizeToFit()
                    contentLabel.frame = CGRect(x: 50, y: yOffset, width: contentView.bounds.width - 66, height: contentLabel.frame.height)
                    contentView.addSubview(contentLabel)
                    
                    yOffset = contentLabel.frame.maxY + 8
                }
                
                yOffset += 8
            }
            
            // 添加相关食物
            if let relations = foodDetail.relations, !relations.isEmpty {
                let sectionLabel = UILabel(frame: CGRect(x: 16, y: yOffset, width: contentView.bounds.width - 32, height: 30))
                sectionLabel.font = UIFont.boldSystemFont(ofSize: 18)
                sectionLabel.text = "相关食物"
                contentView.addSubview(sectionLabel)
                
                yOffset = sectionLabel.frame.maxY + 8
                
                // 创建水平滚动视图
                let scrollViewHeight: CGFloat = 150
                let horizontalScrollView = UIScrollView(frame: CGRect(x: 0, y: yOffset, width: contentView.bounds.width, height: scrollViewHeight))
                horizontalScrollView.showsHorizontalScrollIndicator = false
                horizontalScrollView.showsVerticalScrollIndicator = false
                contentView.addSubview(horizontalScrollView)
                
                var xOffset: CGFloat = 16
                let itemWidth: CGFloat = 120
                let itemHeight: CGFloat = scrollViewHeight
                
                for relatedFood in relations {
                    let foodView = UIView(frame: CGRect(x: xOffset, y: 0, width: itemWidth, height: itemHeight))
                    foodView.backgroundColor = .white
                    foodView.layer.cornerRadius = 8
                    foodView.layer.borderWidth = 0.5
                    foodView.layer.borderColor = UIColor.lightGray.cgColor
                    
                    // 添加图片
                    let imageView = UIImageView(frame: CGRect(x: 10, y: 10, width: itemWidth - 20, height: itemWidth - 20))
                    imageView.contentMode = .scaleAspectFill
                    imageView.clipsToBounds = true
                    imageView.layer.cornerRadius = 8
                    imageView.backgroundColor = .lightGray
                    foodView.addSubview(imageView)
                    
                    if let imageUrlString = relatedFood.image_url, let imageUrl = URL(string: imageUrlString) {
                        URLSession.shared.dataTask(with: imageUrl) { data, response, error in
                            if let data = data, let image = UIImage(data: data) {
                                DispatchQueue.main.async {
                                    imageView.image = image
                                }
                            }
                        }.resume()
                    }
                    
                    // 添加名称
                    let nameLabel = UILabel(frame: CGRect(x: 10, y: imageView.frame.maxY + 5, width: itemWidth - 20, height: 20))
                    nameLabel.font = UIFont.systemFont(ofSize: 14)
                    nameLabel.textAlignment = .center
                    nameLabel.text = relatedFood.name
                    foodView.addSubview(nameLabel)
                    
                    // 添加热量
                    let caloriesLabel = UILabel(frame: CGRect(x: 10, y: nameLabel.frame.maxY, width: itemWidth - 20, height: 20))
                    caloriesLabel.font = UIFont.systemFont(ofSize: 12)
                    caloriesLabel.textColor = .systemRed
                    caloriesLabel.textAlignment = .center
                    caloriesLabel.text = "\(relatedFood.standard_calories) 大卡"
                    foodView.addSubview(caloriesLabel)
                    
                    // 添加点击事件
                    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.relatedFoodTapped(_:)))
                    foodView.addGestureRecognizer(tapGesture)
                    foodView.tag = relatedFood.id
                    foodView.isUserInteractionEnabled = true
                    
                    horizontalScrollView.addSubview(foodView)
                    xOffset += itemWidth + 10
                }
                
                horizontalScrollView.contentSize = CGSize(width: xOffset, height: scrollViewHeight)
                
                yOffset = horizontalScrollView.frame.maxY + 16
            }
            
            // 更新内容视图高度
            contentView.frame.size.height = yOffset + safeAreaInsets.bottom
            scrollView.contentSize = contentView.frame.size
        }
    }
    
    @objc private func categoryButtonTapped(_ sender: UIButton) {
        // 处理分类按钮点击
        let categoryId = sender.tag
        let categoryName = sender.title(for: .normal) ?? "分类食物"
        print("分类按钮点击: \(categoryId), 名称: \(categoryName)")
        
        // 跳转到分类食物列表
        let foodListVC = FoodListViewController(categoryId: categoryId, categoryName: categoryName)
        navigationController?.pushViewController(foodListVC, animated: true)
    }
    
    @objc private func relatedFoodTapped(_ sender: UITapGestureRecognizer) {
        if let view = sender.view {
            let foodId = view.tag
            print("相关食物点击: \(foodId)")
            
            // 跳转到食物详情
            let foodDetailVC = FoodDetailViewControllerImpl()
            foodDetailVC.configure(with: foodId)
            navigationController?.pushViewController(foodDetailVC, animated: true)
        }
    }
    
    @objc private func amountTextFieldChanged(_ sender: UITextField) {
        guard let amountText = sender.text, let amount = Double(amountText) else { return }
        
        // 更新自定义数量
        self.customAmount = amount
        
        // 更新热量显示
        updateCaloriesDisplay()
    }
    
    @objc private func unitButtonTapped(_ sender: UIButton) {
        // 显示单位选择器
        guard let unitInfos = foodDetail?.food_unit_infos, !unitInfos.isEmpty else { return }
        
        let alertController = UIAlertController(title: "选择单位", message: nil, preferredStyle: .actionSheet)
        
        for unitInfo in unitInfos {
            let unitName = unitInfo.is_standard ? "每100g" : (unitInfo.unit.isEmpty ? "份" : unitInfo.unit)
            let action = UIAlertAction(title: unitName, style: .default) { [weak self] _ in
                guard let self = self else { return }
                
                // 更新选中的单位信息
                self.selectedUnitInfo = unitInfo
                
                // 更新单位按钮标题
                sender.setTitle(unitName, for: .normal)
                
                // 更新热量显示
                self.updateCaloriesDisplay()
            }
            alertController.addAction(action)
        }
        
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        present(alertController, animated: true)
    }
    
    private func updateCaloriesDisplay() {
        guard let selectedUnitInfo = self.selectedUnitInfo else { return }
        
        // 计算热量
        let calories = selectedUnitInfo.calories * self.customAmount
        
        // 更新热量显示
        if let caloriesLabel = view.viewWithTag(302) as? UILabel {
            caloriesLabel.text = "\(Int(calories)) \(selectedUnitInfo.calories_unit)"
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension FoodDetailViewControllerImpl: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.tag == 100 {
            // 营养信息表格 - 双列布局
            if let nutrition = foodDetail?.nutrition {
                let itemsPerRow = 2
                let rowCount = (nutrition.count + itemsPerRow - 1) / itemsPerRow
                print("营养信息表格行数: \(rowCount) (总项数: \(nutrition.count))")
                return rowCount
            }
            return 0
        } else if tableView.tag == 200 {
            // 单位信息表格
            let count = foodDetail?.food_unit_infos?.count ?? 0
            print("单位信息表格行数: \(count)")
            return count
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableView.tag == 100 ? "NutritionCellIdentifier" : "UnitInfoCellIdentifier", for: indexPath)
        
        if tableView.tag == 100 {
            // 营养信息表格
            if let nutrition = foodDetail?.nutrition, !nutrition.isEmpty {
                // 计算每行显示两个营养信息
                let totalItems = nutrition.count
                let itemsPerRow = 2
                let rowCount = (totalItems + itemsPerRow - 1) / itemsPerRow
                
                if indexPath.row < rowCount {
                    let leftIndex = indexPath.row * itemsPerRow
                    let rightIndex = min(leftIndex + 1, totalItems - 1)
                    
                    let leftItem = nutrition[leftIndex]
                    let leftText = "\(leftItem.name): \(leftItem.amount)\(leftItem.unit)"
                    
                    var cellText = leftText
                    
                    // 如果右侧有数据，添加右侧数据
                    if rightIndex != leftIndex && rightIndex < totalItems {
                        let rightItem = nutrition[rightIndex]
                        let rightText = "\(rightItem.name): \(rightItem.amount)\(rightItem.unit)"
                        
                        // 计算左侧文本宽度，确保右侧文本对齐
                        let leftWidth = (tableView.bounds.width - 32) / 2
                        let spaces = String(repeating: " ", count: max(0, 20 - leftText.count))
                        cellText = "\(leftText)\(spaces)\(rightText)"
                    }
                    
                    cell.textLabel?.text = cellText
                    cell.textLabel?.font = UIFont.systemFont(ofSize: 14)
                    cell.textLabel?.numberOfLines = 1
                    cell.textLabel?.adjustsFontSizeToFitWidth = true
                    cell.textLabel?.minimumScaleFactor = 0.8
                }
            }
        } else if tableView.tag == 200 {
            // 单位信息表格
            if let unitInfos = foodDetail?.food_unit_infos, indexPath.row < unitInfos.count {
                let unitInfo = unitInfos[indexPath.row]
                
                // 构建显示文本
                var displayText = ""
                
                if unitInfo.is_standard {
                    // 标准单位（每100g）
                    displayText = "每100g: \(unitInfo.calories)\(unitInfo.calories_unit) (总重量: \(unitInfo.total_weight)g, 可食部: \(unitInfo.edible_weight)g)"
                } else {
                    // 自定义单位
                    if unitInfo.unit.isEmpty {
                        displayText = "\(unitInfo.amount)份: \(unitInfo.calories)\(unitInfo.calories_unit) (总重量: \(unitInfo.total_weight)g, 可食部: \(unitInfo.edible_weight)g)"
                    } else {
                        displayText = "\(unitInfo.amount)\(unitInfo.unit): \(unitInfo.calories)\(unitInfo.calories_unit) (总重量: \(unitInfo.total_weight)g, 可食部: \(unitInfo.edible_weight)g)"
                    }
                }
                
                cell.textLabel?.text = displayText
                cell.textLabel?.font = UIFont.systemFont(ofSize: 14)
                cell.textLabel?.numberOfLines = 2
                cell.textLabel?.adjustsFontSizeToFitWidth = true
                cell.textLabel?.minimumScaleFactor = 0.8
                print("单位信息单元格: \(displayText)")
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView.tag == 100 {
            // 营养信息表格
            return 44
        } else if tableView.tag == 200 {
            // 单位信息表格
            return 60
        }
        return 44
    }
}

// MARK: - Helper Methods
extension FoodDetailViewControllerImpl {
    private func showError(message: String) {
        let alert = UIAlertController(title: "错误", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
}

struct FoodDetailResponse: Codable {
    let success: Bool
    let data: FoodDetail?
    let request_id: String
}

struct FoodDetail: Codable {
    let id: Int
    let name: String
    let evaluation: String?
    let image_url: String?
    let standard_calories: Int
    let category: [FoodCategory]?
    let material_infos: MaterialInfos?
    let nutrition: [NutritionInfo]?
    let productions: [ProductionStep]?
    let relations: [RelatedFood]?
    let food_unit_infos: [FoodUnitInfo]?
}

struct MaterialInfos: Codable {
    let major: [MaterialItem]?
    let seasoning: [MaterialItem]?
}

struct MaterialItem: Codable {
    let name: String
    let amount: String
    let unit: String
}

struct NutritionInfo: Codable {
    let name: String
    let amount: String
    let unit: String
}

struct ProductionStep: Codable {
    let food_id: Int
    let step: Int
    let content: String
}

struct RelatedFood: Codable {
    let id: Int
    let name: String
    let evaluation: String?
    let image_url: String?
    let standard_calories: Int
    let category: [FoodCategory]?
}

struct FoodUnitInfo: Codable {
    let food_id: Int
    let amount: Double
    let unit: String
    let total_weight: Double
    let edible_weight: Double
    let calories: Double
    let calories_unit: String
    let is_standard: Bool
}

// 食物搜索响应模型
struct FoodSearchResponse: Codable {
    let success: Bool
    let data: FoodSearchData
    let request_id: String
    
    struct FoodSearchData: Codable {
        let keyword: String
        let limit: Int
        let list: [Food]
        let page: Int
        let total: Int
    }
}

// 食物搜索结果视图控制器
class FoodSearchViewController: UIViewController {
    
    // MARK: - Properties
    
    private let keyword: String
    private var foods: [Food] = []
    private var currentPage = 1
    private var totalPages = 1
    private var isLoading = false
    private var hasMoreData = true
    
    // MARK: - UI Components
    
    // 表格视图
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.register(FoodCell.self, forCellReuseIdentifier: "FoodCellIdentifier")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        return tableView
    }()
    
    // 加载指示器
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    // 底部加载指示器
    private lazy var footerActivityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 50)
        return indicator
    }()
    
    // 无数据视图
    private lazy var emptyView: UIView = {
        let view = UIView()
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView(image: UIImage(named: "food_placeholder"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray3
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "没有找到相关食物"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(imageView)
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60),
            
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        return view
    }()
    
    // MARK: - Lifecycle
    
    init(keyword: String) {
        self.keyword = keyword
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置标题
        title = "搜索: \(keyword)"
        
        // 设置视图
        view.backgroundColor = .systemBackground
        
        // 设置表格
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        view.addSubview(emptyView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            emptyView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 添加返回按钮
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        
        // 设置导航栏外观
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }
        
        // 设置额外的顶部安全区域边距，避免被自定义导航栏遮挡
        additionalSafeAreaInsets = UIEdgeInsets(top: 44, left: 0, bottom: 0, right: 0)
        
        // 添加下拉刷新
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        // 加载数据
        fetchFoods()
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func refreshData() {
        currentPage = 1
        hasMoreData = true
        foods.removeAll()
        tableView.reloadData()
        fetchFoods()
    }
    
    // MARK: - Data Fetching
    
    private func fetchFoods() {
        guard !isLoading && hasMoreData else { return }
        
        isLoading = true
        
        if foods.isEmpty {
            activityIndicator.startAnimating()
        } else {
            tableView.tableFooterView = footerActivityIndicator
            footerActivityIndicator.startAnimating()
        }
        
        // 对关键词进行URL编码
        guard let encodedKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            showError(message: "搜索关键词无效")
            return
        }
        
        let url = "https://gourmet.pfcent.com/api/v1/foods/search?keyword=\(encodedKeyword)&page=\(currentPage)&limit=20"
        let headers: HTTPHeaders = [
            "Accept": "*/*",
            "Connection": "keep-alive",
            "User-Agent": "PostmanRuntime-ApipostRuntime/1.1.0"
        ]
        
        AF.request(url, method: .get, headers: headers)
            .validate()
            .responseDecodable(of: FoodSearchResponse.self) { [weak self] response in
                guard let self = self else { return }
                
                self.isLoading = false
                self.activityIndicator.stopAnimating()
                self.tableView.refreshControl?.endRefreshing()
                self.footerActivityIndicator.stopAnimating()
                self.tableView.tableFooterView = nil
                
                switch response.result {
                case .success(let searchResponse):
                    if searchResponse.success {
                        let newFoods = searchResponse.data.list
                        
                        // 计算总页数
                        let total = searchResponse.data.total
                        let limit = searchResponse.data.limit
                        self.totalPages = (total + limit - 1) / limit
                        
                        // 检查是否还有更多数据
                        self.hasMoreData = self.currentPage < self.totalPages
                        
                        // 更新页码
                        self.currentPage += 1
                        
                        // 更新数据源
                        if self.currentPage == 2 {
                            self.foods = newFoods
                        } else {
                            self.foods.append(contentsOf: newFoods)
                        }
                        
                        // 更新 UI
                        self.tableView.reloadData()
                        self.emptyView.isHidden = !self.foods.isEmpty
                    } else {
                        self.showError(message: "搜索食物失败")
                    }
                    
                case .failure(let error):
                    print("Error searching foods: \(error.localizedDescription)")
                    self.showError(message: "网络错误，请稍后重试")
                }
            }
    }
    
    // MARK: - Helper Methods
    
    private func showError(message: String) {
        let alert = UIAlertController(title: "错误", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension FoodSearchViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return foods.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FoodCell.reuseIdentifier, for: indexPath) as! FoodCell
        
        if indexPath.row < foods.count {
            let food = foods[indexPath.row]
            cell.configure(with: food)
            
            // 如果滚动到最后一行，加载更多数据
            if indexPath.row == foods.count - 1 && !isLoading && hasMoreData {
                fetchFoods()
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row < foods.count {
            let food = foods[indexPath.row]
            let foodDetailVC = FoodDetailViewControllerImpl()
            foodDetailVC.configure(with: food.id)
            navigationController?.pushViewController(foodDetailVC, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100 // 固定高度，也可以使用 UITableView.automaticDimension
    }
}
