//
//  ViewControllerPath.swift
//  DeepTransitionSample
//
//  Created by 森下 健 on 2014/12/15.
//  Copyright (c) 2014年 Yumemi. All rights reserved.
//

import Foundation


@objc public class TransitionPath : Printable, Equatable {
    public let path: String
    public private(set) var componentList = [TransitionPathComponent]()
    public var depth : Int { return componentList.count }

    public init(path: String) {
        self.path = path
        self.componentList = splitPath(path)
    }
    
    private init(componentList: [TransitionPathComponent]) {
        self.path = TransitionPath.componentListToPath(componentList)
        self.componentList = componentList
    }
    
    public func appendPath(#component: TransitionPathComponent) -> TransitionPath {
        return TransitionPath(componentList: self.componentList + [component])
    }

    public func appendPath(#list: [TransitionPathComponent]) -> TransitionPath {
        return TransitionPath(componentList: self.componentList + componentList)
    }

    public func appendPath(path: TransitionPath) -> TransitionPath {
        return TransitionPath(componentList: self.componentList + path.componentList)
    }
    
    public func up(depth: Int = 1) -> TransitionPath? {
        if depth <= self.depth {
            var list = [TransitionPathComponent]()
            for i in 0..<self.depth-depth {
                list.append(self.componentList[i])
            }
            return TransitionPath(componentList: list)
        }
        return nil
    }
    
    public func relativeTo(path: String, basePath: TransitionPath? = nil) -> TransitionPath {
        var base = basePath ?? self
        if path.hasPrefix("^") {
            return TransitionPath(path: path.substringFromIndex(advance(path.startIndex, 1)))
        }
        // 何個戻るか？ と そういうのを除去したPath文字列
        let info = howManyUp(path)
        var comList = [TransitionPathComponent]()
        for var i=0; i < (base.componentList.count-info.upCount); i++ {
            comList.append(base.componentList[i])
        }
        let retPath = TransitionPath(componentList: comList).path + info.remainPath

        return TransitionPath(path: retPath)
    }
    
    private func howManyUp(path: String, upCount: Int = 0, lastSegue: String? = nil) -> (upCount: Int, remainPath: String) {
        if path.isEmpty {
            return (upCount: upCount, remainPath: "")
        }
        if path.hasPrefix("..") {
            var segue:String?
            var cutCount = 2
            if path.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 2 {
                segue = String(path[advance(path.startIndex, 2)])
                cutCount = 3
            }
            return howManyUp(path.substringFromIndex(advance(path.startIndex, cutCount)), upCount: upCount+1, lastSegue: segue)
        } else {
            var retPath = (lastSegue ?? "") + path
            switch String(retPath[retPath.startIndex]) {
            case "/", "#", "!":
                break
            default:
                retPath = "/" + retPath
            }

            return (upCount: upCount, remainPath: retPath)
        }
    }
    
    public class func diff(#path1: TransitionPath, path2: TransitionPath) -> (common: TransitionPath, d1: [TransitionPathComponent], d2: [TransitionPathComponent]) {
        let minDepth = min(path1.depth, path2.depth)
        var common = [TransitionPathComponent]()
        var d1 = [TransitionPathComponent]()
        var d2 = [TransitionPathComponent]()

        var diffRootIndex = 0
        for i in 0..<minDepth {
            if path1.componentList[i] == path2.componentList[i] {
                common.append(path1.componentList[i])
                diffRootIndex = i+1
            } else {
                break
            }
        }

        for i1 in diffRootIndex..<path1.depth {
            d1.append(path1.componentList[i1])
        }
        for i2 in diffRootIndex..<path2.depth {
            d2.append(path2.componentList[i2])
        }
        return (TransitionPath(componentList: common), d1, d2)
    }
    
    public class func componentListToPath(componentList: [TransitionPathComponent]) -> String {
        if componentList.isEmpty {
            return ""
        }
        var str = ""
        for c in componentList  {
            str += c.description
        }
        return str
    }
    
    // MARK: Enums
    public enum SegueKind : String {
        case Show = "/"
        case Modal = "!"
        case Tab = "#"
    }
    
    public enum ContainerKind : String, Printable {
        case None = "None"
        case Navigation = "Navigation"
        
        public var description : String {
            return "ContainerKind.\(self.rawValue)"
        }
    }
    
    // MARK: Printable
    public var description: String { return path }
    
    // MARK: Private
    // Private なんだけど UnitTest用にPublic
    public func splitPath(path: String) -> [TransitionPathComponent] {
        var pathList = [TransitionPathComponent]()
        let tokens = tokenize(path)
        var alreadyHasNavigationController = false
        var ownContainer = ContainerKind.None
        var segue: SegueKind?
        var name: String? = nil
        var paramKey: String?
        var params = [String:String]()
        
        func addPath() {
            if let id = name {
                if let seg = segue {
                    pathList.append(TransitionPathComponent(identifier: id, segueKind: seg, params:params, ownRootContainer: ownContainer))
                    if !alreadyHasNavigationController && ownContainer == .Navigation {
                        alreadyHasNavigationController = true
                    }
                    name = nil
                    params = [String:String]()
                    segue = nil
                    ownContainer = .None
                }
            }
        }
        
        for token in tokens {
            switch token {
            case .KindShow:
                addPath()
                switch (alreadyHasNavigationController, segue) {
                case (_, .Some(.Modal)): // "!/"
                    ownContainer = .Navigation
                case (_, .Some(.Tab)):   // "#/"
                    ownContainer = .Navigation
                case (false, .None):
                    ownContainer = .Navigation
                    segue = .Show
                default:
                    segue = .Show
                }
            case .KindModal:
                addPath()
                segue = .Modal
                alreadyHasNavigationController = false
            case .KindTab:
                addPath()
                segue = .Tab
                
            case .VC(let n):
                name = n
                segue = segue ?? .Show
            case .ParamKey(let k): paramKey = k
            case .ParamValue(let v): if let k = paramKey { params[k] = v }
            case .End:
                addPath()
                break
            }
        }
        return pathList
    }
    
    
    private enum State {
        case Normal, ParamKey, ParamValue
    }
    
