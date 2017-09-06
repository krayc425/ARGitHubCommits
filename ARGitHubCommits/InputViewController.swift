//
//  InputViewController.swift
//  ARGitHubCommits
//
//  Created by 宋 奎熹 on 2017/7/31.
//  Copyright © 2017年 宋 奎熹. All rights reserved.
//

import UIKit

class InputViewController: UIViewController {
    
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var automaticSwitch: UISwitch!
    @IBOutlet var goButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        usernameTextField.text = UserDefaults.standard.string(forKey: "username")
        
        automaticSwitch.setOn(UserDefaults.standard.bool(forKey: "automatic"), animated: true)
        automaticSwitch.addTarget(self, action: #selector(switchChange), for: .valueChanged)
        automaticSwitch.onTintColor = .myYellowColor
        
        goButton.layer.cornerRadius = 3.0
        goButton.layer.masksToBounds = true
        goButton.backgroundColor = .myYellowColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = false
    }
    
    @IBAction func gotoARAction() {
        guard let username = usernameTextField.text,
            username.characters.count > 0 else {
                return alert(message: "Please enter a username")
        }
        
        let gch = GitHubCommitHelper.sharedInstance
        guard let commits = gch.fetchCommits(ofUser: username) else {
            return alert(message: "Fail to load commits")
        }
        
        UserDefaults.standard.setValue(username, forKey: "username")
        performSegue(withIdentifier: "arSegue", sender: commits)
    }
    
    @objc func switchChange() {
        UserDefaults.standard.set(automaticSwitch.isOn, forKey: "automatic")
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "arSegue",
            let vc = segue.destination as? ViewController,
            let commits = sender as? [GitHubCommitData] {
            vc.commits = commits
            vc.automaticSetView = self.automaticSwitch.isOn
        }
    }
}
