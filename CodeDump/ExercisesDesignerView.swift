//
//  ExercisesDesignerView.swift
//  CodeDump
//
//  Created by Luke Solomon on 7/6/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import UIKit


protocol ExercisesDesignerViewDelegate:UIViewController {
  func doneButtonTapped(text: String)
}

struct ExercisesDesignerViewModel {
  var designerViewDelegate:ExercisesDesignerViewDelegate
}

class ExercisesDesignerView: UIView {
  
  var viewModel:ExercisesDesignerViewModel?
  weak var delegate:ExercisesDesignerViewDelegate!
  
  var containerView = OutrunStackView()
  var textField = OutrunTextField()
  var doneButton = UIButton()
  var tapGesture = UITapGestureRecognizer()
  // pickerview as well
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
  }
    
  func configure(viewModel: ExercisesDesignerViewModel) {
    self.delegate = viewModel.designerViewDelegate
    self.viewModel = viewModel
    
    self.addGestureRecognizer(tapGesture)
    tapGesture.addTarget(self, action: #selector(hideKeyboard))
    
    self.addSubview(containerView)
    self.backgroundColor = UIColor.OutrunBlack
    containerView.distribution = .fill
    containerView.alignment = .fill
    containerView.axis = .horizontal
    containerView.translatesAutoresizingMaskIntoConstraints = false
    containerView.addBackground(color: UIColor.OutrunBlack)
    
    containerView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 0, height: 0, enableInsets: false)
    
    containerView.addArrangedSubview(textField)
    textField.customizeWithStandardValues(placeholder: "_")
    textField.delegate = self
    
    containerView.addArrangedSubview(doneButton)
    doneButton.titleLabel?.text = "Done"
    doneButton.setTitle("Done", for: .normal)
    doneButton.addTarget(self, action: #selector(self.doneButtonTapped), for: .touchUpInside)
  }
  
  @objc func doneButtonTapped() {
    delegate.doneButtonTapped(text: self.textField.text ?? "")
  }
  
  @objc func hideKeyboard() {
    self.resignFirstResponder()
  }
    
}

extension ExercisesDesignerView: UITextFieldDelegate {
  
}
