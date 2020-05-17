//
//  OutrunTabBar.swift
//  CodeDump
//
//  Created by Luke Solomon on 5/15/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import UIKit

class OutrunTabBar: UITabBarController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
        
    
    let profileNavigationController = UINavigationController.init(rootViewController: ProfileViewController())
    profileNavigationController.tabBarItem = UITabBarItem(tabBarSystemItem: .contacts, tag: 0)
//    profileNavigationController.tabBarItem.badgeColor = UIColor.OutrunLaserBlue
    
    
    if #available(iOS 13, *) {
      
      let appearance = UITabBarAppearance()
      appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.gray]
      appearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.OutrunLaserBlue]
      appearance.stackedLayoutAppearance.normal.badgeBackgroundColor = UIColor.OutrunBlack
      tabBar.standardAppearance = appearance
      
    } else {
      
      let appearance = UITabBarItem.appearance(whenContainedInInstancesOf: [OutrunTabBar.self])
      appearance.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.gray], for: .normal)
      appearance.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.OutrunLaserBlue], for: .selected)
      tabBar.backgroundColor = UIColor.OutrunBlack
      
    }


    let selectWorkoutNavigationController = UINavigationController.init(rootViewController: SelectWorkoutViewController())
    selectWorkoutNavigationController.tabBarItem = UITabBarItem(tabBarSystemItem: .downloads, tag: 1)

    
    let settingsNavigationController = UINavigationController.init(rootViewController: SettingsViewController())
    settingsNavigationController.tabBarItem = UITabBarItem(tabBarSystemItem: .more, tag: 2)
    
    
    self.viewControllers = [profileNavigationController, selectWorkoutNavigationController, settingsNavigationController]

    
    self.selectedViewController = selectWorkoutNavigationController
    self.tabBar.barTintColor = UIColor.OutrunBlack
    self.tabBar.backgroundColor = UIColor.OutrunBlack
  }

}
