//
//  GameViewController.swift
//  Crazy Road
//
//  Created by Barak on 22/11/2020.
//

import UIKit
import QuartzCore
import SceneKit
import SpriteKit

enum GameState {
    case menu, playing, gameOver
}

class GameViewController: UIViewController {
    
    var scene: SCNScene!
    var sceneView: SCNView!
    var gameHUD: GameHUD!
    var gameState = GameState.menu
    var score: Int = 0
    var highscore: Int?
    var restart: Bool? = false
    
    
    var camerNode = SCNNode()
    var lightNode = SCNNode()
    var playerNode = SCNNode()
    var collisionNode = CollisionNode()
    var mapNode = SCNNode()
    var lanes = [LaneNode]()
    var laneCount = 0
    let musicNode = SCNNode()
    
    var jumpForwardAction: SCNAction?
    var jumpRightAction: SCNAction?
    var jumpLeftAction: SCNAction?
    var driveRightAction: SCNAction?
    var driveLeftAction: SCNAction?
    var dieAction: SCNAction?
    var jumpSoundAction: SCNAction?
    
    
    var frontBlocked = false
    var rightBlocked = false
    var leftBlocked = false
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView = (view as! SCNView)
        initialiseGame()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameState {
        case .menu:
            setupGestures()
            gameHUD = GameHUD(with: sceneView.bounds.size, menu: false)
            sceneView.overlaySKScene = gameHUD
            sceneView.overlaySKScene?.isUserInteractionEnabled = false
            gameState = .playing
        default:
            break
        }
    }
    

    
    func resetGame() {
        scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        scene = nil
        gameState = .menu
        score = 0
        laneCount = 0
        lanes = [LaneNode]()
        initialiseGame()
    }
    
    func initialiseGame() {
        setupScene()
        setupPlayer()
        setupCollisionNode()
        setupFloor()
        setupCamera()
        setupLight()
        setupGestures()
        setupActions()
        setupTraffic()
        setupBackgroundMusic()

        
    }
    
    func setupScene() {
        
        sceneView.delegate = self
        scene = SCNScene()
        scene.physicsWorld.contactDelegate = self
        sceneView.present(scene, with: .fade(withDuration: 0.5), incomingPointOfView: nil, completionHandler: nil)
        DispatchQueue.main.async {
            self.gameHUD = GameHUD(with: self.sceneView.bounds.size, menu: true)
            self.sceneView.overlaySKScene = self.gameHUD
            self.sceneView.overlaySKScene?.isUserInteractionEnabled = false
        }
        scene.rootNode.addChildNode(mapNode)
        
        for _ in 0..<6 {
           createNewLane(initial: true)
        }
        
        for _ in 0..<16 {
            createNewLane(initial: false)
        }
    }
    
    func setupFloor() {
        let floor = SCNFloor()
        floor.firstMaterial?.diffuse.contents = UIImage(named: "art.scnassets/darkgrass.png")
        floor.firstMaterial?.diffuse.wrapS = .repeat
        floor.firstMaterial?.diffuse.wrapT = .repeat
        floor.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(12.5, 12.5, 12.5)
        floor.reflectivity = 0.0
        let floorNode = SCNNode(geometry: floor)
        scene.rootNode.addChildNode(floorNode)
    }
    
    func setupCamera() {
        camerNode.camera = SCNCamera()
        camerNode.position = SCNVector3(0, 10, 0)
        camerNode.eulerAngles = SCNVector3(-toRadians(angle: 60), toRadians(angle: 20), 0)
        scene.rootNode.addChildNode(camerNode)
        
    }
    
    func setupLight() {
        let ambientNode = SCNNode()
        ambientNode.light = SCNLight()
        ambientNode.light?.type = .ambient
        
        let directionalNode = SCNNode()
        directionalNode.light = SCNLight()
        directionalNode.light?.type = .directional
        directionalNode.light?.castsShadow = true
        directionalNode.light?.shadowColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
        directionalNode.position = SCNVector3(-5, 5, 0)
        directionalNode.eulerAngles = SCNVector3(0, -toRadians(angle: 90), -toRadians(angle: 45))
        
        lightNode.addChildNode(ambientNode)
        lightNode.addChildNode(directionalNode)
        lightNode.position = camerNode.position
        scene.rootNode.addChildNode(lightNode)
        
        
    }
    
    func setupPlayer() {
        guard let playerScene = SCNScene(named: "art.scnassets/Chicken.scn") else { return }
        if let player = playerScene.rootNode.childNode(withName: "player", recursively: true) {
            playerNode = player
            playerNode.position = SCNVector3(-3, 0.3, 0)
            scene.rootNode.addChildNode(playerNode)
        }
    }
    
    func setupCollisionNode() {
        collisionNode = CollisionNode()
        collisionNode.position = playerNode.position
        scene.rootNode.addChildNode(collisionNode)
    }
    
    func setupGestures() {
        DispatchQueue.main.async {
            let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe(_:)))
            swipeUp.direction = .up
            self.sceneView.addGestureRecognizer(swipeUp)
            
            let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe(_:)))
            swipeRight.direction = .right
            self.sceneView.addGestureRecognizer(swipeRight)
            
            let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.handleSwipe(_:)))
            swipeLeft.direction = .left
            self.sceneView.addGestureRecognizer(swipeLeft)
        }
    }
    
    func setupBackgroundMusic() {
        if let source = SCNAudioSource(fileNamed: "art.scnassets/trafficSound.wav") {
            source.volume = 0.12
            let action = SCNAction.repeatForever(SCNAction.playAudio(source, waitForCompletion: true))
            musicNode.runAction(action)
            scene.rootNode.addChildNode(musicNode)
        } else {
            print("cannot find file")
        }
    }
    
    func setupActions() {
        if let jumpSource = SCNAudioSource(fileNamed: "art.scnassets/jumpSound.wav") {
            jumpSource.volume = 4
            jumpSoundAction = SCNAction.playAudio(jumpSource, waitForCompletion: false)
        } else {
            print("cannot find jump sound")
            jumpSoundAction = SCNAction()
        }
        var dieSoundaction = SCNAction()
        if let dieSource = SCNAudioSource(fileNamed: "art.scnassets/dieSound-2.wav") {
            dieSource.volume = 1.2
            dieSoundaction = SCNAction.playAudio(dieSource, waitForCompletion: false)
        } else {
            print("cannot find file")
        }
        let flyAwayAction = SCNAction.moveBy(x: 0, y: 5, z: 0, duration: 1.0)
        let turnAction = SCNAction.repeat(SCNAction.rotateBy(x: 0, y: toRadians(angle: 360), z: 0, duration: 1.2), count: 1)
        
        let moveUpAction = SCNAction.moveBy(x: 0, y: 1, z: 0, duration: 0.1)
        let moveDownAction = SCNAction.moveBy(x: 0, y: -1, z: 0, duration: 0.1)
        moveUpAction.timingMode = .easeOut
        moveDownAction.timingMode = .easeIn
        let jumpAction = SCNAction.sequence([moveUpAction, moveDownAction])
        
        let moveForwardAction = SCNAction.moveBy(x: 0, y: 0, z: -1, duration: 0.2)
        let moveRightAction = SCNAction.moveBy(x: 1, y: 0, z: 0, duration: 0.2)
        let moveLeftAction = SCNAction.moveBy(x: -1, y: 0, z: 0, duration: 0.2)
        
        let turnForwardAction = SCNAction.rotateTo(x: 0, y: toRadians(angle: 180), z: 0, duration: 0.2, usesShortestUnitArc: true)
        let turnRightAction = SCNAction.rotateTo(x: 0, y: toRadians(angle: 90), z: 0, duration: 0.2, usesShortestUnitArc: true)
        let turnLeftAction = SCNAction.rotateTo(x: 0, y: toRadians(angle: -90), z: 0, duration: 0.2, usesShortestUnitArc: true)
        
        jumpForwardAction = SCNAction.group([turnForwardAction, jumpAction, moveForwardAction, jumpSoundAction!])
        jumpRightAction = SCNAction.group([turnRightAction, jumpAction, moveRightAction, jumpSoundAction!])
        jumpLeftAction = SCNAction.group([turnLeftAction, jumpAction, moveLeftAction, jumpSoundAction!])
        
        driveRightAction = SCNAction.repeatForever(SCNAction.moveBy(x: 2, y: 0, z: 0, duration: 1))
        driveLeftAction = SCNAction.repeatForever(SCNAction.moveBy(x: -2, y: 0, z: 0, duration: 1))
        
        dieAction = SCNAction.group([flyAwayAction, turnAction, dieSoundaction])
    }
    
    func jumpForward() {
        if let action = jumpForwardAction {
            addLanes()
            playerNode.runAction(action) {
                self.checkBlocks()
                self.score += 1
                self.gameHUD.pointsLabel?.text = "\(self.score)"
            }
        }
    }
    
    func setupTraffic() {
        for lane in lanes {
            if let trafficNode = lane.trafficNode {
                addActions(for: trafficNode)
            }
        }
    }
    
    func updatePositions() {
        collisionNode.position = playerNode.position
        let diffX = playerNode.position.x + 1 - camerNode.position.x
        let diffZ = playerNode.position.z + 2 - camerNode.position.z
        camerNode.position.x += diffX
        camerNode.position.z += diffZ
        lightNode.position = camerNode.position
    }
    
    func updateTraffic() {
        for lane in lanes {
            guard let trafficNode = lane.trafficNode else {
                continue
            }
            for vehicle in trafficNode.childNodes {
                if vehicle.position.x > 13 {
                    vehicle.position.x = -21
                } else if vehicle.position.x < -21 {
                    vehicle.position.x = 13
                }
            }
        }
    }
    
    func createNewLane(initial: Bool) {
        let type: LaneType
        let lane: LaneNode
        if laneCount < 8 {
            type = randomBool(odds: 3) || initial ? LaneType.grass : LaneType.road
            lane = LaneNode(type: type, width: 40, clearStart: true)
        } else {
            type = randomBool(odds: 3) || initial ? LaneType.grass : LaneType.road
            lane = LaneNode(type: type, width: 40, clearStart: false)
        }
        lane.position = SCNVector3(0, 0, 5 - laneCount)
        laneCount += 1
        lanes.append(lane)
        mapNode.addChildNode(lane)
        
        if let trafficNode = lane.trafficNode {
            addActions(for: trafficNode)
        }
    }
    
    func checkForRestartGame() {
        restart = gameHUD.restartButton?.restart
        if let restart = restart {
            if restart {
                gameOver()
            }
        }
    }
    
    func removeUnusedLanes() {
        for child in mapNode.childNodes {
            if !sceneView.isNode(child, insideFrustumOf: camerNode) && child.worldPosition.z > playerNode.worldPosition.z {
                child.removeFromParentNode()
                lanes.removeFirst()
            }
        }
    }
    
    func addLanes() {
        for _ in 0...1 {
            createNewLane(initial: false)
        }
        
        removeUnusedLanes()
    }
    
    func addActions(for trafficNode: TrafficNode) {
        guard let driveAction = trafficNode.directionRight ? driveRightAction : driveLeftAction else { return }
        driveAction.speed = 1 / CGFloat(trafficNode.type + 1) + 0.5
        for vehicle in trafficNode.childNodes {
            vehicle.removeAllActions()
            vehicle.runAction(driveAction)
        }
    }
    
    func gameOver() {
        DispatchQueue.main.async {
            if let gestureRecognizer = self.sceneView.gestureRecognizers {
                for recognizer in gestureRecognizer {
                    self.sceneView.removeGestureRecognizer(recognizer)
                }
            }
        }

        gameState = .gameOver
        if let action = dieAction {
            musicNode.removeFromParentNode()
            playerNode.runAction(action) {
                self.highscore = UserDefaults.standard.integer(forKey: "Highscore")
                if let highscore = self.highscore {
                    if self.score > highscore {
                        UserDefaults.standard.setValue(self.score, forKey: "Highscore")
                    }
                } else {
                    UserDefaults.standard.setValue(self.score, forKey: "Highscore")
                }
                self.resetGame()
            }
            
        }
    }

}

