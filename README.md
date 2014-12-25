# DeepTransition

[![CI Status](http://img.shields.io/travis/Ken Morishita/DeepTransition.svg?style=flat)](https://travis-ci.org/Ken Morishita/DeepTransition)
[![Version](https://img.shields.io/cocoapods/v/DeepTransition.svg?style=flat)](http://cocoadocs.org/docsets/DeepTransition)
[![License](https://img.shields.io/cocoapods/l/DeepTransition.svg?style=flat)](http://cocoadocs.org/docsets/DeepTransition)
[![Platform](https://img.shields.io/cocoapods/p/DeepTransition.svg?style=flat)](http://cocoadocs.org/docsets/DeepTransition)

iOSのネイティブアプリにおいて、例えば直前の画面に戻るというのは簡単ですが、
ViewController階層の遠い画面に遷移するのは、
普通にやると途中のViewControllerに色々処理を書いて回る必要があったりして結構たいへんなものです。

他にも以下のようなことがしたいときがあります。

* Push通知から起動したときは、そのパラメータに応じて自動的にその画面を表示したい
* WebやWebViewのリンクから、アプリ内の特定の画面に遷移したい（対象の階層が深くても）。
* 画面遷移毎にGoogleAnalyticsなどで記録を行いたい

今回の仕組みはこれを簡単に行うためのルールとその実装です。

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

* Swift Only

## Installation

DeepTransition is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "DeepTransition"

仕様
======

簡単な使い方
-----------

* Main Storyboradの各ViewControllerに `Storyboard ID` を付けるようにします
* 各ViewControllerは TransitionViewController を継承するようにします
  * UITabBarController は TransitionTabBarController を継承するようにします
  * 外部既存クラスのため継承できない場合は、「TransitionViewControllerなどを継承できない場合」を見てください
* 遷移を行うときに `transition.to("list_news!show(id=9)")` などのMethodを使います
* 最初のViewControllerは RootTransitionAgent で指定します。

RootTransitionAgent
-----------

最初に表示するViewControllerは 特別に RootTransitionAgent （か継承した）Classを使って

`RootTransitionAgent.create().forever().start("^/top")`

のような記述を AppDelegate に書けば表示されます。

遷移の書き方
-------------
※ViewControllerをVCと書きます
### 例

* `user`, `/user`: 今のVCにNavigationControllerのPushで `user` というVCに遷移する
* `!user`: 今のVCに Modal(presentViewController) で `user`というVCを表示する
* `..`: 一つ上のVCに戻る
* `../freind`: 一つ上のVCから `friend` にPush遷移する
* `^/top`: `^` は絶対PATHを表しています。window の rootViewController に NavigationControllerを付けて`top`というVCを表示します
* `home#user`: home というVCの 内部VCのuserに遷移します

### 特別な遷移

* up(n=1): n個上のVCに戻ります。

### 記号

* `/`: NavigationController の Push による遷移
* `!`: ModalViewのような表示
* `#`: Tab のような内部ViewController
* パラメータ： `/top/news(category=10,offset=50)`  のように () で渡します。 agent の params Methodで参照できます。
* `!/`: ModalViewのような表示内で、更にNavigationControllerのコンテナを含みます

TransitionViewControllerを継承できない場合
---------------------
TransitionViewController の実装は以下のようなになっています。
その外部既存クラスを継承やextensionして、 `viewDidShow()` を呼ぶようにしてください。


```swift
public class TransitionViewController : UIViewController {
  override public func viewDidAppear(animated: Bool) {
    viewDidShow()
    super.viewDidAppear(animated)
  }
}
```

TransitionTabBarController を継承できない場合
--------------------
TransitionTabBarController の実装はいかのようになっています。
これを 継承やExtensionなどで実装してください。

```swift
public class TransitionTabBarController : UITabBarController {
  override public func viewDidAppear(animated: Bool) {
    setupAgentToInnerNameController()
    super.viewDidAppear(animated)
    viewDidShow()
    if (viewControllers?.count ?? 0) > selectedIndex {
      viewControllers?[selectedIndex].viewDidShow()
    }
  }
}
```

遷移の通知
---------

遷移のイベントを NSNotificationCenter に通知します。

* TRANSITION_CENTER_EVENT_START_TRANSITION： 遷移が開始された
* TRANSITION_CENTER_EVENT_END_TRANSITION： 遷移が終了した

カスタマイズや細かい実装上の注意
==========

UIViewControllerが行うこと
----------------

* 一つのViewControllerはMain Storyboard の`Storyboard ID`で識別されます。 この挙動は後述する `decideViewController` Methodを実装することで変更できます。
* その階層を '/top/list_news/show_news' というような形で指定します。この場合、 top -> list_news -> show_news という順でViewControllerがつながります。
* ページ遷移するときは、 `transition.to("/top/list_news")` などで行います。
* ViewControllerを追加する遷移がある場合は必ずそうしてください。
* ただし、Back（ViewControllerを除去する動作）などは、別の方法(NavigationControllerが自動で付けるもの)で行っても大丈夫です
* viewDidAppearをoverrideした時は必ず super を呼ぶ(これを忘れるとそれ以降遷移しなくなります)

### UITabBarController 内部ViewController

UITabBarController で内部で複数のViewControllerを扱う場合は、
そのVCの生成はFramework側では行わず、UITabBarController などで行うようにしてください（それが通常の動作だと思います）。
その子供のVCは `controllerName:String` という Propertyを定義することで、Framework側が探せるようになります（Storyboard IDからは探せない）。

Exampleの ProfileViewController.swift
などを参考にしてください。

### UITabBarController 内に新しく UINavigationController を配置するときの注意

UITabBarController 内部の UINavigationController は その管理下にある VCの viewDidAppear などをCallしてくれないようです。

Exampleの FriendListViewController.swift

のように、  UINavigationControllerDelegate を実装して、

```swift
func navigationController(navigationController: UINavigationController, didShowViewController viewController: UIViewController, animated: Bool) {
  viewController.viewDidAppear(animated)
}
```

などとすることで呼ぶようになります。

### TransitionAgentDelegate のMethodを 実装するとき
遷移に振る舞いをカスタマイズしたいときにはこれらを実装します。

* decideViewController では TransitionViewControllerProtocol を実装したUIViewControllerを返します。遷移してはいけない場合はnilを返します。
* showViewController, showModelViewController, showInternalViewController では、ViewControllerの表示アニメーションなどをカスマイズできます。
そこではViewControllerを自由に表示して良いですが、ViewController階層に必ずAddすること。
* → navigationController.pushViewController や presentViewController や addChildViewController?? などを使うこと

TransitionViewControllerProtocol の各Methodで行うこと
--------------
独自に TransitionViewControllerProtocol を実装するときは以下のことに気をつけてください。
実装は TransitionViewController, TransitionDefaultHandler を参考にしてください。

### addViewController

* ViewControllerを作成する
* 作成した ViewController に Agentに正しいPathを与えて設置する
* ViewController階層に必ずAddすること。
* viewDidAppearイベントをCenterに通知する (transitionCenter.reportViewDidAppear を呼ぶ)。基本的にはUIViewControllerのイベントの viewDidAppear内で行ってください。

### setupAgent

* Agentを正しいPathで作成し、必要なDelegateを設定します。

### removeViewController

* 子供のViewControllerを非表示・除去して、transitionCenter.reportFinishedRemoveViewControllerFromを呼びます


## Author

Ken Morishita, mokemokechicken@gmail.com

## License

DeepTransition is available under the MIT license. See the LICENSE file for more info.
