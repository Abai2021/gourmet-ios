//
//  FoodViewController.swift
//  gourmet-ios
//
//  Created by Cascade on 2025/3/30.
//

import UIKit

class FoodViewController: UIViewController {
    
    private let centerLabel: UILabel = {
        let label = UILabel()
        label.text = "食物页面"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up view
        title = "食物"
        view.backgroundColor = UIColor(white: 0.95, alpha: 1.0) // 淡灰色背景
        
        // Add center label
        view.addSubview(centerLabel)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            centerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
