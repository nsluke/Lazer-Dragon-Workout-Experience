//
//  OutrunViewController.swift
//  CodeDump
//
//  Created by Luke Solomon on 6/19/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import UIKit


class OutrunViewController: UIViewController {
  
  // MARK: Interface
  var outrunStackView = OutrunStackView()

  
  convenience init(anchor: Bool = true) {
    self.init()
    if anchor {
      outrunStackView.pinToSuper()
    }
  }
  
  // MARK: View Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = UIColor.OutrunDarkerGray
    navigationItem.backBarButtonItem?.tintColor = UIColor.OutrunLaserBlue
    navigationController?.navigationBar.backgroundColor = UIColor.OutrunDarkerGray
    navigationController?.navigationBar.barTintColor = UIColor.OutrunDarkerGray
    
    // Back Button Color & Font
    let backButtonItem = UIBarButtonItem(
      title: "<",
      style: .plain,
      target: self,
      action: #selector(backButtonTapped)
    )
    
    backButtonItem.setTitleTextAttributes([
       .foregroundColor : UIColor.OutrunLaserBlue,
       .font : UIFont(name: "Pixel-01", size: 48) ?? UIFont.systemFont(ofSize: 18)
     ], for: .normal)
    
    self.navigationItem.setLeftBarButton(backButtonItem, animated: false)
  }
  
  @objc func backButtonTapped() {
    self.navigationController?.popViewController(animated: true)
  }
  
  func hideBackButton() {
    // override back button from Super
    let backButtonItem = UIBarButtonItem(
      title: "",
      style: .plain,
      target: nil,
      action: nil
    )
    self.navigationItem.setLeftBarButton(backButtonItem, animated: false)
    self.navigationItem.leftBarButtonItem?.isEnabled = false
    self.navigationItem.hidesBackButton = true
  }
  
}