    public enum Token : Equatable, Printable {
        case VC(String)
        case ParamKey(String)
        case ParamValue(String)
        case KindShow, KindModal, KindTab
        case End
        
        public var description: String {
            switch self {
            case .VC(let s):
                return "VC(\(s))"
            case .ParamKey(let s):
                return "Key(\(s))"
            case .ParamValue(let s):
                return "Val(\(s))"
            case .KindShow:
                return "/"
            case .KindModal:
                return "!"
            case .KindTab:
                return "#"
            case .End:
                return "$"
            }
        }
    }
    
    public func tokenize(path: String) -> [Token] {
        var tokens = [Token]()
        var tstr: String?
        let end = "\u{0}"
        var state: State = .Normal
        
        
        func addToken(ch: String) {
            tstr = (tstr ?? "") + ch
        }
        
        for chara in (path+end) {
            let ch = String(chara)
            switch state {
            case .Normal:
                switch ch {
                case SegueKind.Show.rawValue:
                    if let t = tstr { tokens.append(Token.VC(t)); tstr = nil }
                    tokens.append(Token.KindShow)
                    
                case SegueKind.Modal.rawValue:
                    if let t = tstr { tokens.append(Token.VC(t)); tstr = nil }
                    tokens.append(Token.KindModal)
                    
                case SegueKind.Tab.rawValue:
                    if let t = tstr { tokens.append(Token.VC(t)); tstr = nil }
                    tokens.append(Token.KindTab)
                    
                case end:
                    if let t = tstr { tokens.append(Token.VC(t)); tstr = nil }
                    tokens.append(.End)
                    break
                case "(":
                    if let t = tstr { tokens.append(Token.VC(t)); tstr = nil }
                    state = .ParamKey
                default:
                    addToken(ch)
                }
            case .ParamKey:
                switch ch {
                case "=":
                    if let t = tstr { tokens.append(Token.ParamKey(t)); tstr = nil }
                    state = .ParamValue
                default:
                    addToken(ch)
                }
                
            case .ParamValue:
                switch ch {
                case ",":
                    if let t = tstr { tokens.append(Token.ParamValue(t)); tstr = nil }
                    state = .ParamKey
                case ")":
                    if let t = tstr { tokens.append(Token.ParamValue(t)); tstr = nil }
                    state = .Normal
                default:
                    addToken(ch)
                }
            }
        }
        return tokens
    }
    
}

public func ==(lhs: TransitionPath, rhs: TransitionPath) -> Bool {
    if lhs.depth == rhs.depth {
        for i in 0..<lhs.depth {
            if lhs.componentList[i] != rhs.componentList[i] {
                return false
            }
        }
        return true
    }
    return false
}


public func ==(lhs: TransitionPath.Token, rhs: TransitionPath.Token) -> Bool {
    switch (lhs, rhs) {
    case (.VC(let a), .VC(let b)) where a == b: return true
    case (.ParamKey(let a), .ParamKey(let b)) where a == b: return true
    case (.ParamValue(let a), .ParamValue(let b)) where a == b: return true
    case (.KindShow, .KindShow): return true
    case (.KindModal, .KindModal): return true
    case (.KindTab, .KindTab): return true
    case (.End, .End): return true
    default:
        return false
    }
}


public func ==(lhs: TransitionPathComponent, rhs: TransitionPathComponent) -> Bool {
    return lhs.isEqual(rhs)
}

@objc public class TransitionPathComponent : Printable, Equatable {
    public let segueKind: TransitionPath.SegueKind
    public let identifier: String
    public var params: [String:String]
    public let ownRootContainer: TransitionPath.ContainerKind
    
    public init(identifier: String, segueKind: TransitionPath.SegueKind, params:[String:String], ownRootContainer: TransitionPath.ContainerKind) {
        self.identifier  = identifier
        self.segueKind = segueKind
        self.params = params
        self.ownRootContainer = ownRootContainer
    }
    
    public func isEqual(other: TransitionPathComponent) -> Bool {
        return
            self.identifier == other.identifier &&
                self.segueKind == other.segueKind &&
                self.ownRootContainer == other.ownRootContainer &&
                self.paramString() == other.paramString()
    }
    
    public var description: String {
        var pstr = paramString()
        if !pstr.isEmpty {
            pstr = "(\(pstr))"
        }
        var ret = ""
        switch ownRootContainer {
        case .None:
            ret = "\(segueKind.rawValue)\(identifier)\(pstr)"
        case .Navigation:
            if segueKind != TransitionPath.SegueKind.Show {
                ret = "\(segueKind.rawValue)/\(identifier)\(pstr)"
            } else {
                ret = "\(segueKind.rawValue)\(identifier)\(pstr)"
            }
        }
        return ret
    }
    
    public func paramString() -> String {
        var kvList = [String]()
        for k in params.keys.array.sorted(<) {
            kvList.append("\(k)=\(params[k]!)")
        }
        return join(",", kvList)
    }
}

