//
// Created by VIPER
// Copyright (c) 2020 VIPER. All rights reserved.
//

import Foundation

class SelectWorkoutPresenter: SelectWorkoutPresenterProtocol, SelectWorkoutInteractorOutputProtocol {

  weak var view: SelectWorkoutViewProtocol?
  var interactor: SelectWorkoutInteractorInputProtocol?
  var router: SelectWorkoutRouterProtocol?
  
  
  
  // MARK: - View Input
  func viewDidLoad() {
    interactor?.fetchWorkouts()
  }
  
  func showWorkoutDetail(forWorkout workout: WorkoutModel) {
    router?.presentWorkoutDetailScreen(from: view!, forWorkout: workout)
  }
  
  
  // MARK: - Interactor Input
  func didFetchWorkouts(_ workouts: [WorkoutModel]) {
    view?.loadWorkouts(with: workouts)
  }
  
  func onError() {
    
  }
  
}
