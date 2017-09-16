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
    
    var commits: [GitHubCommitData]?
    var commitWeekCount: Int {
        return (commits!.count + 6) / 7
    }
    var commitBarNode: SCNNode?

    var automaticSetView = false
    
    let factor: Float = 0.03
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        
        sceneView.antialiasingMode = .multisampling4X
        
        // Used in 3D games, ignore here
        sceneView.automaticallyUpdatesLighting = false
        
        if !automaticSetView {
            let tap = UITapGestureRecognizer()
            tap.addTarget(self, action: #selector(didTap))
            sceneView.addGestureRecognizer(tap)
        }
            
        let button = UIButton(frame: CGRect(x: 30, y: 30, width: 60, height: 30))
        button.backgroundColor = .myYellowColor
        button.setTitle("Back", for: .normal)
        button.titleLabel?.font = UIFont(name: "PingFangSC-Regular", size: 15.0)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 4.0
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(backAction), for: .touchUpInside)
        self.view.addSubview(button)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.isHidden = true
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        // detect horizontal planes
        configuration.planeDetection = .horizontal
        // self-fit light
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
        currentPlane = plane

        createNodes(with: commits, at: SCNVector3(position.x,
                                                  position.y,
                                                  position.z - Float(commitWeekCount) * 0.75 * factor), in: sceneView.scene.rootNode)

        addFloor(at: sceneView.scene.rootNode, with: position)
    }
    
    @objc func backAction() {
        self.navigationController?.popViewController(animated: true)
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
    
    private func addFloor(at node: SCNNode, with position: SCNVector3) {
        let floor = SCNFloor()
        floor.reflectivity = 0
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white
        material.colorBufferWriteMask = SCNColorMask(rawValue: 0)
        floor.materials = [material]
        
        floorNode = SCNNode(geometry: floor)
        floorNode.position = position
        node.addChildNode(floorNode)
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
    
    // called when the ARKit detects a plane
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARPlaneAnchor {
            // ensure that only add 1 plane
            if automaticSetView {
                if currentPlane == nil {
                    currentPlane = node
                    let planeAnchor = anchor as! ARPlaneAnchor
                    addFloor(at: node, with: SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z))

                    createNodes(with: commits!, at: SCNVector3(floorNode.position.x,
                                                               floorNode.position.y,
                                                               floorNode.position.z - Float(commitWeekCount) * 0.75 * factor), in: node)
                }
            } else {
                alert(message: "Found a plane, touch here")
            }
        }
    }
    
    // MARK: - Scene Builder
    
    private func createNodes(with commits: [GitHubCommitData], at position: SCNVector3, in node: SCNNode) {
        let light = SCNLight()
        light.type = .directional
        light.color = UIColor(white: 1.0, alpha: 0.2)
        light.shadowColor = UIColor(white: 0.0, alpha: 0.8).cgColor
        let lightNode = SCNNode()
        lightNode.eulerAngles = SCNVector3Make(-.pi / 3, .pi / 4, 0)
        lightNode.light = light
        node.addChildNode(lightNode)
        
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor(white: 0.8, alpha: 0.4)
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        node.addChildNode(ambientNode)
        
        commitBarNode = SCNNode()
        commitBarNode?.name = "barNode"
        commitBarNode?.position = position
        
        node.addChildNode(commitBarNode!)
        
        var totalCount = 0
        for weekFromNow in 0..<commitWeekCount {
            for i in 0...6 {
                totalCount += 1
                guard totalCount <= commits.count else { return }
                
                let commitData = commits[weekFromNow * 7 + i]
                let box = SCNBox(width: CGFloat(factor), height: CGFloat(factor) * (CGFloat(commitData.count) + 1.0), length: CGFloat(factor), chamferRadius: 0.0)
                let node = SCNNode(geometry: box)
                let material = SCNMaterial()
                material.diffuse.contents = commitData.color
                box.materials = [material]
                node.position = SCNVector3(Float(i) * 1.5 * factor, Float(box.height) / 2.0, Float(weekFromNow) * 1.5 * factor)
                
                print(totalCount)
                print(box.description)
                print(node.position)

                commitBarNode!.addChildNode(node)
            }
        }

        // adjust the angle of the model
        let pointOfViewRotation = sceneView.pointOfView?.rotation
        commitBarNode?.rotation = SCNVector4Make(0, (pointOfViewRotation?.y)!, 0, (pointOfViewRotation?.w)!)
    }
    
}
