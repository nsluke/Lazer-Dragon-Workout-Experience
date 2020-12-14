//
// Created by Luke Solomon
// Copyright (c) 2020 Luke Solomon. All rights reserved.
//

import Foundation
import UIKit

class WorkoutSceneView: UIViewController {
  // VIEW -> PRESENTER
  var presenter: WorkoutScenePresenterProtocol?
}

// PRESENTER -> VIEW
extension WorkoutSceneView: WorkoutSceneViewProtocol {
  
}
