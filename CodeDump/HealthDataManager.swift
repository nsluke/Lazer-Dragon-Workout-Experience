//
//  HealthDataManager.swift
//  Livongo
//
//  Created by Luke Solomon on 7/20/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import Foundation
import HealthKit


final class HealthData:ObservableObject {
  var steps:Int
  var heartRate:Int
  
  init(steps: Int, heartRate: Int) {
    self.steps = steps
    self.heartRate = heartRate
  }
}

class HealthDataManager {
  
  static var shared = HealthDataManager()
  static var store = HKHealthStore()
  
  func requestAuthorization(completion: @escaping (Bool) -> ()) {
        
    guard HKHealthStore.isHealthDataAvailable() else {
      completion(false)
      return
    }

    let healthKitTypesToRead: Set<HKObjectType> = [HKObjectType.quantityType(forIdentifier: .stepCount)!]
    
    HKHealthStore().requestAuthorization(toShare: nil, read: healthKitTypesToRead) { (success, error) in
      completion(success)
      return
    }
  }
  
  
  func getStepCounts(completion: @escaping (Result<([HKQuantitySample]), Error>) -> ()) {
    
    guard HKHealthStore.isHealthDataAvailable() else{
      return
    }
    
    guard let stepsCountSampleType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
      assert("*** This method should never fail ***")
    }
    
    let stepQuery = HKSampleQuery.init(sampleType: stepsCountSampleType, predicate: nil, limit: 14, sortDescriptors: nil) {
      (query, results, error) in
      
      guard let samples = results as? [HKQuantitySample] else {
        // Handle any errors here.
        print("HealthDataManager: Error fetching step counts: \(String(describing: error?.localizedDescription))")
        completion(.failure(error!))
        return
      }

      completion(.success(samples))
    }
    HealthDataManager.store.execute(stepQuery)
  }
  
  
  
}
