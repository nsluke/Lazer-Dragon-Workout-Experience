//
//  OutrunTabBar.swift
//  CodeDump
//
//  Created by Luke Solomon on 5/15/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import UIKit

// Presenter
class OutrunTabBarPresenter: OutrunTabBarViewToPresenterProtocol {
    
    // MARK: - Properties
    weak var view:OutrunTabBarPresenterToViewProtocol?
    var interactor: OutrunTabBarPresentorToInteractorProtocol?
    var router: OutrunTabBarPresenterToRouterProtocol?
    
    // MARK: - Methods
    func updateView() {
//        interactor?.fetchLiveNews()
    }
}
// MARK: - LiveNewsListInteractorToPresenterProtocol
extension OutrunTabBarPresenter:OutrunTabBarInteractorToPresenterProtocol {
  
}

// Interactor
class OutrunTabBarInteractor : OutrunTabBarPresentorToInteractorProtocol {
  weak var presenter: OutrunTabBarInteractorToPresenterProtocol?
}

// Router
class OutrunTabBarRouter : OutrunTabBarPresenterToRouterProtocol {
  
  class func createModule() -> OutrunTabBar {
      let view = OutrunTabBar()
      let presenter: OutrunTabBarViewToPresenterProtocol & OutrunTabBarInteractorToPresenterProtocol = OutrunTabBarPresenter()
      let interactor: OutrunTabBarPresentorToInteractorProtocol = OutrunTabBarInteractor()
      let router: OutrunTabBarPresenterToRouterProtocol = OutrunTabBarRouter()
      
      view.presenter = presenter
      presenter.view = view
      presenter.router = router
      presenter.interactor = interactor
      interactor.presenter = presenter
      
      return view
  }
}

//View
class OutrunTabBar: UITabBarController {
  var presenter:OutrunTabBarViewToPresenterProtocol?
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
//    profileNavigationController.tabBarItem.badgeColor = UIColor.OutrunLaserBlue
    
    if #available(iOS 13, *) {
      let appearance = UITabBarAppearance()
      appearance.stackedLayoutAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.gray]
      appearance.stackedLayoutAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.OutrunLaserBlue]
      appearance.stackedLayoutAppearance.normal.badgeBackgroundColor = UIColor.OutrunLaserBlue
      appearance.backgroundColor = UIColor.OutrunBlack
      tabBar.standardAppearance = appearance
      tabBar.isTranslucent = false
    } else {
      let appearance = UITabBarItem.appearance(whenContainedInInstancesOf: [OutrunTabBar.self])
      appearance.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.gray], for: .normal)
      appearance.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.OutrunLaserBlue], for: .selected)
      tabBar.backgroundColor = UIColor.OutrunBlack
    }

//    let profileNavigationController = UINavigationController.init(rootViewController: ProfileViewController())
//    profileNavigationController.tabBarItem = UITabBarItem(tabBarSystemItem: .contacts, tag: 0)

    let selectWorkoutView = SelectWorkoutRouter.presentSelectWorkoutModule()
    let selectWorkoutNavigationController = OutrunNavigationController(rootViewController: selectWorkoutView)
    selectWorkoutNavigationController.tabBarItem = UITabBarItem(title: "Workouts", image: UIImage(imageLiteralResourceName: "MuscleIcon"), tag: 1)

    
//    let settingsNavigationController = UINavigationController.init(rootViewController: SettingsViewController())
//    settingsNavigationController.tabBarItem = UITabBarItem(tabBarSystemItem: .more, tag: 2)
    
    
    self.viewControllers = [selectWorkoutNavigationController] //[profileNavigationController, selectWorkoutNavigationController, settingsNavigationController]

    
    self.selectedViewController = selectWorkoutNavigationController
    self.tabBar.barTintColor = UIColor.OutrunBlack
    self.tabBar.backgroundColor = UIColor.OutrunBlack
  }

}

extension OutrunTabBar: OutrunTabBarPresenterToViewProtocol {

}