extension GameViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didApplyAnimationsAtTime time: TimeInterval) {
        checkForRestartGame()
        updatePositions()
        updateTraffic()
    }
}

extension GameViewController: SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        guard let categoryA = contact.nodeA.physicsBody?.categoryBitMask, let categoryB = contact.nodeB.physicsBody?.categoryBitMask else {
            return
        }
        let mask = categoryA | categoryB
        
        switch mask {
        case PhysicsCategory.chicken | PhysicsCategory.vehicle:
            gameOver()
        case PhysicsCategory.vegetation | PhysicsCategory.collisionTestFront:
            frontBlocked = true
        case PhysicsCategory.vegetation | PhysicsCategory.collisionTestRight:
            rightBlocked = true
        case PhysicsCategory.vegetation | PhysicsCategory.collisionTestLeft:
            leftBlocked = true
        default:
            break
        }
    }
}

extension GameViewController {
    @objc func handleSwipe(_ sender: UISwipeGestureRecognizer) {
        switch sender.direction {
        case UISwipeGestureRecognizer.Direction.up:
            if !frontBlocked {
                jumpForward()
            }
        case UISwipeGestureRecognizer.Direction.right:
            if playerNode.position.x < 8 && !rightBlocked {
                if let action = jumpRightAction {
                    playerNode.runAction(action) {
                        self.checkBlocks()
                    }
                }
            }
        case UISwipeGestureRecognizer.Direction.left:
            if playerNode.position.x > -11 && !leftBlocked {
                if let action = jumpLeftAction {
                    playerNode.runAction(action) {
                        self.checkBlocks()
                    }
                }
            }
        default:
            break
        }
    }
    
