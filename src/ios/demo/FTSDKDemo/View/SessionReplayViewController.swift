//
//  SessionReplayViewController.swift
//  FTSDKDemo
//
//  Created by hulilei on 2024/9/6.
//

import UIKit
import RxSwift
import RxCocoa

class SessionReplayViewController: UIViewController,UIPickerViewDataSource,UIPickerViewDelegate,UICollectionViewDelegate,UICollectionViewDataSource {

    
    let disposeBag = DisposeBag()
    let segmentControl =  UISegmentedControl.init(items: ["Views 1","Views 2","Views 3"])
    var scrollView:UIScrollView = UIScrollView.init()
    var provinceIndex:Int = 0
    var cityIndex:Int = 0
    var districtIndex:Int = 0
    var arrayDS:Array<Any>?
    let nameSelectLabel:UILabel = UILabel.init()
    let progressView:UIProgressView = UIProgressView.init()
    let stepper = UIStepper.init()
    let slider = UISlider.init()
    lazy var pickerView:UIPickerView = {
        let picker = UIPickerView.init(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 266))
        picker.dataSource = self
        picker.delegate = self
        return picker
    }()
    lazy var activityView:UIActivityIndicatorView = {
        let activity = UIActivityIndicatorView.init(style: .large)
        activity.color = .theme
        return activity
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .navigationBackgroundColor
        title = "SessionReplay"
        createUI()
    }
    
    func createUI(){
        let width = self.view.frame.width
        let tipLabel = SRTipLabel.init(frame: CGRect(x: 10, y: 98, width: width-20, height: 20))
        tipLabel.text = "this is a `UISegmentedControl`"
        self.view.addSubview(tipLabel)
        segmentControl.frame = CGRect(x: 10, y: 118, width: width-20, height: 30)
        segmentControl.selectedSegmentIndex = 0
        segmentControl.rx.selectedSegmentIndex.subscribe { [weak self] selectIndex in
            self?.scrollView.contentOffset = CGPoint(x: selectIndex*Int(width), y: 0)
        }.disposed(by: disposeBag)
        self.view.addSubview(segmentControl);
        var height = segmentControl.frame.maxY
        let scrollViewHeight = self.view.frame.height-height
        let tapGesture = UITapGestureRecognizer.init()
        tapGesture.rx.event.subscribe { [weak self] element in
            self?.view.endEditing(true)
        }.disposed(by: disposeBag)
        scrollView.addGestureRecognizer(tapGesture)
        self.view.addSubview(scrollView)
        scrollView.bounces = false
        scrollView.frame = CGRect(x: 0, y: height, width: width, height: scrollViewHeight)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.contentSize = CGSize(width: width*3, height: scrollViewHeight)
        scrollView.isPagingEnabled = true
        scrollView.rx.contentOffset.subscribe { [weak self] point in
            guard let self = self else {
                return
            }
            let index = Int(point.x) / Int(self.view.frame.width)
            self.segmentControl.selectedSegmentIndex = index
        }.disposed(by: disposeBag)
      
        
        let label = UILabel.init(frame: CGRect(x: 10, y: 10, width: 220, height: 30))
        label.text = "this is a `UILabel`"
        scrollView.addSubview(label)
        
        
        let switchTipLabel = SRTipLabel.init(frame: CGRect(x: 10, y: label.frame.maxY+10, width: width/2 - 10, height: 20))
        switchTipLabel.text = "this is a `UISwitch`"
        scrollView.addSubview(switchTipLabel)
        
        let switchBtn = UISwitch.init(frame: CGRect(x: 10, y: Int(CGRectGetMaxY(switchTipLabel.frame)+10), width: 0, height: 0))
        scrollView.addSubview(switchBtn)
        switchBtn.isOn = true
        switchBtn.rx.isOn.subscribe { [weak self] element in
            if switchBtn.isOn {
                self?.activityView.startAnimating()
            }else{
                self?.activityView.stopAnimating()
            }
        }.disposed(by: disposeBag)
        
        let activityTipLabel = SRTipLabel.init(frame: CGRect(x: switchTipLabel.frame.maxX, y: switchTipLabel.frame.minY, width: width/2 - 10, height: 20))
        activityTipLabel.text = "this is a `UIActivityIndicatorView`"
        scrollView.addSubview(activityTipLabel)
        scrollView.addSubview(activityView)
        activityView.frame = CGRect(x: activityTipLabel.frame.minX, y: activityTipLabel.frame.maxY+10, width: 30, height: 30)
        activityView.startAnimating()
        
        let buttonTipLabel = SRTipLabel.init(frame: CGRect(x: 10, y: switchBtn.frame.maxY+10, width: width/2 - 20, height: 20))
        buttonTipLabel.text = "this is a `UIButton`"
        scrollView.addSubview(buttonTipLabel)
        let button = UIButton.init(frame: CGRect(x: 10, y: buttonTipLabel.frame.maxY+10, width: 100, height: 30))
        button.setTitle("Button", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.rx.controlEvent(.touchUpInside).subscribe(onNext: { element in
            button.isSelected = !button.isSelected
        }).disposed(by: disposeBag)
                    button.setTitleColor(.theme, for: .selected)
        button.layer.borderWidth = 1
        button.layer.borderColor = ThemeManager.primaryColor.cgColor
        button.layer.cornerRadius = 5
        scrollView.addSubview(button)
    
        let imageTipLabel = SRTipLabel.init(frame: CGRect(x: switchTipLabel.frame.maxX, y: buttonTipLabel.frame.minY, width: width/2 - 20, height: 20))
        imageTipLabel.text = "this is a `UIImageView`."
        scrollView.addSubview(imageTipLabel)
        let imageView = UIImageView.init(frame: CGRect(x: imageTipLabel.frame.minX, y: imageTipLabel.frame.maxY+10, width: 100, height: 100))
        imageView.image = UIImage.init(named: "AppIcon")
        scrollView.addSubview(imageView)

        let sliderTipLabel = SRTipLabel.init(frame: CGRect(x: 10, y: button.frame.maxY+10, width: width-20, height: 20))
        sliderTipLabel.text = "this is a `UISlider`."
        scrollView.addSubview(sliderTipLabel)
        slider.frame = CGRect(x: 10, y: sliderTipLabel.frame.maxY+10, width: 150, height: 30)
        slider.tintColor = .theme
        slider.maximumValue = 20
        slider.minimumValue = 0
        slider.value = 10
        scrollView.addSubview(slider)
       
        let progressTipLabel = SRTipLabel.init(frame: CGRect(x: 10, y: slider.frame.maxY+10, width: width-20, height: 20))
        progressTipLabel.text = "this is a `UIProgressView`."
        scrollView.addSubview(progressTipLabel)
        progressView.frame = CGRect(x: 10, y: progressTipLabel.frame.maxY+20, width: 150, height: 30)
        progressView.tintColor = .theme
        progressView.progress = 0.5
        scrollView.addSubview(progressView)
        slider.rx.value.subscribe { [weak self] element in
            guard let self = self else{
                return
            }
            if self.slider.value != Float(self.stepper.value){
                self.stepper.value = Double(self.slider.value)
            }
            self.progressView.progress = slider.value / 20
        }.disposed(by: disposeBag)
        
        let stepperTipLabel = SRTipLabel.init(frame: CGRect(x: imageTipLabel.frame.minX, y: progressTipLabel.frame.minY, width: 150, height: 20))
        stepperTipLabel.text = "this is a `UIStepper`."
        scrollView.addSubview(stepperTipLabel)
        stepper.frame = CGRect(x: stepperTipLabel.frame.minX, y: stepperTipLabel.frame.maxY+10, width: 100, height: 30)
        stepper.maximumValue = 20
        stepper.minimumValue = 0
        stepper.value = 10
        scrollView.addSubview(stepper)
        stepper.rx.value.subscribe { [weak self] element in
            guard let self = self else{
                return
            }
            if self.slider.value != Float(stepper.value){
                self.slider.value = Float(stepper.value)
            }
            self.progressView.progress = slider.value / 20
        }.disposed(by: disposeBag)
        let textField = UITextField.init(frame: CGRect(x: width+10, y: 10, width: 200, height: 30))
        textField.placeholder = "This is a `UITextField`."
        textField.borderStyle = .roundedRect
        scrollView.addSubview(textField)
        
        let secureTextField = UITextField.init(frame: CGRect(x: width+10, y: 50, width: self.view.frame.width-20, height: 30))
        secureTextField.placeholder = "This is a SecureTextEntry `UITextField`."
        secureTextField.borderStyle = .roundedRect
        secureTextField.isSecureTextEntry = true
        scrollView.addSubview(secureTextField)
        
        let textView = UITextView.init(frame: CGRect(x: width+10, y: secureTextField.frame.maxY+10, width: 200, height: 100))
        textView.textColor = .darkGray
        textView.text = "This is a `UITextView`."
        textView.layer.borderWidth = 1
        textView.backgroundColor = .theme
        scrollView.addSubview(textView)
        let collectionTipLabel = SRTipLabel.init(frame: CGRect(x: textView.frame.minX, y: textView.frame.maxY+10, width: 200, height: 20))
        collectionTipLabel.text = "this is a `UICollectionView`."
        scrollView.addSubview(collectionTipLabel)
        
        let layout = UICollectionViewFlowLayout.init()
        layout.scrollDirection = .vertical
        layout.itemSize = CGSizeMake(100, 40)
        let collectionView = UICollectionView.init(frame: CGRect(x: width, y: collectionTipLabel.frame.maxY, width: self.view.frame.width, height: scrollView.frame.height-collectionTipLabel.frame.maxY), collectionViewLayout: layout)
        collectionView.dataSource = self;
        collectionView.delegate = self;
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "UICollectionViewCell")
        self.scrollView.addSubview(collectionView)
        
        let datePickerTip = SRTipLabel.init(frame: CGRect(x: 2*width+10, y: 0, width: self.view.frame.width, height: 20))
        datePickerTip.text = "this is a `UIDatePicker`, style : compact"
        scrollView.addSubview(datePickerTip)
        let datePicker = UIDatePicker.init(frame: CGRect(x: 2*width+10, y: datePickerTip.frame.maxY, width: 200, height: 30))
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .compact
        }
        let wheelsDatePickerTip = SRTipLabel.init(frame: CGRect(x: 2*width+10, y: datePicker.frame.maxY, width: self.view.frame.width, height: 20))
        wheelsDatePickerTip.text = "this is a `UIDatePicker`, style : wheels"
        scrollView.addSubview(wheelsDatePickerTip)
        let wheelsDatePicker = UIDatePicker.init(frame: CGRect(x: 2*width+10, y: wheelsDatePickerTip.frame.maxY, width: 200, height: 20))
        wheelsDatePicker.datePickerMode = .dateAndTime
        if #available(iOS 13.4, *) {
            wheelsDatePicker.preferredDatePickerStyle = .wheels
        }
        scrollView.addSubview(wheelsDatePicker)
        height = wheelsDatePicker.frame.maxY
        if #available(iOS 14.0 , *) {
            let inlineDatePickerTip = SRTipLabel.init(frame: CGRect(x: 2*width+10, y: height, width: self.view.frame.width, height: 20))
            inlineDatePickerTip.text = "this is a `UIDatePicker`, style : inline"
            scrollView.addSubview(inlineDatePickerTip)
            let inlineDatePicker = UIDatePicker.init(frame: CGRect(x: 2*width+10, y: inlineDatePickerTip.frame.maxY+5, width: 200, height: 30))
            inlineDatePicker.preferredDatePickerStyle = .inline
            scrollView.addSubview(inlineDatePicker)
            height = CGRectGetMaxY(inlineDatePicker.frame)
        }
        
        self.arrayDS = readProvince()

        
        
        
        scrollView.addSubview(pickerView)
        let pickerTip = SRTipLabel.init(frame: CGRect(x: 10, y: progressView.frame.maxY+20, width: self.view.frame.width, height: 20))
        pickerTip.text = "this is a `UIPickerView`"
        scrollView.addSubview(pickerTip)
        pickerView.frame = CGRect(x: 0, y: pickerTip.frame.maxY, width: scrollView.frame.width, height: 266)
       
        
