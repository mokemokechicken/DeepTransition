//
//  TransitionGraphModelTest.swift
//  DeepTransitionSample
//
//  Created by 森下 健 on 2014/12/15.
//  Copyright (c) 2014年 Yumemi. All rights reserved.
//

import UIKit
import XCTest

import DeepTransitionExample
import DeepTransition

typealias SegueKind = TransitionPath.SegueKind
typealias ContainerKind = TransitionPath.ContainerKind

class TransitionPathTest: XCTestCase {
    let obj = TransitionPath(path: "")

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSplitPath_1() {
        let pl = obj.splitPath("/top")
        XCTAssertEqual(1, pl.count)
        checkSamePathComponent(target: pl.first, id: "top", kind: SegueKind.Show, root: .Navigation, params: nil)
    }

    func testSplitPath_2() {
        let pl = obj.splitPath("/top/news(id=10)")
        XCTAssertEqual(2, pl.count)
        checkSamePathComponent(target: pl.first, id: "top", kind: SegueKind.Show, root: .Navigation, params: nil)
        checkSamePathComponent(target: pl.last, id: "news", kind: SegueKind.Show, params: ["id":"10"])
    }

    func testSplitPath_3() {
        let pl = obj.splitPath("/top#coupon!show(id=10,shop=5)")
        XCTAssertEqual(3, pl.count)
        if pl.count > 0 {
            checkSamePathComponent(target: pl[0], id: "top", kind: SegueKind.Show, root: .Navigation, params: nil)
        }
        if pl.count > 1 {
            checkSamePathComponent(target: pl[1], id: "coupon", kind: SegueKind.Tab, params: nil)
        }
        if pl.count > 2 {
            checkSamePathComponent(target: pl[2], id: "show", kind: SegueKind.Modal, params: ["id":"10", "shop":"5"])
        }
    }

    func testSplitPath_4() {
        let pl = obj.splitPath("/top!/menu#/settings")
        XCTAssertEqual(3, pl.count)
        if pl.count > 0 {
            checkSamePathComponent(target: pl[0], id: "top", kind: SegueKind.Show, root: .Navigation, params: nil)
        }
        if pl.count > 1 {
            checkSamePathComponent(target: pl[1], id: "menu", kind: SegueKind.Modal, root: .Navigation, params: nil)
        }
        if pl.count > 2 {
            checkSamePathComponent(target: pl[2], id: "settings", kind: SegueKind.Tab, root: .Navigation, params: nil)
        }
    }

    func testSplitPath_5() {
        let pl = obj.splitPath("!menu!/home/follows")
        XCTAssertEqual(3, pl.count)
        if pl.count > 0 {
            checkSamePathComponent(target: pl[0], id: "menu", kind: SegueKind.Modal, root: .None, params: nil)
        }
        if pl.count > 1 {
            checkSamePathComponent(target: pl[1], id: "home", kind: SegueKind.Modal, root: .Navigation, params: nil)
        }
        if pl.count > 2 {
            checkSamePathComponent(target: pl[2], id: "follows", kind: SegueKind.Show, root: .None, params: nil)
        }
    }

    func testSplitPath_6() {
        let pl = obj.splitPath("!menu#/home/follows")
        XCTAssertEqual(3, pl.count)
        if pl.count > 0 {
            checkSamePathComponent(target: pl[0], id: "menu", kind: SegueKind.Modal, root: .None, params: nil)
        }
        if pl.count > 1 {
            checkSamePathComponent(target: pl[1], id: "home", kind: SegueKind.Tab, root: .Navigation, params: nil)
        }
        if pl.count > 2 {
            checkSamePathComponent(target: pl[2], id: "follows", kind: SegueKind.Show, root: .None, params: nil)
        }
    }

    func checkSamePathComponent(target t: TransitionPathComponent!, id: String, kind: SegueKind, root: ContainerKind = ContainerKind.None, params p: [String:String]? = nil) {
        if t == nil {
            XCTAssert(false, "Target Object is nil!")
            return
        }
        var params = p ?? [String:String]()
        XCTAssertEqual(id, t.identifier)
        XCTAssertEqual(kind, t.segueKind)
        XCTAssertEqual(params, t.params)
        XCTAssertEqual(root, t.ownRootContainer)
    }
    
    typealias T = TransitionPath.Token
    func testTokenize() {
        
        XCTAssertEqual([T.KindShow, T.VC("top"), T.KindShow, T.VC("news"), T.End], obj.tokenize("/top/news"))
        XCTAssertEqual([T.KindShow, T.VC("top"), T.KindModal, T.KindShow, T.VC("menu"),T.KindShow, T.VC("settings"), T.KindTab, T.VC("prof"), T.End], obj.tokenize("/top!/menu/settings#prof"))
        XCTAssertEqual([T.KindShow, T.VC("top"), T.KindShow, T.VC("news"),T.KindShow, T.VC("show"),
            T.ParamKey("id"), T.ParamValue("10"),
            T.ParamKey("url"),T.ParamValue("http://hoge.com/mu?hoge=10#jj"), T.End],
            obj.tokenize("/top/news/show(id=10,url=http://hoge.com/mu?hoge=10#jj)"))
    }
    
