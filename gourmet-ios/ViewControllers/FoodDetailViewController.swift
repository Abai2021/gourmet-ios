import UIKit
import Alamofire

class FoodDetailViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, FoodDetailViewControllerProtocol {
    
    // MARK: - 属性
    
    private var foodId: Int = 0
    private var foodDetail: FoodDetail?
    private var selectedUnitInfo: FoodUnitInfo?
    private var customAmount: Double = 1.0
    private var isFavorite: Bool = false
    
    // MARK: - UI 组件
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .systemBackground
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        return view
    }()
    
    // 基本信息容器
    private lazy var basicInfoContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        return view
    }()
    
    // 营养信息标题
    private lazy var nutritionTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = .label
        label.text = "营养信息"
        return label
    }()
    
    // 营养信息容器
    private lazy var nutritionContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        return view
    }()
    
    // 营养信息表格视图
    private lazy var nutritionTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(NutritionCell.self, forCellReuseIdentifier: "NutritionCell")
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.backgroundColor = .systemBackground
        return tableView
    }()
    
    // 食物图片
    private lazy var foodImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray6
        imageView.image = UIImage(named: "food_placeholder")
        return imageView
    }()
    
    // 分类集合视图
    private lazy var categoryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(CategoryCell.self, forCellWithReuseIdentifier: "CategoryCellIdentifier")
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()
    
    // 相关食物集合视图
    private lazy var relationsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        layout.itemSize = CGSize(width: 150, height: 180)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(RelatedFoodCell.self, forCellWithReuseIdentifier: "RelatedFoodCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()

// MARK: - UITableViewDelegate, UITableViewDataSource

extension FoodDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == nutritionTableView {
            let count = foodDetail?.nutrition?.count ?? 0
            return (count + 1) / 2 // 双列显示，向上取整
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == nutritionTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NutritionCell", for: indexPath) as! NutritionCell
            
            if let nutrition = foodDetail?.nutrition {
                let leftIndex = indexPath.row * 2
                if leftIndex < nutrition.count {
                    let leftItem = nutrition[leftIndex]
                    cell.leftNameLabel.text = leftItem.name
                    cell.leftValueLabel.text = "\(leftItem.amount) \(leftItem.unit)"
                } else {
                    cell.leftNameLabel.text = ""
                    cell.leftValueLabel.text = ""
                }
                
                let rightIndex = leftIndex + 1
                if rightIndex < nutrition.count {
                    let rightItem = nutrition[rightIndex]
                    cell.rightNameLabel.text = rightItem.name
                    cell.rightValueLabel.text = "\(rightItem.amount) \(rightItem.unit)"
                } else {
                    cell.rightNameLabel.text = ""
                    cell.rightValueLabel.text = ""
                }
            }
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource

extension FoodDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == categoryCollectionView {
            return foodDetail?.category?.count ?? 0
        } else {
            // 相关食物集合视图
            return foodDetail?.relations?.count ?? 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == categoryCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCellIdentifier", for: indexPath) as! CategoryCell
            
            if let category = foodDetail?.category?[indexPath.item] {
                cell.configure(with: category)
            }
            
            return cell
        } else {
            // 相关食物集合视图
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RelatedFoodCell", for: indexPath) as? RelatedFoodCell else {
                return UICollectionViewCell()
            }
            
            if let relatedFood = foodDetail?.relations?[indexPath.item] {
                cell.configure(with: relatedFood)
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == categoryCollectionView {
            // 分类集合视图
            return CGSize(width: 100, height: 100)
        } else {
            // 相关食物集合视图
            return CGSize(width: 150, height: 180)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == categoryCollectionView {
            // 点击分类，跳转到分类食物列表
            if let category = foodDetail?.category?[indexPath.item] {
                let foodListVC = FoodListViewController(categoryId: category.id, categoryName: category.name)
                navigationController?.pushViewController(foodListVC, animated: true)
            }
        } else {
            // 点击相关食物，跳转到食物详情
            if let relatedFood = foodDetail?.relations?[indexPath.item] {
                let foodDetailVC = FoodDetailViewController(foodId: relatedFood.id)
                navigationController?.pushViewController(foodDetailVC, animated: true)
            }
        }
    }
}

// MARK: - UIPickerViewDelegate, UIPickerViewDataSource

extension FoodDetailViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return foodDetail?.food_unit_infos?.count ?? 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard let unitInfo = foodDetail?.food_unit_infos?[row] else { return nil }
        
        if unitInfo.is_standard {
            return "每100g"
        } else {
            return "\(unitInfo.amount) \(unitInfo.unit) (\(unitInfo.total_weight)g)"
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedUnitInfo = foodDetail?.food_unit_infos?[row]
        updateUnitInfo()
    }
}

// MARK: - UITextFieldDelegate

extension FoodDetailViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == customAmountTextField {
            customAmountChanged()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - 网络请求
    
    private func fetchFoodDetail() {
        activityIndicator.startAnimating()
        
        let url = "\(APIConst.baseURL)/api/v1/foods/\(foodId)"
        
        AF.request(url).responseDecodable(of: FoodDetailResponse.self) { [weak self] response in
            guard let self = self else { return }
            
            self.activityIndicator.stopAnimating()
            
            switch response.result {
            case .success(let foodDetailResponse):
                if foodDetailResponse.success, let foodDetail = foodDetailResponse.data {
                    self.foodDetail = foodDetail
                    self.updateUI()
                } else {
                    self.showError(foodDetailResponse.message ?? "获取食物详情失败")
                }
            case .failure(let error):
                self.showError(error.localizedDescription)
            }
        }
    }

// MARK: - 自定义单元格

// 营养信息单元格
class NutritionCell: UITableViewCell {
    
    private let leftNameLabel = UILabel()
    private let leftValueLabel = UILabel()
    private let rightNameLabel = UILabel()
    private let rightValueLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        
        // 设置标签
        leftNameLabel.font = UIFont.systemFont(ofSize: 14)
        leftNameLabel.textColor = .label
        leftNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        leftValueLabel.font = UIFont.systemFont(ofSize: 14)
        leftValueLabel.textColor = .secondaryLabel
        leftValueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        rightNameLabel.font = UIFont.systemFont(ofSize: 14)
        rightNameLabel.textColor = .label
        rightNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        rightValueLabel.font = UIFont.systemFont(ofSize: 14)
        rightValueLabel.textColor = .secondaryLabel
        rightValueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加标签
        contentView.addSubview(leftNameLabel)
        contentView.addSubview(leftValueLabel)
        contentView.addSubview(rightNameLabel)
        contentView.addSubview(rightValueLabel)
        
        // 设置约束
        NSLayoutConstraint.activate([
            leftNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            leftNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            leftValueLabel.leadingAnchor.constraint(equalTo: leftNameLabel.trailingAnchor, constant: 8),
            leftValueLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            rightNameLabel.leadingAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 16),
            rightNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            rightValueLabel.leadingAnchor.constraint(equalTo: rightNameLabel.trailingAnchor, constant: 8),
            rightValueLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureLeft(name: String, value: String) {
        leftNameLabel.text = name
        leftValueLabel.text = value
    }
    
    func configureRight(name: String, value: String) {
        rightNameLabel.text = name
        rightValueLabel.text = value
    }
    
    func clearRight() {
        rightNameLabel.text = ""
        rightValueLabel.text = ""
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        leftNameLabel.text = ""
        leftValueLabel.text = ""
        rightNameLabel.text = ""
        rightValueLabel.text = ""
    }
}

// 相关食物单元格
class RelatedFoodCell: UICollectionViewCell {
    
    private let imageView = UIImageView()
    private let nameLabel = UILabel()
    private let caloriesLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // 设置视图
        contentView.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = 0.5
        contentView.layer.borderColor = UIColor.systemGray4.cgColor
        
        // 设置图片视图
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray6
        imageView.image = UIImage(named: "food_placeholder")
        
        // 设置名称标签
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 2
        
        // 设置热量标签
        caloriesLabel.translatesAutoresizingMaskIntoConstraints = false
        caloriesLabel.font = UIFont.systemFont(ofSize: 12)
        caloriesLabel.textColor = .systemRed
        caloriesLabel.textAlignment = .center
        
        // 添加子视图
        contentView.addSubview(imageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(caloriesLabel)
        
        // 设置约束
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            
            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            
            caloriesLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            caloriesLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            caloriesLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            caloriesLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with food: RelatedFood) {
        nameLabel.text = food.name
        caloriesLabel.text = "\(food.standard_calories) 大卡"
        
        // 加载图片
        if let imageUrlString = food.image_url, let imageUrl = URL(string: imageUrlString) {
            URLSession.shared.dataTask(with: imageUrl) { [weak self] data, response, error in
                guard let self = self, let data = data, error == nil,
                      let image = UIImage(data: data) else {
                    return
                }
                
                DispatchQueue.main.async {
                    self.imageView.image = image
                }
            }.resume()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imageView.image = UIImage(named: "food_placeholder")
        nameLabel.text = nil
        caloriesLabel.text = nil
    }
}

// MARK: - FoodDetailViewControllerProtocol

extension FoodDetailViewController: FoodDetailViewControllerProtocol {
    func configure(with foodId: Int) {
        self.foodId = foodId
        if isViewLoaded {
            fetchFoodDetail()
        }
    }
}
