import UIKit

class NutritionCell: UITableViewCell {
    
    let leftNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .label
        return label
    }()
    
    let leftValueLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        return label
    }()
    
    let rightNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .label
        return label
    }()
    
    let rightValueLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        return label
    }()
    
    let dividerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGray5
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        
        contentView.addSubview(leftNameLabel)
        contentView.addSubview(leftValueLabel)
        contentView.addSubview(dividerView)
        contentView.addSubview(rightNameLabel)
        contentView.addSubview(rightValueLabel)
        
        NSLayoutConstraint.activate([
            leftNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            leftNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            leftNameLabel.widthAnchor.constraint(equalToConstant: 80),
            
            leftValueLabel.leadingAnchor.constraint(equalTo: leftNameLabel.trailingAnchor, constant: 8),
            leftValueLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            leftValueLabel.trailingAnchor.constraint(equalTo: dividerView.leadingAnchor, constant: -16),
            
            dividerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            dividerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            dividerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            dividerView.widthAnchor.constraint(equalToConstant: 1),
            
            rightNameLabel.leadingAnchor.constraint(equalTo: dividerView.trailingAnchor, constant: 16),
            rightNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            rightNameLabel.widthAnchor.constraint(equalToConstant: 80),
            
            rightValueLabel.leadingAnchor.constraint(equalTo: rightNameLabel.trailingAnchor, constant: 8),
            rightValueLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            rightValueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
}
