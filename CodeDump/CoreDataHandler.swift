//
//  CoreDataHandler.swift
//  CodeDump
//
//  Created by Luke Solomon on 5/13/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import Foundation
import UIKit
import CoreData
//import Combine


enum CoreDataHandlerError: Error {
  case fetchFailure
  case saveFailure
}


struct CoreDataHandler {  
  let persistentContainer:NSPersistentContainer!
  
  private static var dispatchQueue = DispatchQueue.init(
    label: "CoreDataMgr",
    qos: .background,
    attributes: .concurrent,
    autoreleaseFrequency: .inherit,
    target: .none
  )
  
  init(container: NSPersistentContainer) {
    self.persistentContainer = container
    self.persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
  }
  
  init() {
    //Use the default container for production environment
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
      fatalError("Can not get shared app delegate")
    }
    self.init(container: appDelegate.persistentContainer)
  }
  
  
  // =================================================================================
  //                                  MARK: - Save
  // =================================================================================
  
  func insertWorkouts(workoutModels:[WorkoutModel], completion: @escaping (Result<Bool, Error>) -> Void) {
    for workout in workoutModels {
      self.insertWorkout(workoutModel: workout, completion: { result in
        if case .failure(let error) = result {
          completion(.failure(error))
        } else {
          completion(.success(true))
        }
      })
    }
  }
  
  
  func insertWorkout(workoutModel:WorkoutModel, completion: @escaping (Result<Bool, Error>) -> Void) {
    guard let workout = NSEntityDescription.insertNewObject(forEntityName: "Workout", into: persistentContainer.viewContext) as? Workout else { return }
    workout.name = workoutModel.name
    workout.type = workoutModel.type.rawValue
    workout.length = Int16(workoutModel.length)
    
    workout.warmupLength = Int16(workoutModel.warmupLength)
    workout.intervalLength = Int16(workoutModel.intervalLength)
    workout.restLength = Int16(workoutModel.restLength)
    workout.restBetweenSetLength = Int16(workoutModel.restBetweenSetLength)
    
    workout.numberOfIntervals = Int16(workoutModel.numberOfIntervals)
    workout.numberOfSets = Int16(workoutModel.numberOfSets)
    workout.cooldownLength = Int16(workoutModel.cooldownLength)
    
    for exerciseModel in workoutModel.exercises {
      guard let exercise = NSEntityDescription.insertNewObject(forEntityName: "Exercise", into: persistentContainer.viewContext) as? Exercise else { return }
      exercise.image = exerciseModel.image.pngData()
      exercise.name = exerciseModel.name
      exercise.splitLength = Int16(exerciseModel.splitLength)
      workout.addToExercises(exercise)
    }
    
//    do {
//      try persistentContainer.viewContext.save()
//      completion(.success(true))
//    } catch let error as NSError {
//      print("CoreDataHandler could not save Workout - \(error) \(error.userInfo)")
//      completion(.failure(error))
//    }
  }
  
  
  func saveExercise(exerciseModel: ExerciseModel) {
    let exercise = NSEntityDescription.insertNewObject(forEntityName: "Exercise", into: persistentContainer.viewContext) as! Exercise
    exercise.image = exerciseModel.image.pngData()
    exercise.name = exerciseModel.name
    exercise.splitLength = Int16(exerciseModel.splitLength)
    
//    do {
////      try persistentContainer.viewContext.save()
//    } catch let error as NSError {
//      print("CoreDataHandler: could not save Exercise - \(error) \(error.userInfo)")
//    }
  }
  
  // =================================================================================
  //                                 MARK: - Fetch
  // =================================================================================

  func fetchWorkouts(completion: @escaping (Result<[Workout], Error>) -> Void) {
    CoreDataHandler.dispatchQueue.sync {
      let fetchRequest = NSFetchRequest<Workout>(entityName: "Workout")
      
      do {
        let workouts = try persistentContainer.viewContext.fetch(fetchRequest)
        let sortedWorkouts = workouts.sorted { (w1, w2) -> Bool in
          w1.intervalLength < w2.intervalLength
        }
        completion(.success(sortedWorkouts))
      } catch let error as NSError {
        print("CoreDataHandler: could not fetch workouts - \(error) \(error.userInfo)")
        completion(.failure(error))
      }
    }
  }
  
  func fetchWorkoutWithName(name: String, completion: @escaping (Result<Workout, Error>) -> Void) {
    let fetchRequest:NSFetchRequest<Workout> = Workout.fetchRequest()
    fetchRequest.predicate = NSPredicate(format: "name = %@", name)
    
    do {
      let workout = try persistentContainer.viewContext.fetch(fetchRequest).first
      if let safeWorkout = workout {
        completion(.success(safeWorkout))
      } else {
        completion(.failure(NSError(domain: "", code: 0, userInfo: nil)))
      }
    } catch let error as NSError {
      print("CoreDataHandler: could not fetch workout \(name) - \(error) \(error.userInfo)")
      completion(.failure(error))
    }
  }
  
  func fetchExercisesWithName(name: String, completion: @escaping (Result<[Exercise], Error>) -> Void) {
    CoreDataHandler.dispatchQueue.sync {
      let fetchRequest = NSFetchRequest<Exercise>(entityName: "Exercise")
      fetchRequest.predicate = NSPredicate(format: "workout.name = %@", name)
      
      do {
        let exercises = try persistentContainer.viewContext.fetch(fetchRequest)
        let sortedExercises = exercises.sorted { (e1, e2) -> Bool in
          e1.order < e2.order
        }
        completion(.success(sortedExercises))
      } catch let error as NSError {
        print("CoreDataHandler: could not fetch exercises - \(error) \(error.userInfo)")
        completion(.failure(error))
      }
    }
  }
  
  // =================================================================================
  //                                 MARK: - Delete
  // =================================================================================

  func deleteWorkoutWithName(name: String, completion: @escaping (Result<Bool, Error>) -> Void) {
    CoreDataHandler.dispatchQueue.sync {
      let fetchRequest:NSFetchRequest<Workout> = Workout.fetchRequest()
      fetchRequest.predicate = NSPredicate(format: "name = %@", name)
      
      do {
        if let workout = try persistentContainer.viewContext.fetch(fetchRequest).first {
          persistentContainer.viewContext.delete(workout)
  //        do {
  //          try persistentContainer.viewContext.save()
  //        } catch let error as NSError {
  //          print("CoreDataHandler: could not save context - \(error) \(error.userInfo)")
  //          completion(.failure(error))
  //        }
        } else {
          print("CoreDataHandler: could not delete workout, name not found?")
        }
        completion(.success(true))
        
      } catch let error as NSError {
        print("CoreDataHandler: could not delete workout \(name) - \(error) \(error.userInfo)")
        completion(.failure(error))
      }
    }
  }
  
  
  func saveContext(completion: @escaping () -> ()) {
    CoreDataHandler.dispatchQueue.sync {
      do {
        try persistentContainer.viewContext.save()
        completion()
      } catch let error as NSError {
        print("CoreDataHandler could not save Workouts - \(error) \(error.userInfo)")
      }
    }
  }
    
  // =================================================================================
  //                     MARK: - Memory OBJ to NSManagedObjects
  // =================================================================================

  func workoutModelsToWorkouts(workoutModels:[WorkoutModel]) -> [Workout] {
    var workouts = [Workout]()
    
    for workoutModel in workoutModels {
      let workout = Workout(context:  persistentContainer.viewContext)
      workout.name = workoutModel.name
      workout.type = workoutModel.type.rawValue
      workout.length = Int16(workoutModel.length)
      
      workout.warmupLength = Int16(workoutModel.warmupLength)
      workout.intervalLength = Int16(workoutModel.intervalLength)
      workout.restLength = Int16(workoutModel.restLength)
      workout.restBetweenSetLength = Int16(workoutModel.restBetweenSetLength)
      
      workout.numberOfIntervals = Int16(workoutModel.numberOfIntervals)
      workout.numberOfSets = Int16(workoutModel.numberOfSets)
      workout.cooldownLength = Int16(workoutModel.cooldownLength)
      //      workout.exercises = NSSet(array: workoutModel.exercises)
      for exerciseModel in workoutModel.exercises {
        let exercise = Exercise(context: persistentContainer.viewContext)
        exercise.order = Int16(exerciseModel.order)
        exercise.image = exerciseModel.image.pngData()
        exercise.name = exerciseModel.name
        exercise.splitLength = Int16(exerciseModel.splitLength)
        workout.addToExercises(exercise)
      }
      
      workouts.append(workout)
    }
    
    return workouts
  }
  
}
