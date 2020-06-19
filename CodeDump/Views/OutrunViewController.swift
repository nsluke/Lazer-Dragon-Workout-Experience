//
//  OutrunViewController.swift
//  CodeDump
//
//  Created by Luke Solomon on 6/19/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import UIKit


class OutrunViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
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
  
}
