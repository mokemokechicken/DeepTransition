//
//  TransitionModel.swift
//  DeepTransitionSample
//
//  Created by 森下 健 on 2014/12/13.
//  Copyright (c) 2014年 Yumemi. All rights reserved.
//

//import "DeepTransitionSample-Bridging-Header.h"

import Foundation

public let TRANSITION_CENTER_EVENT_START_TRANSITION = "TRANSITION_CENTER_EVENT_START_TRANSITION"
public let TRANSITION_CENTER_EVENT_END_TRANSITION   = "TRANSITION_CENTER_EVENT_END_TRANSITION"


public protocol TransitionCenterProtocol {
    func addAgent(agent: TransitionAgentProtocol)
    func reportFinishedRemoveViewControllerFrom(path: TransitionPath)
    func reportViewDidAppear(path: TransitionPath)
    func reportTransitionError(reason: String?)
    
    // For Transition
    func to(destination: String)
    func changeParams(params: [String:String])
    func up()
    func up(depth: Int)
    
    // For Development
    var debugMode: Bool { get set }
}

@objc public class TransitionCenter : NSObject, TransitionCenterProtocol {
    public var debugMode:Bool = false {
        didSet {
            self._fsm.debugMode = self.debugMode
        }
    }
    private let _fsm : TransitionModel_TransitionModelFSM!
    
    public override init() {
        super.init()
        _fsm = TransitionModel_TransitionModelFSM(context: self)
    }
    
    // MARK: TransitionCenterProtocol
    public func reportFinishedRemoveViewControllerFrom(path: TransitionPath) {
        async_fsm { $0.finish_remove(path) }
    }
    
    public func reportViewDidAppear(path: TransitionPath) {
        async_fsm { $0.move(path) }
    }
    
    public func reportTransitionError(reason: String?) {
        let r = reason ?? ""
        mylog("TransitionError: \(r)")
        async_fsm { $0.stop() }
    }

    public func to(destination: String) {
        async_fsm { $0.request(destination) }
    }
    
    public func changeParams(params: [String : String]) {
        async_fsm { $0.request(params) }
    }
    
    private func to(destination: TransitionPath) {
        self.to("^\(destination.path)")
    }
    
    
    public func up() {up(1)}
    public func up(depth: Int) {
        if let path = currentPath.up(depth: depth) {
            self.to(path)
        }
    }
    
    // MARK: Agent Management
    //////////////////////////////////
    private var agents = [WeakAgent]()
    public func addAgent(agent: TransitionAgentProtocol) {
        mylog("Add Agent In Center: \(agent.transitionPath)")
        agents.append(WeakAgent(agent: agent))
    }
    
    private func findAgentOf(path: TransitionPath) -> TransitionAgentProtocol? {
        for c in agents {
            if path ==  c.agent?.transitionPath {
                return c.agent
            }
        }
        return nil
    }
    //////////////////////////////////

    public private(set) var currentPath = TransitionPath(path: "")
    private var startPath : TransitionPath?
    private var destPath : TransitionPath?
    private var addingInfo : AddingInfo?

    private struct AddingInfo {
        let tInfo : TransitionInfo
        let nextComponent: TransitionPathComponent
        let agent: TransitionAgentProtocol
    }
    
    private func async_fsm(block:(TransitionModel_TransitionModelFSM) -> Void) {
        dispatch_async(dispatch_get_main_queue()) {
            block(self._fsm)
        }
    }
    
    func onEntryIdle() {
        switch (startPath, destPath) {
        case (let .Some(s), let .Some(d)):
            mylog("Finish Transition FROM \(s) TO \(currentPath)")
            notifyChangeState(TRANSITION_CENTER_EVENT_END_TRANSITION, info: TransitionStateInfo(startPath: s, destinationPath: currentPath))
        default:
            break
        }
        destPath = nil
        startPath = nil
    }
    
    func onRequestConfirming(destination: AnyObject!) {
        switch destination? {
        case let .Some(x as String):
            destPath =  currentPath.relativeTo(x)
        case let .Some(x as TransitionPath):
            destPath = x
        case let .Some(x as [String : String]):
            async_fsm { $0.change(x) }
            return
        default:
            async_fsm { $0.cancel() }
            return
        }

        if destPath == currentPath {
            async_fsm { $0.cancel() }
            return
        }
        
        startPath = currentPath
        let tInfo = calcTransitionInfo()
        for context in self.caclWillRemoveContext(tInfo) {
            if !context.canDisappearNow(destPath!) { // これから消されるVCに消えて大丈夫か尋ねる
                async_fsm { $0.cancel() }
                return
            }
        }
        mylog("Start Transition FROM \(startPath!) TO \(destPath!)")
        notifyChangeState(TRANSITION_CENTER_EVENT_START_TRANSITION, info: TransitionStateInfo(startPath: startPath!, destinationPath: destPath!))
        async_fsm { $0.ok() }
    }
    
