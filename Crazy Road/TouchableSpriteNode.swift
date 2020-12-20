//
//  TouchableSpriteNode.swift
//  Crazy Road
//
//  Created by Barak on 14/12/2020.
//

import SpriteKit

class TouchableSpriteNode: SKSpriteNode {
    
    var restart = false
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        restart = true
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        restart = false
    }
}
