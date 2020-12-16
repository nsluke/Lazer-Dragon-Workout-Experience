//
// Created by Luke Solomon
// Copyright (c) 2020 Luke Solomon. All rights reserved.
//

import Foundation



// PRESENTER -> VIEW
protocol WorkoutSceneViewProtocol: class {
  var presenter: WorkoutScenePresenterProtocol? { get set }
  
  func updateTimer(time: String, remainingTime: String, elapsedTime: String)
  func updateStartStopButton(text: String)
  func updateExerciseLabel(text: String)
}

// PRESENTER -> ROUTER
protocol WorkoutSceneRouterProtocol: class {
  static func presentWorkoutSceneModule(fromView view: AnyObject, withWorkout workout:WorkoutModel) -> WorkoutSceneView
  func handleEndWorkout(fromView view:WorkoutSceneViewProtocol)
}

// VIEW -> PRESENTER
protocol WorkoutScenePresenterProtocol: class {
  var view: WorkoutSceneViewProtocol? { get set }
  var interactor: WorkoutSceneInteractorInputProtocol? { get set }
  var router: WorkoutSceneRouterProtocol? { get set }
  
  func playPauseButtonTapped()
  func pauseWorkout()
  func resumeWorkout()
  func endButtonTapped()
  func previousExerciseButtonTapped()
  func nextExerciseButtonTapped()
}

// PRESENTER -> INTERACTOR
protocol WorkoutSceneInteractorInputProtocol: class {
  var presenter: WorkoutSceneInteractorOutputProtocol? { get set }
  
  func playPauseToggle()
  func pauseWorkout()
  func resumeWorkout()
  func endWorkout()
  func previousExercise()
  func nextExercise()
}

// INTERACTOR -> PRESENTER
protocol WorkoutSceneInteractorOutputProtocol: class {
  func handleResume()
  func handlePause()
  func handlePreviousExercise(exercise: ExerciseModel)
  func handleNextExercise(exercise: ExerciseModel)
  func updateTimer(time: String, remainingTime: String, elapsedTime: String)
  func updateStartStopButton(text: String)
  func updateExerciseLabel(text: String)
  func handleEndWorkout()
}

// INTERACTOR -> LOCALDATAMANAGER
protocol WorkoutSceneLocalDataManagerInputProtocol: class {
  var workout:WorkoutModel? { get set }
  var workoutState:WorkoutSegment { get set }

  func tick()
  func willTransitionToNext()
  func willTransitionToPrevious()
  func willStop()
  func willWarmup()
  func willInterval()
  func willRest()
  func willRestBetweenSets()
  func willCooldown()
  func willEnd()
  func fetchPreviousExercise()
  func fetchNextExercise()
  func fetchIsPlaying()
}

// LOCALDATAMANAGER -> INTERACTOR
protocol WorkoutSceneLocalDataManagerOutputProtocol: class {
  func onPreviousExerciseFetched(exercise: ExerciseModel)
  func onNextExerciseFetched(exercise: ExerciseModel)
  func onFetchIsPlaying(isPlaying:Bool)
  func onTick(remainingTime:Int)
  func handleShouldStop()
  func handleShouldWarmup(warmupLength:Int)
  func handleShouldInterval(exercise:ExerciseModel)
  func handleShouldRest(length:Int)
  func handleShouldRestBetweenSets(length:Int)
  func handleShouldCooldown(length:Int)
  func handleShouldEnd()
}
