//
//  TransitionHistory.swift
//  DeepTransitionSample
//
//  Created by 森下 健 on 2014/12/22.
//  Copyright (c) 2014年 Yumemi. All rights reserved.
//

import Foundation

class TransitionHistory {
    private var histories = [TransitionPath]()
    
    func addHistory(path: TransitionPath) {
        histories.append(path)
        NSLog("add History: \(path.path)")
    }
    
    func back(size: Int) -> TransitionPath? {
        if size < 1 {
            return nil
        }
        
        for i in 0..<size {
            if self.histories.count > 0 {
                self.histories.removeLast()
            }
        }
        return self.histories.last
    }
    
    func history() -> [TransitionPath] {
        return histories.reverse()
    }
    
    func clearAll() {
        self.histories.removeAll(keepCapacity: false)
    }
}
