//
//  GameHUD.swift
//  Crazy Road
//
//  Created by Barak on 06/12/2020.
//

import SpriteKit

class GameHUD: SKScene {
    var logoLabel: SKLabelNode?
    var tapToPlayLabel: SKLabelNode?
    var pointsLabel: SKLabelNode?
    var restartButton: TouchableSpriteNode?
    var highscoreLabel: SKLabelNode?
    var highscore: Int?
    
    
    init(with size: CGSize, menu: Bool) {
        super.init(size: size)
        if menu {
            addMenuLabels()
        } else {
            addGameLabels()
        }
    }
    
    func addMenuLabels() {
        logoLabel = SKLabelNode(fontNamed: "8BIT WONDER Nominal")
        tapToPlayLabel = SKLabelNode(fontNamed: "8BIT WONDER Nominal")
        guard let logoLabel = logoLabel, let tapToPlayLabel = tapToPlayLabel else {
            return
        }
        logoLabel.text = "Crazy Road"
        logoLabel.fontSize = 35
        logoLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(logoLabel)
        
        tapToPlayLabel.text = "Tap to Play"
        tapToPlayLabel.fontSize = 25
        tapToPlayLabel.position = CGPoint(x: frame.midX, y: frame.midY - logoLabel.frame.size.height)
        addChild(tapToPlayLabel)
    }
    
    func addGameLabels() {
        pointsLabel = SKLabelNode(fontNamed: "8BIT WONDER Nominal")
        guard let pointsLabel = pointsLabel else {
            print("points label problem")
            return
        }

        restartButton = TouchableSpriteNode(imageNamed: "art.scnassets/restart.png")
        guard let restartButton = restartButton else {
            print("restart btn problem")
            return
        }
        
        highscoreLabel = SKLabelNode(fontNamed: "8BIT WONDER Nominal")
        guard let highscoreLabel = highscoreLabel else {
            return
        }
        pointsLabel.text = "0"
        pointsLabel.fontSize = 40
        pointsLabel.position = CGPoint(x: frame.minX + pointsLabel.frame.size.width, y: frame.maxY - pointsLabel.frame.size.height * 2)
        addChild(pointsLabel)
        
        restartButton.isUserInteractionEnabled = true
        restartButton.anchorPoint = CGPoint(x: 0.5, y: 0)
        restartButton.size = CGSize(width: pointsLabel.frame.size.height, height: pointsLabel.frame.size.height)
        restartButton.position = CGPoint(x: frame.maxX - pointsLabel.frame.size.width, y: frame.maxY - pointsLabel.frame.size.height * 2)
        addChild(restartButton)

        highscore = UserDefaults.standard.integer(forKey: "Highscore")
        if let highscore = highscore {
            highscoreLabel.text = "\(highscore)"
        } else {
            highscoreLabel.text = "0"
        }
        highscoreLabel.fontSize = 20
        highscoreLabel.alpha = 0.75
        highscoreLabel.position = CGPoint(x: frame.minX + pointsLabel.frame.size.width, y: frame.maxY - pointsLabel.frame.size.height * 2 - highscoreLabel.frame.size.height * 1.45)
        addChild(highscoreLabel)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
