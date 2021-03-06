//
//  Copyright (c) 2017. Uber Technologies
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import RIBs
import LoggedInPluginPoint
import LoggedInPlugin

protocol LoggedInInteractable: Interactable, OffGameListener, TicTacToeListener, LoginPluginListener {
    var router: LoggedInRouting? { get set }
    var listener: LoggedInListener? { get set }
}

protocol LoggedInViewControllable: ViewControllable {
    func present(viewController: ViewControllable)
    func dismiss(viewController: ViewControllable)
}

final class LoggedInRouter: Router<LoggedInInteractable>, LoggedInRouting {

    init(interactor: LoggedInInteractable,
         viewController: LoggedInViewControllable,
         loggedInPluginFactory: ILoggedInPluginFactory,
         offGameBuilder: OffGameBuildable,
         ticTacToeBuilder: TicTacToeBuildable) {
        self.viewController = viewController
        self.loggedInPluginFactory = loggedInPluginFactory
        self.offGameBuilder = offGameBuilder
        self.ticTacToeBuilder = ticTacToeBuilder
        super.init(interactor: interactor)
        interactor.router = self
    }

    override func didLoad() {
        super.didLoad()
        attachOffGame()
    }

    // MARK: - LoggedInRouting

    func cleanupViews() {
        if let currentChild = currentChild {
            viewController.dismiss(viewController: currentChild.viewControllable)
        }
    }

    func routeToTicTacToe() {
        detachCurrentChild()

        let ticTacToe = ticTacToeBuilder.build(withListener: interactor)
        currentChild = ticTacToe
        attachChild(ticTacToe)
        viewController.present(viewController: ticTacToe.viewControllable)
    }

    func routeToOffGame() {
        detachCurrentChild()
        attachOffGame()
    }
    
    func routeToPlugin(id: String) {
        detachCurrentChild()
        attachPlugin(id: id)
    }

    // MARK: - Private

    private let viewController: LoggedInViewControllable
    private let offGameBuilder: OffGameBuildable
    private let ticTacToeBuilder: TicTacToeBuildable
    private let loggedInPluginFactory: ILoggedInPluginFactory

    private var currentChild: ViewableRouting?
    
    private func attachPlugin(id: String) {
        guard let plugin = loggedInPluginFactory.getPlugin(id: id)?.builder.build(withListener: interactor) else {
            print("Plugin with id: \(id) does not exist!")
            return
        }
        
        self.currentChild = plugin
        attachChild(plugin)
        viewController.present(viewController: plugin.viewControllable)
    }

    private func attachOffGame() {
        let offGame = offGameBuilder.build(withListener: interactor)
        self.currentChild = offGame
        attachChild(offGame)
        viewController.present(viewController: offGame.viewControllable)
    }

    private func detachCurrentChild() {
        if let currentChild = currentChild {
            detachChild(currentChild)
            viewController.dismiss(viewController: currentChild.viewControllable)
        }
    }
}
