//
//  RootTransitionContext.swift
//  DeepTransitionSample
//
//  Created by 森下 健 on 2014/12/16.
//  Copyright (c) 2014年 Yumemi. All rights reserved.
//


import UIKit

private var instance : RootTransitionAgent?

public class RootTransitionAgent : TransitionAgent {

    public class func create() -> RootTransitionAgent {
        return RootTransitionAgent(path: TransitionPath(path: ""))
    }
    
    public func start(destinaton: String) {
        transition.to(destinaton)
    }

    public func decideViewController(pathComponent: TransitionPathComponent) -> UIViewController? {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier(pathComponent.identifier) as? UIViewController
    }

    override public func removeViewController(pathComponent: TransitionPathComponent) -> Bool {
        transition.reportFinishedRemoveViewControllerFrom(transitionPath)
        return true
    }
    
    override public func addViewController(pathComponent: TransitionPathComponent) -> Bool  {
        let window = UIApplication.sharedApplication().delegate?.window
        let path = transitionPath.appendPath(component: pathComponent)
 
        if let vc = decideViewController(pathComponent) {
            if pathComponent.ownRootContainer == .Navigation {
                window??.rootViewController = UINavigationController(rootViewController: vc)
            } else {
                window??.rootViewController = vc
            }
            window??.makeKeyAndVisible()
            
            vc.setupAgent(path)
            transition.reportViewDidAppear(path)
            return true
        }
        return false
    }
    
    public func forever() -> RootTransitionAgent {
        instance = self
        return self
    }
}
