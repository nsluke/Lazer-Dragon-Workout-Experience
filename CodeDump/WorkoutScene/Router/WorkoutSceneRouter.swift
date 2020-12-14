//
// Created by Luke Solomon
// Copyright (c) 2020 Luke Solomon. All rights reserved.
//

import Foundation

class WorkoutSceneRouter {}

// PRESENTER -> ROUTER
extension WorkoutSceneRouter: WorkoutSceneRouterProtocol {
  class func presentWorkoutSceneModule(fromView view: AnyObject) -> WorkoutSceneView {
    // Generating module components
    let view = WorkoutSceneView()
    let presenter: WorkoutScenePresenterProtocol = WorkoutScenePresenter()
    let router: WorkoutSceneRouterProtocol = WorkoutSceneRouter()
    
    // Connecting
    view.presenter = presenter
    presenter.view = view
    presenter.router = router
    
    return view
  }
}
