//
//  InputTableViewCell.swift
//  FTSDKDemo
//
//  Created by hulilei on 2024/9/2.
//

import UIKit

class InputTableViewCell: UITableViewCell {
    let titleLabel:UILabel = {
        let label = UILabel.init()
        label.textColor = .tipLabel
        label.font = .systemFont(ofSize: 17)
        return label
    }()
    
   public lazy var contentTextfield:DesignableUITextField = {
        let textField = DesignableUITextField.init()
        textField.textColor = .tipLabel
        textField.font = .systemFont(ofSize: 15)
        textField.leftViewMode = .always
        textField.keyboardType = .default
        textField.clearButtonMode = .always
        textField.addTarget(self, action: #selector(onInputTextChanged(textField:)), for: .editingChanged)
        textField.lineColor = .clear
        return textField
    }()
    
    public var inputTextFieldChanged:((String?)->Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.setupInitialUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
  
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func setupInitialUI(){
        self.backgroundColor = .white
        self.contentView.addSubview(titleLabel)
        self.contentView.addSubview(contentTextfield)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(15)
            make.left.equalTo(contentView).offset(20)
            make.size.equalTo(CGSize(width: contentView.frame.size.width-30, height: 20))
        }
        contentTextfield.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp_bottomMargin).offset(20)
            make.left.equalTo(titleLabel)
            make.right.equalTo(contentView).offset(-10)
            make.bottom.equalTo(contentView.snp_bottomMargin).offset(10)
        }
    }
    func setInfo(info:CellInfo) {
        titleLabel.text = info.title
        contentTextfield.placeholder = info.hint
        contentTextfield.text = info.detail
        contentTextfield.connect = info.connectStatus
        info.refresh = { [weak self] in
            self?.contentTextfield.connect = info.connectStatus
        }
    }
    
    func setDetail(detail:String){
        contentTextfield.text = detail
    }
    
    @objc func onInputTextChanged(textField:UITextField){
        if let inputTextFieldChanged = inputTextFieldChanged {
            inputTextFieldChanged(textField.text)
        }
    }
}
