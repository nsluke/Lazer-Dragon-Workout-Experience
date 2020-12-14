//
// Created by Luke Solomon
// Copyright (c) 2020 Luke Solomon. All rights reserved.
//

import Foundation

class WorkoutScenePresenter {
  // PRESENTER -> VIEW
  weak var view: WorkoutSceneViewProtocol?
  // PRESENTER -> INTERACTOR
  var interactor: WorkoutSceneInteractorInputProtocol?
  // PRESENTER -> ROUTER
  var router: WorkoutSceneRouterProtocol?
  
  init() {}
}

// VIEW -> PRESENTER
extension WorkoutScenePresenter: WorkoutScenePresenterProtocol {
  
}
// INTERACTOR -> PRESENTER
extension WorkoutScenePresenter: WorkoutSceneInteractorOutputProtocol {
  
}
