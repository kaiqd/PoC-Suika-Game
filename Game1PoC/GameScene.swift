import SpriteKit

enum FormaGeometrica: String, CaseIterable {
    case circulo
    case quadrado
    case triangulo

    var cor: UIColor {
        switch self {
        case .circulo: return .systemBlue
        case .quadrado: return .systemRed
        case .triangulo: return .systemGreen
        }
    }
}

class GameScene: SKScene, SKPhysicsContactDelegate {

    var tempoInicial: TimeInterval?
    var formasAguardando: Set<SKNode> = []
    var limiteGameOverY: CGFloat = 0
    var gameOver: Bool = false
    var container: SKSpriteNode!
    var proximaFormaTipo: FormaGeometrica = .circulo
    var proximaFormaPreview: SKShapeNode?
    var tituloLabel: SKLabelNode!
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    var scoreLabel: SKLabelNode!
    
    override func didMove(to view: SKView) {
        
        tituloLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            tituloLabel.text = "Jogo de Formas"
            tituloLabel.fontSize = 24
            tituloLabel.fontColor = .white
            tituloLabel.position = CGPoint(x: size.width / 2, y: size.height - 100)
            tituloLabel.zPosition = 10
            tituloLabel.horizontalAlignmentMode = .center
            tituloLabel.verticalAlignmentMode = .center
            addChild(tituloLabel)
        
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - 130)
        scoreLabel.zPosition = 10
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.verticalAlignmentMode = .center
            addChild(scoreLabel)
        
        backgroundColor = UIColor(red: 5/255, green: 10/255, blue: 20/255, alpha: 1)
        physicsWorld.contactDelegate = self
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        setupContainer()
        proximaFormaTipo = FormaGeometrica.allCases.randomElement() ?? .circulo
        mostrarProximaForma()
    }

    func setupContainer() {
        // tamanho do container
        let containerWidth = size.width * 0.9
        let containerHeight = size.height * 0.8
        let containerSize = CGSize(width: containerWidth, height: containerHeight)
        let containerPosition = CGPoint(x: size.width / 2, y: containerHeight / 2 + 20)

        // visualizacao do container
        let background = SKShapeNode(rectOf: containerSize)
        background.fillColor = UIColor.white.withAlphaComponent(0.05)
        background.strokeColor = UIColor.white
        background.lineWidth = 3
        background.position = containerPosition
        background.zPosition = -1
        addChild(background)

        let physicsBodies: [SKPhysicsBody] = [
            // Base
            SKPhysicsBody(edgeFrom: CGPoint(x: -containerWidth/2, y: -containerHeight/2),
                          to: CGPoint(x: containerWidth/2, y: -containerHeight/2)),

            // Lado esquerdo
            SKPhysicsBody(edgeFrom: CGPoint(x: -containerWidth/2, y: -containerHeight/2),
                          to: CGPoint(x: -containerWidth/2, y: containerHeight/2)),

            // Lado direito
            SKPhysicsBody(edgeFrom: CGPoint(x: containerWidth/2, y: -containerHeight/2),
                          to: CGPoint(x: containerWidth/2, y: containerHeight/2)),
        ]

        let containerNode = SKNode()
        containerNode.position = containerPosition
        containerNode.physicsBody = SKPhysicsBody(bodies: physicsBodies)
        containerNode.physicsBody?.isDynamic = false

        addChild(containerNode)
        
        let linhaLimite = SKShapeNode(rectOf: CGSize(width: containerWidth, height: 2))
        linhaLimite.fillColor = .red
        linhaLimite.strokeColor = .clear
        linhaLimite.position = CGPoint(
            x: containerPosition.x,
            y: containerPosition.y + containerHeight / 2 - 10 // ajustado levemente abaixo da borda visual
        )
        linhaLimite.zPosition = 10
        addChild(linhaLimite)
        limiteGameOverY = linhaLimite.position.y

    }


    func createForma(tipo: FormaGeometrica, level: Int, position: CGPoint) -> SKShapeNode {
        let tamanho = CGFloat(20 + (level - 1) * 10)
        let forma: SKShapeNode

        switch tipo {
        case .circulo:
            forma = SKShapeNode(circleOfRadius: tamanho)
        case .quadrado:
            let size = CGSize(width: tamanho * 2, height: tamanho * 2)
            forma = SKShapeNode(rectOf: size, cornerRadius: 4)
        case .triangulo:
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 0, y: tamanho))
            path.addLine(to: CGPoint(x: -tamanho, y: -tamanho))
            path.addLine(to: CGPoint(x: tamanho, y: -tamanho))
            path.close()
            forma = SKShapeNode(path: path.cgPath)
        }

        forma.fillColor = tipo.cor
        forma.strokeColor = .clear
        forma.position = position
        forma.name = "\(tipo.rawValue)_\(level)"
        forma.zPosition = 1

        forma.physicsBody = SKPhysicsBody(polygonFrom: forma.path ?? CGPath(rect: CGRect(x: -tamanho, y: -tamanho, width: tamanho * 2, height: tamanho * 2), transform: nil))
        forma.physicsBody?.restitution = 0.2
        forma.physicsBody?.categoryBitMask = 1
        forma.physicsBody?.contactTestBitMask = 1
        forma.physicsBody?.collisionBitMask = 1

