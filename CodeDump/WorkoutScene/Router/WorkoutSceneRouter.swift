//
// Created by Luke Solomon
// Copyright (c) 2020 Luke Solomon. All rights reserved.
//

import UIKit

class WorkoutSceneRouter {}

// PRESENTER -> ROUTER
extension WorkoutSceneRouter: WorkoutSceneRouterProtocol {
  class func presentWorkoutSceneModule(fromView view: AnyObject, withWorkout workout:WorkoutModel) -> WorkoutSceneView {
    // Generating module components
    let view = WorkoutSceneView()
    let presenter: WorkoutScenePresenterProtocol & WorkoutSceneInteractorOutputProtocol = WorkoutScenePresenter()
    let router: WorkoutSceneRouterProtocol = WorkoutSceneRouter()
    let interactor:WorkoutSceneInteractor = WorkoutSceneInteractor()
    let dataManager = WorkoutSceneLocalDataManager()
    
    // Connecting
    view.presenter = presenter
    presenter.view = view
    presenter.router = router
    presenter.interactor = interactor
    interactor.localDatamanager = dataManager
    interactor.presenter = presenter
    dataManager.interactor = interactor
    dataManager.workout = workout
    view.title = workout.name
    
    return view
  }
  
  func handleEndWorkout(fromView view:WorkoutSceneViewProtocol) {
    if let sourceView = view as? UIViewController {
      sourceView.navigationController?.popToRootViewController(animated: true)
    }
  }
}
