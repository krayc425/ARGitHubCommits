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
    var floorNode: SCNNode!
    var currentPlane: SCNNode?
    var planeCount = 0 {
        didSet {
            if planeCount > 0 {
                alert(message: "Found a plane, touch here")
            }
        }
    }
    
    var commits: [GitHubCommitData]?
    
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
        
        alert(message: "Move your phone around to find a plane")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    @objc func didTap(_ sender: UITapGestureRecognizer) {
        guard currentPlane == nil else { return }
        let location = sender.location(in: sceneView)
        guard let commits = commits,
            let (plane, position) = anyPlaneFrom(location: location)
            else { return }
        
        let floor = SCNFloor()
        floor.reflectivity = 0
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white
        material.colorBufferWriteMask = SCNColorMask(rawValue: 0)
        floor.materials = [material]
        
        floorNode = SCNNode(geometry: floor)
        floorNode.position = position
        sceneView.scene.rootNode.addChildNode(floorNode)
        
        currentPlane = plane
        sceneView.scene = createScene(with: commits, at: position)
    }
    
    func enableEnvironmentMap(withIntensity intensity: CGFloat) {
        if sceneView.scene.lightingEnvironment.contents == nil,
            let environmentMap = UIImage(named: "Media.scnassets/environment_blur.exr") {
            sceneView.scene.lightingEnvironment.contents = environmentMap
        }
        sceneView.scene.lightingEnvironment.intensity = intensity
    }
    
    private func anyPlaneFrom(location: CGPoint) -> (plane: SCNNode, position: SCNVector3)? {
        let results = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
        guard results.count > 0,
            let anchor = results[0].anchor,
            let node = sceneView.node(for: anchor) else {
                alert(message: "Try another point")
                return nil
        }
        return (node, SCNVector3.positionFromTransform(results[0].worldTransform))
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // from Apple's app
        DispatchQueue.main.async { [weak self] in
            if let lightEstimate = self?.sceneView.session.currentFrame?.lightEstimate {
                self?.enableEnvironmentMap(withIntensity: lightEstimate.ambientIntensity / 50)
            } else {
                self?.enableEnvironmentMap(withIntensity: 25)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if planeCount == 0 {
            planeCount = 1
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
        lightNode.eulerAngles = SCNVector3Make(-.pi / 3, .pi / 4, 0)
        lightNode.light = light
        scnScene.rootNode.addChildNode(lightNode)
        
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor(white: 0.8, alpha: 0.4)
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scnScene.rootNode.addChildNode(ambientNode)
        
        let factor: Float = 0.03
        let count = (commits.count + 6) / 7
        
        let barNode = SCNNode()
        barNode.name = "barNode"
        barNode.position = SCNVector3(position.x, position.y, position.z - Float(count) * 0.75 * factor)
        
        scnScene.rootNode.addChildNode(barNode)
        
        var totalCount = 0
        for weekFromNow in 0..<count {
            for i in 0...6 {
                totalCount += 1
                guard totalCount <= commits.count else { return scnScene }
                
                let commitData = commits[weekFromNow * 7 + i]
                let box = SCNBox(width: CGFloat(factor), height: CGFloat(factor) * (CGFloat(commitData.count) + 1.0), length: CGFloat(factor), chamferRadius: 0.0)
                let node = SCNNode(geometry: box)
                let material = SCNMaterial()
                material.diffuse.contents = commitData.color
                box.materials = [material]
                node.position = SCNVector3Make(Float(i) * 1.5 * factor, Float(box.height) / 2.0, Float(weekFromNow) * 1.5 * factor)
                
                print(totalCount)
                print(box.description)
                print(node.position)
                
                barNode.addChildNode(node)
            }
        }
        
        return scnScene
    }
}
