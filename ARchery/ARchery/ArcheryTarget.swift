//
//  ArcheryTarget.swift
//  ARchery
//
//  Created by Erick Borges on 01/03/2018.
//  Copyright © 2018 Erick Borges. All rights reserved.
//

import UIKit
import SceneKit

class ArcheryTarget: SCNNode {

    override init() {
        super.init()
        // Get 3D model
        guard let archeryTargetScene = SCNScene(named: "art.scnassets/target.scn"),
            let archeryTargetNode = archeryTargetScene.rootNode.childNode(withName: "target", recursively: false),
            let archeryTargetGeometry = archeryTargetNode.geometry
            else { return }
        
        // ArcheryTarget geometry and physics body
        self.geometry = archeryTargetGeometry
        self.transform = archeryTargetNode.transform
        let archeryTargetShape = SCNPhysicsShape(geometry: archeryTargetGeometry, options: nil)
        self.physicsBody = SCNPhysicsBody(type: .static, shape: archeryTargetShape)
        self.physicsBody?.isAffectedByGravity = false
        // Collision
        self.physicsBody?.categoryBitMask = CollisionCategory.archeryTarget.rawValue
        self.physicsBody?.contactTestBitMask = CollisionCategory.arrows.rawValue
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
