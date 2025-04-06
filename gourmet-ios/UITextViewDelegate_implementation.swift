// 复制以下代码替换CommunityViewController.swift中的UITextViewDelegate扩展

extension CommunityViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        // 确保文本颜色为黑色
        textView.textColor = .black
        
        // 更新字符计数标签
        if let countLabel = textView.superview?.viewWithTag(102) as? UILabel {
            countLabel.text = "\(textView.text.count)/200"
        }
        
        // 隐藏或显示占位符标签
        if let placeholderLabel = textView.superview?.viewWithTag(101) as? UILabel {
            placeholderLabel.isHidden = !textView.text.isEmpty
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        // 确保文本颜色为黑色
        textView.textColor = .black
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        // 结束编辑后确保文本颜色保持为黑色
        textView.textColor = .black
    }
}
