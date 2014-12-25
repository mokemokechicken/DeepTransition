//
//  TransitionViewController
//  DeepTransitionSample
//
//  Created by 森下 健 on 2014/12/23.
//  Copyright (c) 2014年 Yumemi. All rights reserved.
//

import UIKit

public class TransitionViewController : UIViewController {
    override public func viewDidAppear(animated: Bool) {
        viewDidShow()
        super.viewDidAppear(animated)
    }

}

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