    func onChangeParams(params: [String:String]) {
        if let agent = findAgentOf(currentPath) {
            agent.changeParams(params)
        }
    }
    
    var removeTargetPath : TransitionPath?

    func onEntryRemoving() {
        let tInfo = calcTransitionInfo()
        if tInfo.oldComponentList.isEmpty {
            mylog("Skip Removing")
            async_fsm { $0.skip_removing() }
            return
        }
        
        var path : TransitionPath? = tInfo.commonPath
        while path != nil {
            if let agent = findAgentOf(path!) { // 大丈夫なら大元に消すように言う
                mylog("Sending RemoveChildRequest to '\(agent.transitionPath)'")
                removeTargetPath = path
                if agent.removeViewController(tInfo.oldComponentList.first!) {
                    return
                }
            }
            path = path!.up()
        }
        mylog("Can't send RemoveChildRequest to '\(tInfo.commonPath)'")
        async_fsm() { $0.stop() }
    }
    
    
    func isExpectedReporter(object: AnyObject!) -> Bool {
        let tInfo = calcTransitionInfo()
        if let path = object as? TransitionPath {
            if path == removeTargetPath {
                mylog("Change CurrentPath From \(currentPath.path) to \(tInfo.commonPath)")
                currentPath = tInfo.commonPath
                removeTargetPath = nil
                return true
            }
        }
        return false
    }

    func onEntryAdding() {
        // TODO: Tab系のVCでContainer系のRootじゃない場合はその親にRequestを投げる必要がある
        let tInfo = calcTransitionInfo()
        var path : TransitionPath? = tInfo.commonPath
        if let nextComponent = tInfo.newComponentList.first {
            while path != nil {
                if let agent = findAgentOf(path!) {
                    self.addingInfo = AddingInfo(tInfo: tInfo, nextComponent: nextComponent, agent: agent)
                    mylog("Sending AddChildRequest '\(agent.transitionPath)' += \(nextComponent.description)")
                    if agent.addViewController(nextComponent) {
                        return
                    }
                }
                path = path!.up()
            }
        }
        async_fsm { $0.stop() }
    }
    
    func isExpectedChild(object: AnyObject!) -> Bool {
        switch (addingInfo, object as? TransitionPath) {
        case(let .Some(ai), let .Some(path)):
            if path == currentPath.appendPath(component: ai.nextComponent) {
                return true
            }
        default:
            break
        }
        return false
    }
    
    func onMove(object: AnyObject!) {
        if let path = object as? TransitionPath {
            if path != currentPath {
                mylog("Change CurrentPath From \(currentPath.path) to \(path)")
                currentPath = path
            }
        }
    }
    
    func onEntryMoved() {
        addingInfo = nil
        if currentPath == destPath {
            async_fsm { $0.finish_transition() }
        } else {
            async_fsm { $0.add() }
        }
    }

    // MARK: Utility
    private func calcTransitionInfo() -> TransitionInfo {
        if destPath == nil {
            return TransitionInfo(commonPath: currentPath, newComponentList: [TransitionPathComponent](), oldComponentList: [TransitionPathComponent]())
        }
        
        let (commonPath, d1, d2) = TransitionPath.diff(path1: currentPath, path2: destPath!)
        return TransitionInfo(commonPath: commonPath, newComponentList: d2, oldComponentList: d1)
    }
    
    private func caclWillRemoveContext(tInfo: TransitionInfo) -> [TransitionAgentProtocol] {
        var ret = [TransitionAgentProtocol]()
        var path = tInfo.commonPath
        for willRemoved in tInfo.oldComponentList {
            path = path.appendPath(component: willRemoved)
            if let agent = findAgentOf(path) {
                ret.append(agent)
            }
        }
        return ret
    }

    private func notifyChangeState(eventName: String, info: TransitionStateInfo) {
        var userInfo = ["info": info]
        NSNotificationCenter.defaultCenter().postNotificationName(eventName, object: self, userInfo: userInfo)
    }
    
    private func mylog(s: String?) {
        if !debugMode { return }
        if let str = s {
            NSLog(str)
        }
    }
    
    


}

public class TransitionStateInfo {
    public let startPath : TransitionPath
    public let destinationPath: TransitionPath
    
    init(startPath: TransitionPath, destinationPath: TransitionPath) {
        self.startPath = startPath
        self.destinationPath = destinationPath
    }
}


private class WeakAgent {
    private weak var agent:TransitionAgentProtocol?
    init(agent: TransitionAgentProtocol) {
        self.agent = agent
    }
}

private class TransitionInfo {
    private let commonPath : TransitionPath
    private let newComponentList : [TransitionPathComponent]
    private let oldComponentList : [TransitionPathComponent]
    
    private init(commonPath: TransitionPath, newComponentList: [TransitionPathComponent], oldComponentList: [TransitionPathComponent])  {
        self.commonPath = commonPath
        self.newComponentList = newComponentList
        self.oldComponentList = oldComponentList
    }
}





