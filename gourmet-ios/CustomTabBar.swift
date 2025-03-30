//
//  CustomTabBar.swift
//  gourmet-ios
//
//  Created by Cascade on 2025/3/30.
//

import UIKit

class CustomTabBar: UITabBar {
    
    private var shapeLayer: CAShapeLayer?
    private var selectedIndex: Int = 0
    private var currentCenterX: CGFloat = 0
    private var isAdjustingTabPositions = false
    
    // 保存TabBar项的视图引用
    private var tabBarItemViews: [UIView] = []
    
    override func draw(_ rect: CGRect) {
        self.addShape()
    }
    
    // 设置当前选中的索引并添加动画
    func setSelectedIndex(_ index: Int) {
        // 如果索引没有变化，不执行任何操作
        if self.selectedIndex == index {
            return
        }
        
        let oldIndex = self.selectedIndex
        self.selectedIndex = index
        
        // 计算旧位置和新位置
        let tabWidth = self.frame.width / CGFloat(self.items?.count ?? 3)
        let oldCenterX = tabWidth * (CGFloat(oldIndex) + 0.5)
        let newCenterX = tabWidth * (CGFloat(index) + 0.5)
        
        // 立即更新形状，不使用动画
        animateShapeChange(from: oldCenterX, to: newCenterX)
        
        // 立即更新标签位置
        updateTabBarItemPositions(animated: false)
    }
    
    // 添加形状层
    private func addShape() {
        // 计算中心点
        let tabWidth = self.frame.width / CGFloat(self.items?.count ?? 3)
        let centerX = tabWidth * (CGFloat(selectedIndex) + 0.5)
        self.currentCenterX = centerX
        
        // 创建形状层
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = createPath(withCenterX: centerX)
        shapeLayer.fillColor = UIColor.white.cgColor
        shapeLayer.strokeColor = UIColor.lightGray.cgColor
        shapeLayer.lineWidth = 0.5
        
        // 如果已经有形状层，先移除
        if let oldShapeLayer = self.shapeLayer {
            self.layer.replaceSublayer(oldShapeLayer, with: shapeLayer)
        } else {
            self.layer.insertSublayer(shapeLayer, at: 0)
        }
        
        self.shapeLayer = shapeLayer
        
        // 更新标签位置
        updateTabBarItemPositions(animated: false)
    }
    
    // 更新标签位置
    private func updateTabBarItemPositions(animated: Bool) {
        // 避免重复调整
        if isAdjustingTabPositions {
            return
        }
        
        isAdjustingTabPositions = true
        
        // 获取所有标签项视图
        let tabBarItemViews = self.subviews.filter { view in
            return view.isKind(of: NSClassFromString("UITabBarButton")!)
        }
        
        self.tabBarItemViews = tabBarItemViews
        
        // 调整每个标签项的位置
        for (index, itemView) in tabBarItemViews.enumerated() {
            let isSelected = index == selectedIndex
            
            // 计算Y偏移量
            let yOffset: CGFloat = isSelected ? -10 : 0
            
            // 设置动画
            if animated {
                UIView.animate(withDuration: 0.1, animations: {
                    itemView.transform = CGAffineTransform(translationX: 0, y: yOffset)
                })
            } else {
                itemView.transform = CGAffineTransform(translationX: 0, y: yOffset)
            }
            
            // 确保图标正确显示
            for subview in itemView.subviews {
                if let imageView = subview as? UIImageView {
                    imageView.contentMode = .center
                }
            }
        }
        
        isAdjustingTabPositions = false
    }
    
    // 创建路径
    private func createPath(withCenterX centerX: CGFloat) -> CGPath {
        let path = UIBezierPath()
        
        // 弧形的高度
        let arcHeight: CGFloat = -15
        
        // 弧形的宽度
        let arcWidth: CGFloat = 80
        
        // 起点（左上角）
        path.move(to: CGPoint(x: 0, y: 0))
        
        // 绘制到弧形左侧的线
        path.addLine(to: CGPoint(x: centerX - arcWidth/2, y: 0))
        
        // 绘制弧形
        path.addQuadCurve(to: CGPoint(x: centerX + arcWidth/2, y: 0),
                          controlPoint: CGPoint(x: centerX, y: arcHeight))
        
        // 绘制到右上角的线
        path.addLine(to: CGPoint(x: self.frame.width, y: 0))
        
        // 绘制到右下角的线
        path.addLine(to: CGPoint(x: self.frame.width, y: self.frame.height))
        
        // 绘制到左下角的线
        path.addLine(to: CGPoint(x: 0, y: self.frame.height))
        
        // 闭合路径
        path.close()
        
        return path.cgPath
    }
    
    // 动画形状变化
    private func animateShapeChange(from oldCenterX: CGFloat, to newCenterX: CGFloat) {
        guard let shapeLayer = self.shapeLayer else { return }
        
        // 立即更新路径，不使用动画
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        shapeLayer.path = createPath(withCenterX: newCenterX)
        CATransaction.commit()
        
        // 更新当前中心点
        self.currentCenterX = newCenterX
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 如果点在曲线区域上方，仍然允许交互
        if !self.isHidden {
            // 定义曲线区域
            let curveArea = CGRect(x: currentCenterX - 40, y: -15, width: 80, height: 15)
            
            // 如果点在曲线区域内，找到合适的子视图处理触摸
            if curveArea.contains(point) {
                for subview in self.subviews {
                    let subviewPoint = subview.convert(point, from: self)
                    if let result = subview.hitTest(subviewPoint, with: event) {
                        return result
                    }
                }
            }
        }
        
        return super.hitTest(point, with: event)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // 重新调整形状
        self.addShape()
        
        // 确保图标正确显示
        for view in self.subviews {
            if view.isKind(of: NSClassFromString("UITabBarButton")!) {
                for subview in view.subviews {
                    if let imageView = subview as? UIImageView {
                        imageView.contentMode = .center
                        imageView.sizeToFit()
                    }
                }
            }
        }
    }
}
