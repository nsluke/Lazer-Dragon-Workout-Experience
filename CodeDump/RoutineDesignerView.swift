//
//  RoutineDesignerView.swift
//  CodeDump
//
//  Created by Luke Solomon on 12/21/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import Combine
import HealthKit


class RoutineDesignerView:UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let view: some View = RoutineDesignerSwiftUIView()
    let hostingController = UIHostingController(rootView: view)
    self.addChild(hostingController)
  }

}

struct RoutineDesignerSwiftUIView:View {
  
  private var healthDataManager:HealthDataManager?
  @State private var steps: [Step] = [Step]()
  
  init() {
    healthDataManager = HealthDataManager()
  }
  
  private func updateUIFromStatistics(_ statisticsCollection: HKStatisticsCollection) {
    let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    let endDate = Date()
    
    statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { (statistics, stop) in
      let count = statistics.sumQuantity()?.doubleValue(for: .count())
      let step = Step(count: Int(count ?? 0), date: statistics.startDate)
      steps.append(step)
    }
  }
  
  var body: some View {
    NavigationView {
      GraphView(steps: steps)
        .navigationTitle("Just Walking")
    }
    .onAppear {
      if let healthDataManager = healthDataManager {
        healthDataManager.requestAuthorization { success in
          if success {
            healthDataManager.calculateSteps { statisticsCollection in
              if let statisticsCollection = statisticsCollection {
                // update the UI
                updateUIFromStatistics(statisticsCollection)
              }
            }
          }
        }
      }
    }
  }
  
}

struct RoutineDesignerSwiftUIView_Previews: PreviewProvider {
  static var previews: some View {
    RoutineDesignerSwiftUIView()
  }
}