    func testDiff_1() {
        let path1 = TransitionPath(path: "/a/b/c")
        let path2 = TransitionPath(path: "/a/b/e/f")
        let (common, d1, d2) = TransitionPath.diff(path1: path1, path2: path2)
        XCTAssertEqual(2, common.depth)
        XCTAssertEqual(1, d1.count)
        XCTAssertEqual(2, d2.count)
        XCTAssertEqual("a", common.componentList[0].identifier)
        XCTAssertEqual("b", common.componentList[1].identifier)
        XCTAssertEqual("c", d1[0].identifier)
        XCTAssertEqual("e", d2[0].identifier)
        XCTAssertEqual("f", d2[1].identifier)
    }

    func testDiff_2() {
        let path1 = TransitionPath(path: "/a(id=1)/b(id=3)/c")
        let path2 = TransitionPath(path: "/a(id=1)/b(id=4)/e/f")
        let (common, d1, d2) = TransitionPath.diff(path1: path1, path2: path2)
        XCTAssertEqual(1, common.depth)
        XCTAssertEqual(2, d1.count)
        XCTAssertEqual(3, d2.count)
        XCTAssertEqual("a", common.componentList[0].identifier)
        XCTAssertEqual("b", d1[0].identifier)
        XCTAssertEqual("id=3", d1[0].paramString())
        XCTAssertEqual("c", d1[1].identifier)
        XCTAssertEqual("b", d2[0].identifier)
        XCTAssertEqual("id=4", d2[0].paramString())
        XCTAssertEqual("e", d2[1].identifier)
        XCTAssertEqual("f", d2[2].identifier)
    }
    
    func testDiff_3() {
        let path1 = TransitionPath(path: "")
        let path2 = TransitionPath(path: "/a/b")
        let (common, d1, d2) = TransitionPath.diff(path1: path1, path2: path2)
        XCTAssertEqual(0, common.depth)
        XCTAssertEqual(0, d1.count)
        XCTAssertEqual(2, d2.count)
        XCTAssertEqual("a", d2[0].identifier)
        XCTAssertEqual("b", d2[1].identifier)
    }

    func testDiff_4() {
        let path1 = TransitionPath(path: "/top")
        let path2 = TransitionPath(path: "/top/list_news")
        let (common, d1, d2) = TransitionPath.diff(path1: path1, path2: path2)
        XCTAssertEqual(1, common.depth)
        XCTAssertEqual(0, d1.count)
        XCTAssertEqual(1, d2.count)
        XCTAssertEqual("top", common.componentList[0].identifier)
        XCTAssertEqual("list_news", d2[0].identifier)
    }
    
    func testDiff_5() {
        let path1 = TransitionPath(path: "/top/home#profile/help")
        let path2 = TransitionPath(path: "/top/home#profile")
        let (common, d1, d2) = TransitionPath.diff(path1: path1, path2: path2)
        XCTAssertEqual(3, common.depth)
        XCTAssertEqual(1, d1.count)
        XCTAssertEqual(0, d2.count)
        XCTAssertEqual("top", common.componentList[0].identifier)
        XCTAssertEqual("home", common.componentList[1].identifier)
        XCTAssertEqual("profile", common.componentList[2].identifier)
        XCTAssertEqual("help", d1[0].identifier)
    }
    
    func testComponentListToPath_1() {
        var path = ""
        path = "/a/b/c"; XCTAssertEqual(path, TransitionPath.componentListToPath(TransitionPath(path: path).componentList))
        path = ""; XCTAssertEqual(path, TransitionPath.componentListToPath(TransitionPath(path: path).componentList))
        path = "!a"; XCTAssertEqual(path, TransitionPath.componentListToPath(TransitionPath(path: path).componentList))
        path = "!a!b!/c"; XCTAssertEqual(path, TransitionPath.componentListToPath(TransitionPath(path: path).componentList))
        path = "!a#b!/c"; XCTAssertEqual(path, TransitionPath.componentListToPath(TransitionPath(path: path).componentList))
        path = "!a#/b!/c(id=10,url=http://hoge.com/hoge?ud=10#jjj)/ddx"; XCTAssertEqual(path, TransitionPath.componentListToPath(TransitionPath(path: path).componentList))
    }
    
