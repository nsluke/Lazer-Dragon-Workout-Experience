//
//  OutrunPickerView.swift
//  CodeDump
//
//  Created by Luke Solomon on 5/11/20.
//  Copyright © 2020 Observatory. All rights reserved.
//

import UIKit


enum OutrunPickerType {
  case IntervalLength
  case RestLength
  case IntervalCount
  case SetCount
}


class OutrunPickerView:UIPickerView {
  
  var outrunPickerViewType:OutrunPickerType?
  
}