    func checkBlocks() {
        if scene.physicsWorld.contactTest(with: collisionNode.front.physicsBody!, options: nil).isEmpty {
            frontBlocked = false
        }
        if scene.physicsWorld.contactTest(with: collisionNode.right.physicsBody!, options: nil).isEmpty {
            rightBlocked = false
        }
        if scene.physicsWorld.contactTest(with: collisionNode.left.physicsBody!, options: nil).isEmpty {
            leftBlocked = false
        }
    }
    
    @objc func restarButtonClicked(){
            gameOver()
        }
}


//var starButton = UIButton()
//
//    func a ()  {
//
//        starButton = UIButton(type: UIButton.ButtonType.custom)
//        starButton.frame = CGRect(x: 100, y: 100, width: 50, height: 50)
//        starButton.backgroundColor = .blue
//        SpielFenster.addSubview(starButton)
//
//        starButton.addTarget(self, action: #selector(starButtonClicked), for: UIControl.Event.touchDown)
//        starButton.adjustsImageWhenHighlighted = false
//    }
//    @objc func starButtonClicked(){
//        animateScaleDown()
//    }
//
//    func animateScaleDown(){
//
//        UIView.animate(withDuration: 0.1, animations: {
//            self.starButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
//
//        }, completion: { _ in
//            self.wait()
//        })
//
//    }
//
//    func wait(){
//        UIView.animate(withDuration: 0.2, animations: {}, completion: { _ in
//            UIView.animate(withDuration: 0.2, animations: {
//                self.starButton.transform = CGAffineTransform(scaleX: 1, y: 1)
//
//            })
//        })
//    }
