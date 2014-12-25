//
//  TransitionServiceLocator.swift
//  DeepTransitionSample
//
//  Created by 森下 健 on 2014/12/18.
//  Copyright (c) 2014年 Yumemi. All rights reserved.
//

import Foundation

public class _TransitionServiceLocater {
    public init() {
        self.transitionCenter = TransitionCenter()
    }
    public var transitionCenter : TransitionCenterProtocol
}

public var TransitionServiceLocater = _TransitionServiceLocater()


