//
// Created by VIPER
// Copyright (c) 2020 VIPER. All rights reserved.
//

import Foundation

class PreviewWorkoutPresenter {

  weak var view: PreviewWorkoutViewProtocol?
  var router: PreviewWorkoutRouterProtocol?

}

extension PreviewWorkoutPresenter: PreviewWorkoutPresenterProtocol {
  func doneButtonTapped(workout: WorkoutModel) {
    self.router?.presentWorkoutScreen(from: self.view!, forWorkout: workout)
  }
}
