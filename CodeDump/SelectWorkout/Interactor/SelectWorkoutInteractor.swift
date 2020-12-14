//
// Created by VIPER
// Copyright (c) 2020 VIPER. All rights reserved.
//

import Foundation

class SelectWorkoutInteractor: SelectWorkoutInteractorInputProtocol {
  
  weak var presenter: SelectWorkoutInteractorOutputProtocol?
  
  // MARK: - Presenter Input
  func fetchWorkouts() {
    DataHandler.shared.getWorkoutModels { [weak self] (result) in
      if case .success(let workouts) = result {
        DispatchQueue.main.async { [weak self] in
          self?.presenter?.didFetchWorkouts(workouts)
        }
      } else if case .failure = result {
        print("SelectWorkoutViewController - Error fetching Data for Table View")
      }
    }
  }
  
}
