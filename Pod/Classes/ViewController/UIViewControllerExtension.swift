//
//  UIViewControllerExtension.swift
//  DeepTransitionSample
//
//  Created by 森下 健 on 2014/12/23.
//  Copyright (c) 2014年 Yumemi. All rights reserved.
//

import UIKit

@objc public protocol HasControllerName {
    optional var controllerName : String { get }
}

private var transitionAgentKey: UInt8 = 0

extension UIViewController : TransitionViewControllerProtocol, HasControllerName {
    public var transition : TransitionCenterProtocol { return TransitionServiceLocater.transitionCenter }
    public var transitionAgent: TransitionAgentProtocol? {
        get {
            return objc_getAssociatedObject(self, &transitionAgentKey) as? TransitionAgentProtocol
        }
        set {
            objc_setAssociatedObject(self, &transitionAgentKey, newValue, UInt(OBJC_ASSOCIATION_RETAIN))
        }
    }
    
    public func setupAgent(path: TransitionPath) {
        if self.transitionAgent?.transitionPath == path {
            return
        }
        
        transitionAgent = createTransitionAgent(path)
        transitionAgent!.delegate = self
        if transitionAgent!.delegateDefaultImpl == nil {
            transitionAgent!.delegateDefaultImpl = createTransitionDefaultHandler(path)
        }
    }
    
    public func viewDidShow() {
        reportViewDidAppear()
    }
    
    public func reportViewDidAppear() {
        if let path = transitionAgent?.transitionPath {
            mylog("reportViewDidAppear: \(path.path)")
            transition.reportViewDidAppear(path)
        }
    }
    
    public func createTransitionAgent(path: TransitionPath) -> TransitionAgentProtocol {
        return TransitionAgent(path: path)
    }
    
    public func createTransitionDefaultHandler(path: TransitionPath) -> TransitionAgentDelegate {
        return TransitionDefaultHandler(viewController: self, path: path)
    }
    
    public func getControllerName() -> String? {
        return (self as HasControllerName).controllerName
    }
}

extension UINavigationController {
    override public func viewDidShow() {
        super.viewDidShow()
        viewControllers?.last?.viewDidShow()
    }
}

private struct ViewControllerInContainer {
    let index : Int
    let name : String?
    let vc : UIViewController
}

extension UITabBarController {
    public func findViewControllerInCollection(name: String) -> (index: Int, vc: UIViewController)? {
        for vcInfo in rootViewControllersInCollection() {
            if vcInfo.name == name {
                return (index: vcInfo.index, vc: vcInfo.vc)
            }
        }
        return nil
    }
    
    public func setupAgentToInnerNameController() {
        if let path = self.transitionAgent?.transitionPath {
            for vcInfo in rootViewControllersInCollection() {
                if let name = vcInfo.name {
                    vcInfo.vc.setupAgent(path.appendPath(TransitionPath(path: "#\(name)")))
                }
            }
        }
    }
    
    private func findNotContainerViewController(vc: UIViewController!) -> UIViewController? {
        if vc == nil {
            return vc
        }
        
        switch vc {
        case let (nav as UINavigationController):
            return findNotContainerViewController(nav.viewControllers?.first as? UIViewController)
            
        default:
            return vc
        }
        
    }
    
    private func rootViewControllersInCollection() -> [ViewControllerInContainer] {
        var ret = [ViewControllerInContainer]()
        var index = 0
        for innerVC in viewControllers as? [UIViewController] ?? [] {
            if let vc = findNotContainerViewController(innerVC) {
                ret.append(ViewControllerInContainer(index: index, name: vc.getControllerName(), vc: vc))
            }
            index++
        }
        return ret
    }
    
}

private func mylog(s: String) {
    #if DEBUG
        NSLog(s)
    #endif
}
