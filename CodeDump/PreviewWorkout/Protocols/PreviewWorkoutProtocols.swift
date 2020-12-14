//
// Created by VIPER
// Copyright (c) 2020 VIPER. All rights reserved.
//

import Foundation
import UIKit

// PRESENTER -> VIEW
protocol PreviewWorkoutViewProtocol: class {
  var presenter: PreviewWorkoutPresenterProtocol? { get set }
}

// PRESENTER -> ROUTER
protocol PreviewWorkoutRouterProtocol: class {
  static func presentPreviewWorkoutModule(fromView view: AnyObject, forWorkout workout: WorkoutModel) -> PreviewWorkoutView
  
  func presentWorkoutScreen(from view: PreviewWorkoutViewProtocol, forWorkout workout: WorkoutModel)
}

// VIEW -> PRESENTER
protocol PreviewWorkoutPresenterProtocol: class {
  var view: PreviewWorkoutViewProtocol? { get set }
  var router: PreviewWorkoutRouterProtocol? { get set }
  
  func doneButtonTapped(workout:WorkoutModel)
}