//        score += level
        
        return forma
    }

    func mostrarProximaForma() {
        proximaFormaPreview?.removeFromParent()

        let preview = createForma(tipo: proximaFormaTipo, level: 1, position: .zero)
        preview.setScale(0.5)
        preview.position = CGPoint(x: 60, y: size.height - 60)
        preview.physicsBody = nil
        preview.zPosition = 100
        proximaFormaPreview = preview
        addChild(preview)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameOver, let x = touches.first?.location(in: self).x else { return }
        let pos = CGPoint(x: x, y: size.height - 100)

        let forma = createForma(tipo: proximaFormaTipo, level: 1, position: pos)
        addChild(forma)

        proximaFormaTipo = FormaGeometrica.allCases.randomElement() ?? .circulo
        mostrarProximaForma()
    }


    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node as? SKShapeNode,
              let nodeB = contact.bodyB.node as? SKShapeNode,
              nodeA.name?.split(separator: "_").count == 2,
              nodeB.name?.split(separator: "_").count == 2 else { return }

        let tipoA = String(nodeA.name!.split(separator: "_")[0])
        let tipoB = String(nodeB.name!.split(separator: "_")[0])
        let levelA = extractLevel(from: nodeA.name!)
        let levelB = extractLevel(from: nodeB.name!)

        guard tipoA == tipoB, levelA == levelB else { return }

        nodeA.removeFromParent()
        nodeB.removeFromParent()

        let novoLevel = levelA + 1
        let tipo = FormaGeometrica(rawValue: tipoA) ?? .circulo
        let novaForma = createForma(tipo: tipo, level: novoLevel, position: contact.contactPoint)
        addChild(novaForma)
        
        score += levelA
    }

    func extractLevel(from name: String) -> Int {
        return Int(name.components(separatedBy: "_").last ?? "1") ?? 1
    }
    
    func encerrarJogo() {
        gameOver = true

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "GAME OVER"
        label.fontSize = 40
        label.fontColor = .red
        label.position = CGPoint(x: size.width / 2, y: size.height / 2)
        label.zPosition = 200
        addChild(label)

        proximaFormaPreview?.removeFromParent()
    }

    override func update(_ currentTime: TimeInterval) {
        guard !gameOver else { return }

        if tempoInicial == nil {
            tempoInicial = currentTime
            return
        }

        // Aguarda pelo menos 1 segundo após o início
        if currentTime - tempoInicial! < 1 { return }

        for node in children {
            guard let forma = node as? SKShapeNode,
                  forma.name?.contains("_") == true,
                  let body = forma.physicsBody,
                  body.isDynamic,
                  body.isResting else { continue }

            // Ignora se já foi analisada antes
            if formasAguardando.contains(forma) { continue }

            formasAguardando.insert(forma)

            let topoDaForma = forma.position.y + forma.frame.height / 2

            if topoDaForma > limiteGameOverY {
                encerrarJogo()
                break
            }
        }
    }


}