//        let selectButton = UIButton.init(frame: CGRect(x: pickerTip.frame.maxX, y: pickerTip.frame.minY, width: 80, height: 30))
//        selectButton.setTitle("Select", for: .normal)
//        selectButton.setTitle("Confirm", for: .selected)
//        selectButton.setTitleColor(.darkGray, for: .normal)
//        selectButton.rx.controlEvent(.touchUpInside).subscribe {[weak self] element in
//            guard let self = self else {
//                selectButton.isSelected = !selectButton.isSelected
//                return
//            }
//            if selectButton.isSelected {
//                UIView.animate(withDuration: 0.1) {
//                    self.pickerView.frame = CGRectMake(0, self.view.frame.height, self.view.frame.width, 266);
//                }
//            }else{
//                UIView.animate(withDuration: 0.1) {
//                    self.pickerView.frame = CGRectMake(0, self.view.frame.height-300, self.view.frame.width, 266);
//                }
//            }
//            selectButton.isSelected = !selectButton.isSelected
//        }.disposed(by: disposeBag)
//        scrollView.addSubview(selectButton)
        scrollView.addSubview(datePicker)
        resetPickerSelectRow()
    }

    func readProvince()->Array<Any>?{
        if let path = Bundle.main.url(forResource: "Province", withExtension: "plist"){
            do{
                let data = try Data(contentsOf: path)
                let plist = try PropertyListSerialization.propertyList(from: data, options: .mutableContainers, format: nil) as! Array<Any>
                 
                return plist
            }catch{
               FTLogError("Failed to Serialization plist file data")
               return nil
            }
        } else {
            FTLogError("Failed to load plist file")
            return nil
        }
        
    }
    
    func resetPickerSelectRow(){
        pickerView.selectRow(provinceIndex, inComponent: 0, animated: true)
        pickerView.selectRow(cityIndex, inComponent: 1, animated: true)
        pickerView.selectRow(districtIndex, inComponent: 2, animated: true)
    }
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        guard let array = arrayDS else {
            return 0
        }
        let provinceDict:Dictionary = array[provinceIndex] as! Dictionary<String, Any>
        let cityArray:Array = provinceDict["citys"] as! Array<Any>
        if(component == 0){
            return array.count
        }else if(component == 1){
            return cityArray.count
        }else{
            let cityDict :Dictionary = cityArray[cityIndex] as! Dictionary<String,Any>
            let districts :Array = cityDict["districts"] as! Array<Any>
            return districts.count
        }
        
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard let array = arrayDS else {
            return nil
        }
        
        if (component == 0){
            let provinceDict:Dictionary = array[row] as! Dictionary<String, Any>
            return provinceDict["province"] as? String
        }else if(component == 1){
            let provinceDict:Dictionary = array[provinceIndex] as! Dictionary<String, Any>
            let cityArray:Array = provinceDict["citys"] as! Array<Any>
            let cityDict :Dictionary = cityArray[row] as! Dictionary<String,Any>
            return (cityDict["city"] as! String)
        }else{
            let provinceDict:Dictionary = array[provinceIndex] as! Dictionary<String, Any>
            let cityArray:Array = provinceDict["citys"] as! Array<Any>
            let cityDict :Dictionary = cityArray[cityIndex] as! Dictionary<String,Any>
            let districtsArray:Array = cityDict["districts"] as! Array<String>
            return districtsArray[row]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard let array = arrayDS else {
            return
        }
        if(component == 0){
            provinceIndex = row
            cityIndex = 0
            districtIndex = 0
            pickerView.reloadComponent(1)
            pickerView.reloadComponent(2)
        }else if(component == 1){
            cityIndex = row
            districtIndex = 0
            pickerView.reloadComponent(2)
        }else{
            districtIndex = row
        }
        let provinceDict:Dictionary = array[provinceIndex] as! Dictionary<String, Any>
        let cityArray:Array = provinceDict["citys"] as! Array<Any>
        let cityDict :Dictionary = cityArray[cityIndex] as! Dictionary<String,Any>
        let districtsArray:Array = cityDict["districts"] as! Array<String>
        let address = "\(provinceDict["province"] as! String)-\(cityDict["city"] as! String)-\(districtsArray[districtIndex])"
        nameSelectLabel.text = address
        resetPickerSelectRow()
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 25
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UICollectionViewCell", for: indexPath)
        let label = UILabel.init(frame: CGRectMake(0, 0, 100, 40))
        label.text = "cell: \(indexPath.row)"
        cell.contentView.addSubview(label)
        label.backgroundColor = randomColor()
        return cell;
    }
    
    func randomColor() -> UIColor {
       let red = CGFloat(arc4random_uniform(255)) / 255.0
       let green = CGFloat(arc4random_uniform(255)) / 255.0
       let blue = CGFloat(arc4random_uniform(255)) / 255.0
       
       return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
   }
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
