//
//  IntervalPickerDataSource.swift
//  CodeDump
//
//  Created by Luke Solomon on 5/11/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import UIKit

protocol WorkoutPickerDelegate {
  func valueChanged(in picker:UIPickerView, toNewValue:Int)
}

// =================== Interval Length =================== //
class WorkoutPickerHandler:NSObject {
  private var pickerView:OutrunPickerView
  private var items = Array(stride(from: 5, to: 65, by: 5))  // ["5","10","15","20","25","30","35","40","45","50","55","60"]
  private var intervals = Array(stride(from: 1, to: 11, by: 1)) // ["1","2","3","4","5","6","7","8","9","10"]
  var delegate:WorkoutPickerDelegate

  init(pickerView: OutrunPickerView, workoutPickerDelegate:WorkoutPickerDelegate) {
      self.pickerView = pickerView
    self.delegate = workoutPickerDelegate
  }
}

extension WorkoutPickerHandler : UIPickerViewDataSource {
  func numberOfComponents(in pickerView: UIPickerView) -> Int {
    return 1
  }

  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    switch self.pickerView.outrunPickerViewType {
    case .IntervalLength:
      return items.count
    case .RestLength:
      return items.count
    case .IntervalCount:
      return intervals.count
    case .SetCount:
      return intervals.count
    default:
      return 0
    }
  }
}

extension WorkoutPickerHandler: UIPickerViewDelegate {
  func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
    var pickerLabel = view as? UILabel;
    if (pickerLabel == nil) {
      pickerLabel = UILabel()
      pickerLabel?.font = UIFont(name: OutrunFonts.Pixel.rawValue, size: 20) ?? UIFont.systemFont(ofSize: 30)
      pickerLabel?.textAlignment = .center
      pickerLabel?.textColor = UIColor.OutrunPaleYellow
    }

    switch self.pickerView.outrunPickerViewType {
    case .IntervalLength:
      pickerLabel?.text = String(items[row])
    case .RestLength:
      pickerLabel?.text = String(items[row])
    case .IntervalCount:
      pickerLabel?.text = String(intervals[row])
    case .SetCount:
      pickerLabel?.text = String(intervals[row])
    default:
      pickerLabel?.text = String(items[row])
    }

    return pickerLabel!;
  }
  
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    self.delegate.valueChanged(in: pickerView, toNewValue: row)
  }
  
}
