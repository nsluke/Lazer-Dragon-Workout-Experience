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



class RoutineDesignerView:UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let view: some View = RoutineDesignerSwiftUIView()
    let hostingController = UIHostingController(rootView: view)
    self.addChild(hostingController)
  }
    
}


struct RoutineDesignerSwiftUIView:View {
  @State private var healthData:HealthData
  var numberOfSteps:Int {
    return healthData.steps
  }
  
  var body: some View {
    VStack {
      Text(String(numberOfSteps))
    }
  }
  .onAppear {
    
  }
}

struct RoutineDesignerSwiftUIView_Previews: PreviewProvider {
  static var previews: some View {
    RoutineDesignerSwiftUIView()
  }
}
