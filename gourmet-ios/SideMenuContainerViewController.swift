//
//  SideMenuContainerViewController.swift
//  gourmet-ios
//
//  Created by Cascade on 2025/3/30.
//

import UIKit

class SideMenuContainerViewController: UIViewController {
    
    private var mainViewController: UIViewController
    private let sideMenuViewController: SideMenuViewController
    
    private var isSideMenuShowing = false
    private let sideMenuWidth: CGFloat = 280
    private let animationDuration: TimeInterval = 0.3
    
    private lazy var dimView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.alpha = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dimViewTapped))
        view.addGestureRecognizer(tapGesture)
        
        return view
    }()
    
    init(mainViewController: UIViewController) {
        self.mainViewController = mainViewController
        self.sideMenuViewController = SideMenuViewController()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupSideMenu()
    }
    
    private func setupView() {
        view.backgroundColor = .clear
        
        // 添加暗色视图
        view.addSubview(dimView)
        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 添加侧滑手势
        let edgePanGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgePan(_:)))
        edgePanGesture.edges = .left
        view.addGestureRecognizer(edgePanGesture)
    }
    
    private func setupSideMenu() {
        // 添加侧边菜单视图控制器
        addChild(sideMenuViewController)
        view.addSubview(sideMenuViewController.view)
        
        // 设置侧边菜单初始位置（屏幕左侧外）
        sideMenuViewController.view.frame = CGRect(
            x: -sideMenuWidth,
            y: 0,
            width: sideMenuWidth,
            height: view.bounds.height
        )
        
        sideMenuViewController.didMove(toParent: self)
        sideMenuViewController.delegate = self
        
        // 添加阴影
        sideMenuViewController.view.layer.shadowColor = UIColor.black.cgColor
        sideMenuViewController.view.layer.shadowOpacity = 0.3
        sideMenuViewController.view.layer.shadowRadius = 5
        sideMenuViewController.view.layer.shadowOffset = CGSize(width: 0, height: 0)
    }
    
    // 显示侧边菜单
    func showSideMenu() {
        guard !isSideMenuShowing else { return }
        
        isSideMenuShowing = true
        
        // 动画显示侧边菜单
        UIView.animate(withDuration: animationDuration) {
            self.sideMenuViewController.view.frame.origin.x = 0
            self.dimView.alpha = 1
        }
    }
    
    // 隐藏侧边菜单
    func hideSideMenu(completion: (() -> Void)? = nil) {
        guard isSideMenuShowing else {
            completion?()
            return
        }
        
        isSideMenuShowing = false
        
        // 动画隐藏侧边菜单
        UIView.animate(withDuration: animationDuration, animations: {
            self.sideMenuViewController.view.frame.origin.x = -self.sideMenuWidth
            self.dimView.alpha = 0
        }, completion: { _ in
            completion?()
        })
    }
    
    @objc private func dimViewTapped() {
        hideSideMenu { [weak self] in
            self?.dismiss(animated: false, completion: nil)
        }
    }
    
    @objc private func handleEdgePan(_ gesture: UIScreenEdgePanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let progress = min(max(translation.x / sideMenuWidth, 0), 1)
        
        switch gesture.state {
        case .began:
            break
            
        case .changed:
            // 更新侧边菜单位置
            sideMenuViewController.view.frame.origin.x = -sideMenuWidth + (sideMenuWidth * progress)
            dimView.alpha = progress
            
        case .ended, .cancelled:
            // 根据滑动速度和位置决定是显示还是隐藏侧边菜单
            let velocity = gesture.velocity(in: view)
            
            if velocity.x > 500 || progress > 0.5 {
                showSideMenu()
            } else {
                hideSideMenu { [weak self] in
                    self?.dismiss(animated: false, completion: nil)
                }
            }
            
        default:
            break
        }
    }
    
    // 设置用户信息
    func setUserInfo(avatar: UIImage?, username: String, userId: String) {
        sideMenuViewController.setUserInfo(avatar: avatar, username: username, userId: userId)
    }
}

// MARK: - SideMenuDelegate
extension SideMenuContainerViewController: SideMenuDelegate {
    
    func didSelectMenuItem(_ menuItem: SideMenuItem) {
        // 隐藏侧边菜单并关闭容器
        hideSideMenu { [weak self] in
            guard let self = self else { return }
            
            // 创建并显示菜单详情页
            let detailVC = MenuDetailViewController(menuItem: menuItem)
            
            // 创建导航控制器
            let navController = UINavigationController(rootViewController: detailVC)
            navController.modalPresentationStyle = .fullScreen
            
            // 关闭侧边栏容器并显示详情页
            self.dismiss(animated: false) {
                self.mainViewController.present(navController, animated: true, completion: nil)
            }
        }
    }
}
