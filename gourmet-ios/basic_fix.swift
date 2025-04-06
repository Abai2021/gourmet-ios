// 这是创建自定义的UITextView子类的方法
// 将此代码放在一个新文件中，或者放在现有文件的适当位置

import UIKit

// 创建一个自定义的UITextView子类，强制使用黑色文本和白色背景
class BlackTextView: UITextView {
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupTextView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTextView()
    }
    
    private func setupTextView() {
        // 强制设置文本颜色为黑色
        self.textColor = .black
        // 强制设置背景色为白色
        self.backgroundColor = .white
    }
    
    // 覆盖这些属性，确保它们不会被意外更改
    override var textColor: UIColor? {
        didSet {
            // 始终确保文本颜色是黑色
            super.textColor = .black
        }
    }
    
    override var backgroundColor: UIColor? {
        didSet {
            // 始终确保背景色是白色
            super.backgroundColor = .white
        }
    }
}

// 使用说明：
// 在CreatePostViewController.swift和CommunityViewController.swift中
// 将所有的UITextView()替换为BlackTextView()
// 例如：
// let textView = BlackTextView()
// 代替
// let textView = UITextView()
