//
// Created by VIPER
// Copyright (c) 2020 VIPER. All rights reserved.
//

import Foundation

protocol SelectWorkoutViewProtocol: class {
  var presenter: SelectWorkoutPresenterProtocol? { get set }
  /**
   *  PRESENTER -> VIEW
   */
  func viewDidLoad()
  func loadWorkouts(with workouts:[WorkoutModel])
}

protocol SelectWorkoutRouterProtocol: class {
  /**
   * PRESENTER -> ROUTER
   */
  static func presentSelectWorkoutModule() -> SelectWorkoutView
  func presentWorkoutDetailScreen(from view: SelectWorkoutViewProtocol, forWorkout workout: WorkoutModel)}

protocol SelectWorkoutPresenterProtocol: class {
  var view: SelectWorkoutViewProtocol? { get set }
  var interactor: SelectWorkoutInteractorInputProtocol? { get set }
  var router: SelectWorkoutRouterProtocol? { get set }
  /**
   * VIEW -> PRESENTER
   */
  func viewDidLoad()
  func showWorkoutDetail(forWorkout workout: WorkoutModel)
}

protocol SelectWorkoutInteractorOutputProtocol: class {
  /**
   * INTERACTOR -> PRESENTER
   */
  func didFetchWorkouts(_ workouts: [WorkoutModel])
}

protocol SelectWorkoutInteractorInputProtocol: class {
  var presenter: SelectWorkoutInteractorOutputProtocol? { get set }
  /**
   * PRESENTER -> INTERACTOR
   */
  func fetchWorkouts()
}
