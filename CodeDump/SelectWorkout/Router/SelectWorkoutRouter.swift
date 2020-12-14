//
// Created by VIPER
// Copyright (c) 2020 VIPER. All rights reserved.
//

import UIKit

class SelectWorkoutRouter: SelectWorkoutRouterProtocol {
  
  class func presentSelectWorkoutModule() -> SelectWorkoutView {
    // Generating module components
    let view = SelectWorkoutView()
    let presenter: SelectWorkoutPresenterProtocol & SelectWorkoutInteractorOutputProtocol = SelectWorkoutPresenter()
    let interactor: SelectWorkoutInteractorInputProtocol = SelectWorkoutInteractor()
    let router: SelectWorkoutRouterProtocol = SelectWorkoutRouter()
    
    // Connecting
    view.presenter = presenter
    presenter.view = view
    presenter.router = router
    presenter.interactor = interactor
    interactor.presenter = presenter
    
    return view
  }
  
  func presentWorkoutDetailScreen(from view: SelectWorkoutViewProtocol, forWorkout workout: WorkoutModel) {
    let previewWorkoutView = PreviewWorkoutRouter.presentPreviewWorkoutModule(fromView: view, forWorkout: workout)
 
      if let sourceView = view as? UIViewController {
         sourceView.navigationController?.pushViewController(previewWorkoutView, animated: true)
      }
  }
  
}
