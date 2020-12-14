//
// Created by Luke Solomon
// Copyright (c) 2020 Luke Solomon. All rights reserved.
//

import Foundation

// PRESENTER -> VIEW
protocol WorkoutSceneViewProtocol: class {
  var presenter: WorkoutScenePresenterProtocol? { get set }
  
  func updateTimer(time: String, remainingTime: String, elapsedTime: String)
  func updateStartStopButton(isPaused: Bool)
  func updateExerciseLabel(text: String)
}

// PRESENTER -> ROUTER
protocol WorkoutSceneRouterProtocol: class {
  static func presentWorkoutSceneModule(fromView view: AnyObject) -> WorkoutSceneView
}

// VIEW -> PRESENTER
protocol WorkoutScenePresenterProtocol: class {
  var view: WorkoutSceneViewProtocol? { get set }
  var interactor: WorkoutSceneInteractorInputProtocol? { get set }
  var router: WorkoutSceneRouterProtocol? { get set }
}

// INTERACTOR -> PRESENTER
protocol WorkoutSceneInteractorOutputProtocol: class {
  
}

// PRESENTER -> INTERACTOR
protocol WorkoutSceneInteractorInputProtocol: class {
  var presenter: WorkoutSceneInteractorOutputProtocol? { get set }
  var APIDataManager: WorkoutSceneAPIDataManagerInputProtocol? { get set }
  var localDatamanager: WorkoutSceneLocalDataManagerInputProtocol? { get set }
}

// INTERACTOR -> DATAMANAGER
protocol WorkoutSceneDataManagerInputProtocol: class {
  
}

// INTERACTOR -> APIDATAMANAGER
protocol WorkoutSceneAPIDataManagerInputProtocol: class {
  
}

// INTERACTOR -> LOCALDATAMANAGER
protocol WorkoutSceneLocalDataManagerInputProtocol: class {
  
}
