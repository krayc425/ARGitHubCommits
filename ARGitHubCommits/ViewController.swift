//
//  ViewController.swift
//  ARGitHubCommits
//
//  Created by 宋 奎熹 on 2017/7/31.
//  Copyright © 2017年 宋 奎熹. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var floorNode: SCNNode?
    var currentPlane:SCNNode?
    var planeCount = 0 {
        didSet {
            if planeCount > 0 {
                let alertC = UIAlertController(title: "Found a plane, touch here", message: nil, preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertC.addAction(alertAction)
                self.present(alertC, animated: true, completion: nil)
            }
        }
    }
    var commits: [GitHubCommitData]? = [GitHubCommitData]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        sceneView.antialiasingMode = .multisampling4X
        
        sceneView.automaticallyUpdatesLighting = false
        
        let tap = UITapGestureRecognizer()
        tap.addTarget(self, action: #selector(didTap))
        sceneView.addGestureRecognizer(tap)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingSessionConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        
        // Run the view's session
        sceneView.session.run(configuration)
        
        let alertC = UIAlertController(title: "Move your phone around to find a plane", message: nil, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertC.addAction(alertAction)
        self.present(alertC, animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    @objc func didTap(_ sender:UITapGestureRecognizer) {
        let location = sender.location(in: sceneView)
        
        guard let _ = currentPlane else {
            guard let newPlaneData = anyPlaneFrom(location: location) else { return }
            
            let floor = SCNFloor()
            floor.reflectivity = 0
            let material = SCNMaterial()
            material.diffuse.contents = UIColor.white
            
            material.colorBufferWriteMask = SCNColorMask(rawValue: 0)
            floor.materials = [material]
            
            floorNode = SCNNode(geometry: floor)
            floorNode!.position = newPlaneData.1
            sceneView.scene.rootNode.addChildNode(floorNode!)
            
            self.currentPlane = newPlaneData.0
            
            guard self.commits != nil else {
                return
            }
            
            sceneView.scene = createScene(with: self.commits!, at: newPlaneData.1)
            
            return
        }
    }
    
    func enableEnvironmentMapWithIntensity(_ intensity: CGFloat) {
        if sceneView.scene.lightingEnvironment.contents == nil {
            if let environmentMap = UIImage(named: "Media.scnassets/environment_blur.exr") {
                sceneView.scene.lightingEnvironment.contents = environmentMap
            }
        }
        sceneView.scene.lightingEnvironment.intensity = intensity
    }
    
    // MARK: - ARSCNViewDelegate
    
    private func anyPlaneFrom(location:CGPoint) -> (SCNNode, SCNVector3)? {
        let results = sceneView.hitTest(location, types: ARHitTestResult.ResultType.existingPlaneUsingExtent)
        
        guard results.count > 0,
            let anchor = results[0].anchor,
            let node = sceneView.node(for: anchor) else {
                
                let alertC = UIAlertController(title: "Try another point", message: nil, preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertC.addAction(alertAction)
                self.present(alertC, animated: true, completion: nil)
                
                return nil
        }
        return (node, SCNVector3.positionFromTransform(results[0].worldTransform))
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // from apples app
        DispatchQueue.main.async {
            if let lightEstimate = self.sceneView.session.currentFrame?.lightEstimate {
                self.enableEnvironmentMapWithIntensity(lightEstimate.ambientIntensity / 50)
            } else {
                self.enableEnvironmentMapWithIntensity(25)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if planeCount == 0 {
            planeCount += 1
        }
    }
    
    // MARK: - Scene Builder
    
    private func createScene(with commits: [GitHubCommitData], at position: SCNVector3) -> SCNScene {
        let scnScene = SCNScene()
        
        let light = SCNLight()
        light.type = .directional
        light.color = UIColor(white: 1.0, alpha: 0.2)
        light.shadowColor = UIColor(white: 0.0, alpha: 0.8).cgColor
        let lightNode = SCNNode()
        lightNode.eulerAngles = SCNVector3Make(-Float.pi / 3, Float.pi / 4, 0)
        lightNode.light = light
        scnScene.rootNode.addChildNode(lightNode)
        
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor(white: 0.8, alpha: 0.4)
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scnScene.rootNode.addChildNode(ambientNode)
        
        let factor = 0.03
        let count = 52
        
        let barNode = SCNNode()
        barNode.name = "barNode"
        barNode.position = SCNVector3(position.x, position.y, position.z - Float(count) * 0.75 * Float(factor))
        
        scnScene.rootNode.addChildNode(barNode)
        
        var totalCount = 0
        for weekFromNow in 0..<count {
            for i in 0...6 {
                totalCount += 1
                let commitData = commits[weekFromNow * 7 + i]
                let box = SCNBox(width: CGFloat(factor), height: CGFloat(factor) * (CGFloat(commitData.count) + 1.0), length: CGFloat(factor), chamferRadius: 0.0)
                let node = SCNNode(geometry: box)
                let material = SCNMaterial()
                material.diffuse.contents = commitData.color
                box.materials = [material]
                node.position = SCNVector3Make(Float(i) * 1.5 * Float(factor), Float(box.height) / 2.0, Float(weekFromNow) * 1.5 * Float(factor))
                
                print(totalCount)
                print(box.description)
                print(node.position)
                
                barNode.addChildNode(node)
            }
        }
        for i in totalCount..<commits.count {
            totalCount += 1
            let commitData = commits[i]
            let box = SCNBox(width: CGFloat(factor), height: CGFloat(factor) * (CGFloat(commitData.count) + 1.0), length: CGFloat(factor), chamferRadius: 0.0)
            let node = SCNNode(geometry: box)
            let material = SCNMaterial()
            material.diffuse.contents = commitData.color
            box.materials = [material]
            node.position = SCNVector3Make(Float(i % 7) * 1.5 * Float(factor), Float(box.height) / 2.0, Float(count + (i - totalCount) / 7) * 1.5 * Float(factor))
            
            print(totalCount)
            print(box.description)
            print(node.position)
            
            barNode.addChildNode(node)
        }
        
        return scnScene
    }
}
