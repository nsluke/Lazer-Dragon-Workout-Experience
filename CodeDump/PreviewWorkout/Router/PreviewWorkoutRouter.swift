//
// Created by VIPER
// Copyright (c) 2020 VIPER. All rights reserved.
//

import Foundation

class PreviewWorkoutRouter: PreviewWorkoutRouterProtocol {
  
  class func presentPreviewWorkoutModule(fromView view: AnyObject, forWorkout workout: WorkoutModel) -> PreviewWorkoutView {
    // Generating module components
    let view = PreviewWorkoutView()
    let presenter: PreviewWorkoutPresenterProtocol = PreviewWorkoutPresenter()
    let router: PreviewWorkoutRouterProtocol = PreviewWorkoutRouter()
    
    // Connecting
    view.workout = workout
    view.presenter = presenter
    presenter.view = view
    presenter.router = router

    return view
  }
  
  func presentWorkoutScreen(from view: PreviewWorkoutViewProtocol, forWorkout workout: WorkoutModel) {
    // router time!
  }
  
}