    func testAppendPath_1() {
        var basePath = TransitionPath(path: "")
        XCTAssertEqual("/top/profile", basePath.appendPath(TransitionPath(path: "/top/profile")).path)
        XCTAssertEqual("!top/profile", basePath.appendPath(TransitionPath(path: "!top/profile")).path)
    }
    
    func testRelativeTo_root() {
        var basePath = TransitionPath(path: "")
        XCTAssertEqual("/top", basePath.relativeTo("top").path)
        XCTAssertEqual("/top", basePath.relativeTo("/top").path)
        XCTAssertEqual("/top/profile", basePath.relativeTo("top/profile").path)
        XCTAssertEqual("!top/profile", basePath.relativeTo("!top/profile").path)
        XCTAssertEqual("", basePath.relativeTo("..").path)
        XCTAssertEqual("/profile", basePath.relativeTo("../profile").path)
        XCTAssertEqual("/profile", basePath.relativeTo("../../profile").path)
        XCTAssertEqual("!profile", basePath.relativeTo("..!profile").path)
        XCTAssertEqual("!profile", basePath.relativeTo("..!..!profile").path)
        XCTAssertEqual("/top/profile", basePath.relativeTo("^/top/profile").path)
        XCTAssertEqual("!top/profile", basePath.relativeTo("^!top/profile").path)
    }

    func testRelativeTo_1depth() {
        var basePath = TransitionPath(path: "/top")
        XCTAssertEqual("/top/top", basePath.relativeTo("top").path)
        XCTAssertEqual("/top/top", basePath.relativeTo("/top").path)
        XCTAssertEqual("/top#top", basePath.relativeTo("#top").path)
        XCTAssertEqual("/top/top/profile", basePath.relativeTo("top/profile").path)
        XCTAssertEqual("/top!top/profile", basePath.relativeTo("!top/profile").path)
        XCTAssertEqual("", basePath.relativeTo("..").path)
        XCTAssertEqual("/profile", basePath.relativeTo("../profile").path)
        XCTAssertEqual("/profile", basePath.relativeTo("../../profile").path)
        XCTAssertEqual("!profile", basePath.relativeTo("..!profile").path)
        XCTAssertEqual("!profile", basePath.relativeTo("..!..!profile").path)
        XCTAssertEqual("/top/profile", basePath.relativeTo("^/top/profile").path)
        XCTAssertEqual("!top/profile", basePath.relativeTo("^!top/profile").path)
    }

    func testRelativeTo_2depth() {
        var basePath = TransitionPath(path: "/top!/friend")
        XCTAssertEqual("/top!/friend/top", basePath.relativeTo("top").path)
        XCTAssertEqual("/top!/friend/top", basePath.relativeTo("/top").path)
        XCTAssertEqual("/top!/friend#top", basePath.relativeTo("#top").path)
        XCTAssertEqual("/top!/friend/top/profile", basePath.relativeTo("top/profile").path)
        XCTAssertEqual("/top!/friend!top/profile", basePath.relativeTo("!top/profile").path)
        XCTAssertEqual("/top", basePath.relativeTo("..").path)
        XCTAssertEqual("/top/profile", basePath.relativeTo("../profile").path)
        XCTAssertEqual("/profile", basePath.relativeTo("../../profile").path)
        XCTAssertEqual("/top!profile", basePath.relativeTo("..!profile").path)
        XCTAssertEqual("!profile", basePath.relativeTo("..!..!profile").path)
        XCTAssertEqual("/top/profile", basePath.relativeTo("^/top/profile").path)
        XCTAssertEqual("!top/profile", basePath.relativeTo("^!top/profile").path)
    }

    func testRelativeTo_tab() {
        var basePath = TransitionPath(path: "/top/friend#list")
        XCTAssertEqual("/top/friend#list/top", basePath.relativeTo("top").path)
        XCTAssertEqual("/top/friend#list/top", basePath.relativeTo("/top").path)
        XCTAssertEqual("/top/friend#list#top", basePath.relativeTo("#top").path)
        XCTAssertEqual("/top/friend#list/top/profile", basePath.relativeTo("top/profile").path)
        XCTAssertEqual("/top/friend#list!top/profile", basePath.relativeTo("!top/profile").path)
        XCTAssertEqual("/top/friend", basePath.relativeTo("..").path)
        XCTAssertEqual("/top/friend/profile", basePath.relativeTo("../profile").path)  // ?? /top/profile ??
        XCTAssertEqual("/top/profile", basePath.relativeTo("../../profile").path)      // /profile ??
        XCTAssertEqual("/top/friend!profile", basePath.relativeTo("..!profile").path)
        XCTAssertEqual("/top!profile", basePath.relativeTo("..!..!profile").path)
        XCTAssertEqual("/top/profile", basePath.relativeTo("^/top/profile").path)
        XCTAssertEqual("!top/profile", basePath.relativeTo("^!top/profile").path)
    }
}
