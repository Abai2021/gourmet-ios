//
//  TabBarController.swift
//  gourmet-ios
//
//  Created by Cascade on 2025/3/30.
//

import UIKit

// 添加自定义工具类的导入
import Alamofire

class TabBarController: UITabBarController, UITabBarControllerDelegate {
    
    // 获取自定义TabBar
    private var customTabBar: CustomTabBar? {
        return self.tabBar as? CustomTabBar
    }
    
    // 是否正在执行页面切换动画
    private var isAnimating = false
    
    // 导航栏视图
    private lazy var navigationBarView: NavigationBarView = {
        let navBar = NavigationBarView()
        navBar.translatesAutoresizingMaskIntoConstraints = false
        navBar.delegate = self
        return navBar
    }()
    
    // 状态栏背景视图
    private lazy var statusBarBackgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = NavigationBarView.healthyGreen
        return view
    }()
    
    // 侧边栏容器
    private var sideMenuContainer: SideMenuContainerViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set delegate
        self.delegate = self
        
        // Setup view controllers
        setupViewControllers()
        
        // Setup custom tabBar
        setupCustomTabBar()
        
        // Setup navigation bar
        setupNavigationBar()
        
        // Enable swipe gesture to switch tabs
        setupSwipeGesture()
        
        // 禁用系统的标签切换动画，使用我们自己的动画
        self.view.backgroundColor = .white
        
        // 默认选中第一个标签页
        self.selectedIndex = 0
        
        // 立即强制更新TabBar的选中状态，确保图标正确显示
        forceUpdateTabBarItemAppearance(at: 0)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 确保选中第一个标签页
        forceUpdateTabBarItemAppearance(at: selectedIndex)
    }
    
    private func setupViewControllers() {
        // Food View Controller
        let foodVC = FoodViewController()
        let foodNav = UINavigationController(rootViewController: foodVC)
        foodNav.navigationBar.isHidden = true // 隐藏系统导航栏
        
        // 创建食物标签页图标并调整大小
        let homeImage = resizeImage(UIImage(named: "tabbar_home"), targetSize: CGSize(width: 25, height: 25))?.withRenderingMode(.alwaysOriginal)
        let homeSelectedImage = resizeImage(UIImage(named: "tabbar_home_selected"), targetSize: CGSize(width: 32, height: 32))?.withRenderingMode(.alwaysOriginal)
        let foodItem = UITabBarItem(title: "食物", image: homeImage, selectedImage: homeSelectedImage)
        foodItem.setTitleTextAttributes([.foregroundColor: UIColor.gray], for: .normal)
        foodItem.setTitleTextAttributes([.foregroundColor: UIColor.systemBlue], for: .selected)
        foodNav.tabBarItem = foodItem
        
        // Community View Controller
        let communityVC = CommunityViewController()
        let communityNav = UINavigationController(rootViewController: communityVC)
        communityNav.navigationBar.isHidden = true // 隐藏系统导航栏
        
        // 创建社区标签页图标并调整大小
        let communityImage = resizeImage(UIImage(named: "tabbar_community"), targetSize: CGSize(width: 25, height: 25))?.withRenderingMode(.alwaysOriginal)
        let communitySelectedImage = resizeImage(UIImage(named: "tabbar_community_selected"), targetSize: CGSize(width: 32, height: 32))?.withRenderingMode(.alwaysOriginal)
        let communityItem = UITabBarItem(title: "社区", image: communityImage, selectedImage: communitySelectedImage)
        communityItem.setTitleTextAttributes([.foregroundColor: UIColor.gray], for: .normal)
        communityItem.setTitleTextAttributes([.foregroundColor: UIColor.systemBlue], for: .selected)
        communityNav.tabBarItem = communityItem
        
        // Diet View Controller
        let dietVC = DietViewController()
        let dietNav = UINavigationController(rootViewController: dietVC)
        dietNav.navigationBar.isHidden = true // 隐藏系统导航栏
        
        // 创建饮食标签页图标并调整大小
        let dietImage = resizeImage(UIImage(named: "tabbar_diet"), targetSize: CGSize(width: 25, height: 25))?.withRenderingMode(.alwaysOriginal)
        let dietSelectedImage = resizeImage(UIImage(named: "tabbar_diet_selected"), targetSize: CGSize(width: 32, height: 32))?.withRenderingMode(.alwaysOriginal)
        let dietItem = UITabBarItem(title: "饮食", image: dietImage, selectedImage: dietSelectedImage)
        dietItem.setTitleTextAttributes([.foregroundColor: UIColor.gray], for: .normal)
        dietItem.setTitleTextAttributes([.foregroundColor: UIColor.systemBlue], for: .selected)
        dietNav.tabBarItem = dietItem
        
        // Set view controllers
        self.viewControllers = [foodNav, communityNav, dietNav]
    }
    
    private func resizeImage(_ image: UIImage?, targetSize: CGSize) -> UIImage? {
        guard let image = image else { return nil }
        
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        // 使用较小的比例，保持图像的宽高比
        let newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    private func setupCustomTabBar() {
        // Set custom tab bar
        let customTabBar = CustomTabBar()
        self.setValue(customTabBar, forKey: "tabBar")
        
        // Set tab bar appearance
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .white
            
            customTabBar.standardAppearance = appearance
            customTabBar.scrollEdgeAppearance = appearance
        } else {
            customTabBar.barTintColor = .white
        }
    }
    
    private func setupNavigationBar() {
        // 添加状态栏背景视图
        view.addSubview(statusBarBackgroundView)
        
        // 添加导航栏视图
        view.addSubview(navigationBarView)
        
        // 设置约束
        NSLayoutConstraint.activate([
            // 状态栏背景视图约束
            statusBarBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            statusBarBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            statusBarBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            statusBarBackgroundView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            
            // 导航栏视图约束
            navigationBarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationBarView.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // 调整内容视图的位置，使其不被导航栏遮挡
        for viewController in viewControllers ?? [] {
            if let navController = viewController as? UINavigationController,
               let rootVC = navController.viewControllers.first {
                
                // 为每个视图控制器添加额外的顶部边距
                rootVC.additionalSafeAreaInsets = UIEdgeInsets(top: 44, left: 0, bottom: 0, right: 0)
            }
        }
    }
    
    private func setupSwipeGesture() {
        // Add swipe gesture recognizers to enable swiping between tabs
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture(_:)))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture(_:)))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
    }
    
    @objc private func handleSwipeGesture(_ gesture: UISwipeGestureRecognizer) {
        // 如果正在执行动画，忽略手势
        if isAnimating {
            return
        }
        
        if gesture.direction == .right {
            if selectedIndex > 0 {
                animateToTab(from: selectedIndex, to: selectedIndex - 1)
            }
        } else if gesture.direction == .left {
            if selectedIndex < (self.viewControllers?.count ?? 1) - 1 {
                animateToTab(from: selectedIndex, to: selectedIndex + 1)
            }
        }
    }
    
    // 强制更新TabBar项的外观
    private func forceUpdateTabBarItemAppearance(at index: Int) {
        // 立即更新TabBar的选中索引
        customTabBar?.setSelectedIndex(index)
        
        // 强制更新TabBar项的图标显示
        if let items = tabBar.items, index < items.count {
            // 遍历所有标签项，重置状态
            for (i, item) in items.enumerated() {
                if i == index {
                    // 选中的标签项
                    item.setTitleTextAttributes([.foregroundColor: UIColor.systemBlue], for: .selected)
                    
                    // 查找并直接修改TabBar按钮的图像视图
                    findAndUpdateTabBarButtonImageView(at: i, isSelected: true)
                } else {
                    // 未选中的标签项
                    item.setTitleTextAttributes([.foregroundColor: UIColor.gray], for: .normal)
                    
                    // 查找并直接修改TabBar按钮的图像视图
                    findAndUpdateTabBarButtonImageView(at: i, isSelected: false)
                }
            }
        }
    }
    
    // 查找并更新TabBar按钮的图像视图
    private func findAndUpdateTabBarButtonImageView(at index: Int, isSelected: Bool) {
        // 获取所有TabBar按钮
        let tabBarButtons = tabBar.subviews.filter { subview in
            return subview.isKind(of: NSClassFromString("UITabBarButton")!)
        }
        
        // 确保索引有效
        guard index < tabBarButtons.count else { return }
        
        // 获取对应的按钮
        let button = tabBarButtons[index]
        
        // 查找按钮中的图像视图
        for subview in button.subviews {
            if let imageView = subview as? UIImageView {
                // 设置图像视图的内容模式
                imageView.contentMode = .center
                
                // 强制更新图像
                if isSelected {
                    // 选中状态 - 使用selectedImage
                    if let selectedImage = tabBar.items?[index].selectedImage {
                        imageView.image = selectedImage
                    }
                } else {
                    // 未选中状态 - 使用image
                    if let normalImage = tabBar.items?[index].image {
                        imageView.image = normalImage
                    }
                }
                
                // 立即刷新视图
                imageView.setNeedsDisplay()
            }
        }
    }
    
    // 动画切换标签页
    private func animateToTab(from fromIndex: Int, to toIndex: Int) {
        // 如果正在执行动画，忽略请求
        if isAnimating {
            return
        }
        
        // 设置动画标志
        isAnimating = true
        
        guard let fromView = self.viewControllers?[fromIndex].view,
              let toView = self.viewControllers?[toIndex].view else {
            isAnimating = false
            return
        }
        
        // 立即强制更新TabBar的选中状态
        forceUpdateTabBarItemAppearance(at: toIndex)
        
        // 设置动画方向
        let screenWidth = UIScreen.main.bounds.width
        let direction: CGFloat = toIndex > fromIndex ? 1.0 : -1.0
        
        // 将目标视图添加到当前视图层次结构中
        fromView.superview?.addSubview(toView)
        
        // 设置目标视图的初始位置（屏幕外）
        toView.frame = fromView.frame
        toView.transform = CGAffineTransform(translationX: screenWidth * direction, y: 0)
        
        // 执行动画
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
            // 将当前视图移出屏幕
            fromView.transform = CGAffineTransform(translationX: -screenWidth * direction, y: 0)
            
            // 将目标视图移入屏幕
            toView.transform = .identity
            
        }, completion: { _ in
            // 重置变换
            fromView.transform = .identity
            toView.transform = .identity
            
            // 移除视图并更新选中索引
            toView.removeFromSuperview()
            self.selectedIndex = toIndex
            
            // 重置动画标志
            self.isAnimating = false
        })
    }
    
    // UITabBarControllerDelegate method
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        // 如果正在执行动画，忽略点击
        if isAnimating {
            return false
        }
        
        // 获取索引
        guard let fromIndex = tabBarController.viewControllers?.firstIndex(of: tabBarController.selectedViewController!),
              let toIndex = tabBarController.viewControllers?.firstIndex(of: viewController) else {
            return true
        }
        
        // 如果点击的是当前标签，不执行动画
        if fromIndex == toIndex {
            return true
        }
        
        // 执行动画切换
        animateToTab(from: fromIndex, to: toIndex)
        
        return false // 返回false以阻止系统默认的切换行为
    }
    
    // 当标签页切换时更新自定义TabBar的选中索引
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if let index = tabBar.items?.firstIndex(of: item) {
            // 立即强制更新TabBar的选中状态
            forceUpdateTabBarItemAppearance(at: index)
        }
    }
    
    // 禁用系统的标签切换动画
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // 确保所有标签页视图都有相同的尺寸
        if let views = viewControllers?.map({ $0.view }) {
            for view in views {
                view?.frame = self.view.bounds
            }
        }
        
        // 确保导航栏和状态栏背景始终在最上层
        view.bringSubviewToFront(statusBarBackgroundView)
        view.bringSubviewToFront(navigationBarView)
    }
}

// MARK: - NavigationBarDelegate
extension TabBarController: NavigationBarDelegate {
    
    func didTapAvatarButton() {
        // 创建侧边栏容器
        let sideMenuContainer = SideMenuContainerViewController(mainViewController: self)
        
        // 不再需要设置用户信息，由 SideMenuViewController 自己处理
        // sideMenuContainer.setUserInfo(
        //     avatar: nil,
        //     username: "请登录",
        //     userId: "点击此处登录"
        // )
        
        // 保存引用以便后续使用
        self.sideMenuContainer = sideMenuContainer
        
        // 使用自定义过渡方式显示侧边栏
        sideMenuContainer.modalPresentationStyle = .overFullScreen
        sideMenuContainer.modalTransitionStyle = .crossDissolve
        
        present(sideMenuContainer, animated: false) {
            sideMenuContainer.showSideMenu()
        }
    }
}
