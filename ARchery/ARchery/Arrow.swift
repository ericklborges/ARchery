//
//  Arrow.swift
//  ARchery
//
//  Created by Erick Borges on 01/03/2018.
//  Copyright © 2018 Erick Borges. All rights reserved.
//

import UIKit
import SceneKit

class Arrow: SCNNode {
    
    override init() {
        super.init()
        // Arrow geometry and physics body
        let sphere = SCNSphere(radius: 0.025)
        self.geometry = sphere
        let shape = SCNPhysicsShape(geometry: sphere, options: nil)
        self.physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
        self.physicsBody?.isAffectedByGravity = false
        // Collision
        self.physicsBody?.categoryBitMask = CollisionCategory.arrows.rawValue
        self.physicsBody?.contactTestBitMask = CollisionCategory.archeryTarget.rawValue        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
