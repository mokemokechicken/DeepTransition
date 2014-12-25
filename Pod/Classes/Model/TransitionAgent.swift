//
//  ViewControllerTransitionContext.swift
//  DeepTransitionSample
//
//  Created by 森下 健 on 2014/12/16.
//  Copyright (c) 2014年 Yumemi. All rights reserved.
//

import UIKit


@objc public protocol OwnTransitionAgent {
    var transitionAgent: TransitionAgentProtocol? { get set }
}

@objc public protocol TransitionAgentDelegate {
    /**
    * ViewControllerを作成する
    * 作成した ViewController に Agentに正しいPathを与えて設置する
    * その際ViewController階層に必ずAddすること。
    * viewDidAppearイベントをCenterに通知する (transitionCenter.reportViewDidAppear を呼ぶ)。
      基本的にはUIViewControllerのイベントの viewDidAppear内で行ってください。
    
    :param: pathComponent 追加したいViewControllerの情報
    
    :returns: 追加するつもりがあるならTrue、無いならFalse
    */
    optional func addViewController(pathComponent: TransitionPathComponent) -> Bool
    
    /**
    * 子供のViewControllerを非表示・除去して、transitionCenter.reportFinishedRemoveViewControllerFromを呼びます
    
    :param: pathComponent 削除するViewControllerの譲歩
    
    :returns: 削除できたらTrue, そうでなければFalse
    */
    optional func removeViewController(pathComponent: TransitionPathComponent) -> Bool
    

    /**
    * パラメータが変更された場合に呼ばれます
    
    :param: params 変更後のパラメータ
    */
    optional func onChangeParams(params: [String:String])
    
    /**
    このViewControllerが削除されてしまってOKかどうか。
    例えば、データ入力や決済中などの重要な状態ならFalseを返して画面遷移をしないようにできます。
    
    :param: nextPath 遷移しようとしている Path。
    
    :returns: 削除されてOKならTrue
    */
    optional func canDisappearNow(nextPath: TransitionPath) -> Bool
    
    ////// Customize Show Child ViewController

    /**
    カスタマイズメソッドです。
    主に デフォルト実装の addViewController から呼ばれます。
    追加したいViewControllerの情報から実際の ViewControllerのInstanceを返します。
    デフォルトでは Main Storyboard の Storyboard ID を参考に決定します。
    
    :param: pathComponent 追加したいViewControllerの情報
    
    :returns: 生成したViewController。 nilならば追加しないということになります。
    */
    optional func decideViewController(pathComponent: TransitionPathComponent)  -> UIViewController?
    
    /**
    カスタマイズメソッドです。
    通常のPush遷移("/")が指定されている時に呼ばれます。
    表示アニメーションを変更したい場合などに実装します。
    また、表示後は結果的に transitionCenter の reportViewDidAppear が呼ばれるようにしてください。
    通常は、 表示対象の ViewController の viewDidAppear で行っているので気にしなくても良いですが、そうでない場合は明示的に呼ぶように調整してください。
    
    :param: vc            表示するViewController
    :param: pathComponent 追加したいViewControllerの情報
    
    :returns: 処理を行ったならTrue
    */
    optional func showViewController(vc: UIViewController, pathComponent: TransitionPathComponent) -> Bool
    
    /**
    カスタマイズメソッドです。
    通常のModal遷移("!")が指定されている時に呼ばれます。
    表示アニメーションを変更したい場合などに実装します。
    また、表示後は結果的に transitionCenter の reportViewDidAppear が呼ばれるようにしてください。
    通常は、 表示対象の ViewController の viewDidAppear で行っているので気にしなくても良いですが、そうでない場合は明示的に呼ぶように調整してください。
    
    :param: vc            表示するViewController
    :param: pathComponent 追加したいViewControllerの情報
    
    :returns: 処理を行ったならTrue
    */
    optional func showModalViewController(vc: UIViewController, pathComponent: TransitionPathComponent) -> Bool

    /**
    カスタマイズメソッドです。
    内部ViewControllerの表示("#")が指定されている時に呼ばれます。
    また、表示後は結果的に transitionCenter の reportViewDidAppear が呼ばれるようにしてください。
    通常は、 表示対象の ViewController の viewDidAppear で行っているので気にしなくても良いですが、そうでない場合は明示的に呼ぶように調整してください。
    
    :param: vc            表示するViewController
    :param: pathComponent 追加したいViewControllerの情報
    
    :returns: 処理を行ったならTrue
    */
    optional func showInternalViewController(vc: UIViewController, pathComponent: TransitionPathComponent) -> Bool
}

@objc public protocol TransitionViewControllerProtocol : TransitionAgentDelegate, OwnTransitionAgent {
    /**
    自ViewControllerに TransitionAgent を設置します。
    
    :param: path TransitionAgent の TransitionPath
    */
    func setupAgent(path: TransitionPath)
}

@objc public protocol TransitionAgentProtocol {
    var transitionPath : TransitionPath { get }
    var params : [String:String]? { get}
    var delegate : TransitionAgentDelegate? { get set }
    var delegateDefaultImpl : TransitionAgentDelegate? { get set }

    func addViewController(pathComponent: TransitionPathComponent) -> Bool
    func removeViewController(pathComponent: TransitionPathComponent) -> Bool
    func changeParams(params: [String:String])
    func canDisappearNow(nextPath: TransitionPath) -> Bool
}

@objc public class TransitionAgent : TransitionAgentProtocol {
    public private(set) var transitionPath: TransitionPath
    public var params : [String:String]? {
        return pathComponent?.params
    }
    
    public weak var delegate : TransitionAgentDelegate?
    public var delegateDefaultImpl : TransitionAgentDelegate?

    private var pathComponent: TransitionPathComponent?
    var transition: TransitionCenterProtocol { return TransitionServiceLocater.transitionCenter }
    

    public init(path: TransitionPath) {
        self.pathComponent = path.componentList.last
        self.transitionPath = path
        transition.addAgent(self)
    }

    public convenience init(parentAgent: TransitionAgentProtocol, pathComponent: TransitionPathComponent) {
        self.init(path: parentAgent.transitionPath.appendPath(component: pathComponent))
    }
    
    //
    public func canDisappearNow(nextPath: TransitionPath) -> Bool {
        return delegate?.canDisappearNow?(nextPath) ?? delegateDefaultImpl?.canDisappearNow?(nextPath) ?? true
    }

    public func removeViewController(pathComponent: TransitionPathComponent) -> Bool {
        if let handler = delegate?.removeViewController {
            return handler(pathComponent)
        } else if let handler = delegateDefaultImpl?.removeViewController  {
            return handler(pathComponent)
        } else {
            return false
        }
    }
    
    public func addViewController(pathComponent: TransitionPathComponent) -> Bool {
        if let handler = delegate?.addViewController {
            return handler(pathComponent)
        } else if let handler = delegateDefaultImpl?.addViewController {
            return handler(pathComponent)
        } else {
            return false
        }
    }
    
    public func changeParams(params: [String : String]) {
        pathComponent?.params = params
        if let handler = delegate?.onChangeParams {
            handler(params)
        } else if let handler = delegateDefaultImpl?.onChangeParams {
            handler(params)
        }
    }
    
    // MARK: Private
    
    deinit {
        mylog("deinit Agent: \(self.transitionPath)")
    }
}

private func mylog(s: String?) {
    #if DEBUG
        if let str = s {
            NSLog(str)
        }
    #endif
}



