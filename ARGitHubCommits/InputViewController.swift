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
    @IBOutlet var goButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        usernameTextField.text = UserDefaults.standard.string(forKey: "username")
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
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "arSegue",
            let vc = segue.destination as? ViewController,
            let commits = sender as? [GitHubCommitData] {
            vc.commits = commits
        }
    }
}
