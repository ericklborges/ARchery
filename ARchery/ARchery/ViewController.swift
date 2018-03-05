//
//  ViewController.swift
//  ARchery
//
//  Created by Erick Borges on 28/02/2018.
//  Copyright © 2018 Erick Borges. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

struct CollisionCategory: OptionSet {
    let rawValue: Int
    
    static let arrows  =       CollisionCategory(rawValue: 1 << 0) // 0b01
    static let archeryTarget = CollisionCategory(rawValue: 1 << 1) // 0b10
}

class ViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {

    // MARK: - Outlet
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var scoreLabel: UILabel!
    
    // MARK: - Properties
    var targetDistance:Float = 2
    var archeryTargetNode:SCNNode!
    var shootPower:Float = 5
    var userScore:Int = 0 {
        didSet {
            DispatchQueue.main.async {
                self.scoreLabel.text = String(self.userScore)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
        setupFirstTapGesture()
        userScore = 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - Setup
    func setupScene(){
        self.sceneView.delegate = self
        // Debug options
        self.sceneView.showsStatistics = true
        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin]
//        self.sceneView.debugOptions = [.showBoundingBoxes, .showPhysicsShapes,]
        // Scene
        let scene = SCNScene()
        self.sceneView.scene = scene
        // SCNPhysicsContactDelegate
        self.sceneView.scene.physicsWorld.contactDelegate = self
    }
    
    func setupSession() {
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        // Run the view's session
        sceneView.session.run(configuration)
    }

    // Add Archery Target to the scene
    func setupFirstTapGesture(){
        let firstTapGesture = UITapGestureRecognizer(target: self, action: #selector(addArcheryTarget))
        firstTapGesture.numberOfTapsRequired = 1
        self.sceneView.addGestureRecognizer(firstTapGesture)
    }
    
    func setupSecondTapGesture(){
        let secondTapGesture = UITapGestureRecognizer(target: self, action: #selector(shootArrow))
        secondTapGesture.numberOfTapsRequired = 1
        self.sceneView.addGestureRecognizer(secondTapGesture)
    }
    
    // MARK: - Game Functionality
    @objc
    func addArcheryTarget(){
        self.archeryTargetNode = ArcheryTarget()
        // User position
        let userPosition = self.getUserPosition()
        let userDirection = self.getUserDirection()
        // Target position
        let x = userDirection.x * targetDistance + userPosition.x
        let y = userDirection.y * targetDistance + userPosition.y
        let z = userDirection.z * targetDistance + userPosition.z
        archeryTargetNode.position = SCNVector3(x,y,z)
        
        //Contraint Lott at
        let constraint = SCNLookAtConstraint(target: self.sceneView.pointOfView!)
        constraint.isGimbalLockEnabled = true
        archeryTargetNode.constraints = [constraint]
        
        self.sceneView.scene.rootNode.addChildNode(archeryTargetNode)
        
//        self.sceneView.gestureRecognizers?.removeAll()
//        self.setupSecondTapGesture()
    }
    
    @objc
    func shootArrow(){
        let arrowNode = Arrow()
        arrowNode.position = self.getUserPosition()
        
        let shootDirection = self.getUserDirection()
        let shootForce = SCNVector3(shootDirection.x * shootPower, shootDirection.y * (shootPower+1), shootDirection.z * shootPower)
        arrowNode.physicsBody?.applyForce(shootForce, asImpulse: true)
        sceneView.scene.rootNode.addChildNode(arrowNode)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: {
            arrowNode.removeFromParentNode()
        })
    }
    
    func uptadeScore(for ponctuation: Int){
        
    }
    
    // MARK: - Auxiliary Methods
    func getUserDirection() -> SCNVector3 {
        if let frame = self.sceneView.session.currentFrame {
            let matrix = SCNMatrix4(frame.camera.transform) // 4x4 transform matrix describing camera in world space
            let direction = SCNVector3(-1 * matrix.m31, -1 * matrix.m32, -1 * matrix.m33) // orientation of camera in world space
            
            return (direction)
        }
        return (SCNVector3(0, 0, -1))
    }
    
    func getUserPosition() -> SCNVector3 {
        if let frame = self.sceneView.session.currentFrame {
            let matrix = SCNMatrix4(frame.camera.transform) // 4x4 transform matrix describing camera in world space
            let position = SCNVector3(matrix.m41, matrix.m42, matrix.m43) // location of camera in world space
            
            return (position)
        }
        return (SCNVector3(0, 0, -0.2))
    }
    
    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
    }
    
    // MARK: - SCNPhysicsContactDelegate
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
        // guarantee contact nodes order
        var firstNode: SCNNode
        var secondNode: SCNNode
        if (contact.nodeA.physicsBody!.categoryBitMask) < contact.nodeB.physicsBody!.categoryBitMask {
            firstNode = contact.nodeA
            secondNode = contact.nodeB
        } else {
            firstNode = contact.nodeB
            secondNode = contact.nodeA
        }
        
        if ((firstNode.physicsBody!.categoryBitMask & CollisionCategory.arrows.rawValue != 0) &&
            (secondNode.physicsBody!.categoryBitMask & CollisionCategory.archeryTarget.rawValue != 0)) {
            // get contact nodes
            guard let arrowNode = firstNode as? Arrow else { return }
            guard let targetNode = self.archeryTargetNode else { return }
            // target center
            let targetCenter = targetNode.position
            // distance from center
            let distanceX = powf((targetCenter.x - contact.contactPoint.x), 2)
            let distanceY = powf((targetCenter.y - contact.contactPoint.y), 2)
            let distanceZ = powf((targetCenter.z - contact.contactPoint.z), 2)
            let contactDistanceFromCenter = sqrt(distanceX + distanceY + distanceZ)
            // punctuation
            let targetNodeScale = self.archeryTargetNode.presentation.scale.x
            let targetSize = ((self.archeryTargetNode.presentation.boundingBox.max.y - self.archeryTargetNode.presentation.boundingBox.min.y) / 2) * targetNodeScale
            let ponctuation = Int((1 - (contactDistanceFromCenter / targetSize)) * 10) + 1
            userScore += ponctuation
            
            arrowNode.physicsBody?.type = .static
        }
    }

}
