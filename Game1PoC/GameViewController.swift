//
//  GameViewController.swift
//  Game1PoC
//
//  Created by Kaique Diniz on 11/04/25.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as? SKView {
            // Cria sua GameScene com o tamanho correto da tela
            let scene = GameScene(size: view.bounds.size)
            scene.scaleMode = .resizeFill

            // Apresenta a cena corretamente
            view.presentScene(scene)

            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
        }

    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
