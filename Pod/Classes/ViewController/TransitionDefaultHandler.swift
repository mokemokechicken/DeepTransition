//
//  TreeTransitionViewController.swift
//  DeepTransitionSample
//
//  Created by 森下 健 on 2014/12/13.
//  Copyright (c) 2014年 Yumemi. All rights reserved.
//

import UIKit


public class TransitionDefaultHandler : TransitionAgentDelegate {
    private weak var delegate : UIViewController?
    public private(set) var transitionPath : TransitionPath
    private var transition : TransitionCenterProtocol { return TransitionServiceLocater.transitionCenter }

    public init(viewController: UIViewController?, path: TransitionPath) {
        self.delegate = viewController
        self.transitionPath = path
    }
    
    public func removeViewController(pathComponent: TransitionPathComponent) -> Bool {
        var removed = false
        if let modal = delegate?.presentedViewController {
            modal.dismissViewControllerAnimated(true, nil)
            removed = true
        }
        
        if let navi = delegate?.navigationController {
            if contains(navi.viewControllers as? [UIViewController] ?? [], delegate!) {
                navi.popToViewController(delegate!, animated: true)
                removed = true
            }
        }
        
        switch pathComponent.segueKind {
        case .Show, .Modal:
            if removed {
                transition.reportFinishedRemoveViewControllerFrom(transitionPath)
                return true
            }
            
        case .Tab:
            transition.reportFinishedRemoveViewControllerFrom(transitionPath)
            return true
        }
        return false
    }
    
    public func decideViewController(pathComponent: TransitionPathComponent) -> UIViewController? {
        if let handler = (delegate as? TransitionAgentDelegate)?.decideViewController {
            return handler(pathComponent)
        } else {
            switch delegate? {
            case let .Some(tab as UITabBarController):
                var innerVC = tab.findViewControllerInCollection(pathComponent.identifier)
                return innerVC?.vc

            default:
                return delegate?.storyboard?.instantiateViewControllerWithIdentifier(pathComponent.identifier) as? UIViewController
            }
        }
    }
    
    public func showViewController(vc: UIViewController, pathComponent: TransitionPathComponent) -> Bool {
        if let handler = (delegate as? TransitionAgentDelegate)?.showViewController {
            return handler(vc, pathComponent: pathComponent)
        } else {
            return (delegate?.navigationController?.pushViewController(vc, animated: true)) != nil
        }
    }
    
    public func showModalViewController(vc: UIViewController, pathComponent: TransitionPathComponent) -> Bool {
        if let handler = (delegate as? TransitionAgentDelegate)?.showModalViewController {
            return handler(vc, pathComponent: pathComponent)
        } else {
            if pathComponent.ownRootContainer == .Navigation {
                let nav = UINavigationController(rootViewController: vc)
                delegate?.presentViewController(nav, animated: true) {}
            } else {
                delegate?.presentViewController(vc, animated: true) {}
            }
            return true
        }
    }
    
    public func showInternalViewController(vc: UIViewController, pathComponent: TransitionPathComponent) -> Bool {
        if let handler = (delegate as? TransitionAgentDelegate)?.showInternalViewController {
            return handler(vc, pathComponent: pathComponent)
        } else {
            switch delegate? {
            case let .Some(tab as UITabBarController):
                if let innerVC = tab.findViewControllerInCollection(pathComponent.identifier) {
                    tab.selectedIndex = innerVC.index
                    innerVC.vc.reportViewDidAppear()
                    return true
                }
            default:
                break
            }
        }
        return false
    }
    
    public func addViewController(pathComponent: TransitionPathComponent) -> Bool {
        if let vc = decideViewController(pathComponent) {
            vc.setupAgent(transitionPath.appendPath(component: pathComponent))
            
            switch pathComponent.segueKind {
            case .Show:
                return showViewController(vc, pathComponent: pathComponent)
                
            case .Modal:
                return showModalViewController(vc, pathComponent: pathComponent)
                
            case .Tab:
                return showInternalViewController(vc, pathComponent: pathComponent)
            }
        }
        return false
    }
    
}

