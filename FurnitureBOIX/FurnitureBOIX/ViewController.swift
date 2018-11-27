//
//  AppDelegate.swift
//  FurnitureBOIS2
//
//  Created by Nathan Nguyen on 11/24/18.
//  Copyright © 2018 Nathan Nguyen. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    let vNode = SCNNode()
    let pNode = SCNNode()
    let cNode = SCNNode()
    let lNode = SCNNode()
    var node = SCNNode()
    private var modelNode: SCNNode!
    
    var focalNode: FocalNode?
    private var screenCenter: CGPoint!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        screenCenter = view.center
        
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints,ARSCNDebugOptions.showWorldOrigin]
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchRecognized(pinch:)))

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panRecognized(pan:)))
        
        // Tracks pans on the screen
        /*let panGesture = UIPanGestureRecognizer(target: self, action: #selector(viewPanned))
        sceneView.addGestureRecognizer(panGesture)
        
        // Tracks rotation gestures on the screen
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(viewRotated))
        sceneView.addGestureRecognizer(rotationGesture)*/

        self.view.addGestureRecognizer(pinchGesture)
        self.view.addGestureRecognizer(panGesture)
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        let vButton = UIButton(frame: CGRect(x: 0, y: 600, width: 75, height: 50))

        vButton.setTitle("Vase", for: .normal)
        vButton.addTarget(self, action: #selector(setVNode), for: .touchUpInside)
        
        let rButton = UIButton(frame: CGRect(x: 150, y: 15, width: 75, height: 50))
        
        rButton.setTitle("Restart", for: .normal)
       
        
        /*let pButton = UIButton(frame: CGRect(x: 155, y: 50, width: 50, height: 50))
        pButton.backgroundColor = UIColor(red: 0.1, green: 0.2, blue: 0.4, alpha: 0.8)
        pButton.setTitle("Restart", for: .normal)
        pButton.addTarget(self, action: #selector(setPNode), for: .touchUpInside)
        */
        
        let cButton = UIButton(frame: CGRect(x: 150, y: 600, width: 75, height: 50))

        cButton.setTitle("Chair", for: .normal)
        cButton.addTarget(self, action: #selector(setCNode), for: .touchUpInside)
        
        let lButton = UIButton(frame: CGRect(x: 300, y: 600, width: 75, height: 50))
        lButton.setTitle("Lamp", for: .normal)
        lButton.addTarget(self, action: #selector(setLNode), for: .touchUpInside)
        
        self.view.addSubview(vButton)
        self.view.addSubview(rButton)
        self.view.addSubview(cButton)
        self.view.addSubview(lButton)
        

    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let standardConfiguration: ARWorldTrackingConfiguration = {
            let configuration = ARWorldTrackingConfiguration()
            if #available(iOS 11.3, *) {
                configuration.planeDetection = [.horizontal, .vertical]
            } else {
                // Fallback on earlier versions
            }
            return configuration
        }()
        
        // Run the view's session
        sceneView.session.run(standardConfiguration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    private func node(at position: CGPoint) -> SCNNode? {
        return sceneView.hitTest(position, options: nil)
            .first(where: { $0.node !== focalNode && $0.node !== modelNode })?
            .node
    }
    
    @IBAction func handleTap(_ sender: UITapGestureRecognizer) {
        /* Looking at the location where the user touched the screen */
        let result = sceneView.hitTest(sender.location(in: sceneView), types: [ARHitTestResult.ResultType.featurePoint])
        guard let hitResult = result.last else {return}

        /* transforms the result into a matrix_float 4x4 so the SCN Node can read the data */
        let hitTransform = hitResult.worldTransform

        /* Print the coordinates captured */
        //print("x: ", hitTransform[3].x, "\ny: ", hitTransform[3].y, "\nz: ", hitTransform[3].z)

        /* Look at Add Geometry Class in Controller Group */
        switch node {
        case vNode:
            addObject(position: hitTransform, sceneView: sceneView, node: vNode, objectPath: "art.scnassets/vase/vase.scn")
        case pNode:
            addObject(position: hitTransform, sceneView: sceneView, node: pNode, objectPath: "art.scnassets/k/painting.scn")
        case cNode:
            addObject(position: hitTransform, sceneView: sceneView, node: cNode, objectPath: "art.scnassets/chair/chair.scn")
        case lNode:
            addObject(position: hitTransform, sceneView: sceneView, node: lNode, objectPath: "art.scnassets/lamp/lamp.scn")
        default:
            print("No Node Found")
        }
    }
    
    func addObject(position: matrix_float4x4, sceneView: ARSCNView, node: SCNNode, objectPath: String){
        
        node.position = SCNVector3(position[3].x, position[3].y, position[3].z)
        
        // Create a new scene
        guard let virtualObjectScene = SCNScene(named: objectPath)
            else {
                print("Unable to Generate" + objectPath)
                return
        }
        
        let wrapperNode = SCNNode()
        for child in virtualObjectScene.rootNode.childNodes {
            child.geometry?.firstMaterial?.lightingModel = .physicallyBased
            wrapperNode.addChildNode(child)
        }
        
        node.addChildNode(wrapperNode)
        sceneView.scene.rootNode.addChildNode(node)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // If we have already created the focal node we should not do it again
        guard focalNode == nil else { return }
        
        // Create a new focal node
        let node = FocalNode()
        //node.addChildNode(modelNode)
        
        // Add it to the root of our current scene
        sceneView.scene.rootNode.addChildNode(node)
        
        // Store the focal node
        self.focalNode = node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // If we haven't established a focal node yet do not update
        guard let focalNode = focalNode else { return }
        
        // Determine if we hit a plane in the scene
        let hit = sceneView.hitTest(screenCenter, types: .existingPlane)
        
        // Find the position of the first plane we hit
        guard let positionColumn = hit.first?.worldTransform.columns.3 else { return }
        
        // Update the position of the node
        focalNode.position = SCNVector3(x: positionColumn.x, y: positionColumn.y, z: positionColumn.z)
    }
    
    @objc func pinchRecognized(pinch: UIPinchGestureRecognizer) {
        node.runAction(SCNAction.scale(by: pinch.scale, duration: 0.0))
    }
    
    /*private var originalRotation: SCNVector3?
    
    @objc private func viewRotated(_ gesture: UIRotationGestureRecognizer) {
        let location = gesture.location(in: sceneView)
        
        guard let node = node(at: location) else { return }
        
        switch gesture.state {
        case .began:
            originalRotation = node.eulerAngles
        case .changed:
            guard var originalRotation = originalRotation else { return }
            originalRotation.y -= Float(gesture.rotation)
            node.eulerAngles = originalRotation
        default:
            originalRotation = nil
        }
    }
    private var selectedNode: SCNNode?
    
    @objc private func viewPanned(_ gesture: UIPanGestureRecognizer) {
        // Find the location in the view
        let location = gesture.location(in: sceneView)
        
        switch gesture.state {
        case .began:
            // Choose the node to move
            selectedNode = node(at: location)
        case .changed:
            // Move the node based on the real world translation
            guard let result = sceneView.hitTest(location, types: .existingPlane).first else { return }
            
            let transform = result.worldTransform
            let newPosition = float3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
            selectedNode?.simdPosition = newPosition
        default:
            // Remove the reference to the node
            selectedNode = nil
        }
    }
    */
   
    
    @objc func panRecognized(pan: UIPanGestureRecognizer) {

        let xPan = pan.velocity(in: sceneView).x/10000

         
        
        node.runAction(SCNAction.rotateBy(x: 0, y: xPan, z: 0, duration: 0.1))
        //node.runAction(SCNAction.moveBy(x: xPan, y: 0.0, z: yPan, duration: 1))
    }
    
    @objc func setVNode(sender: UIButton!) {
        modelNode = vNode
        node = vNode
    }
    
    @objc func setPNode(sender: UIButton!) {
        modelNode = pNode
        node = pNode
    }
 
    @objc func setCNode(sender: UIButton!) {
        modelNode = cNode
        node = cNode
    }
    
    @objc func setLNode(sender: UIButton!) {
        modelNode = lNode
        node = lNode
    }
    
}



