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
    @IBOutlet var indicator: UIActivityIndicatorView!
    
    var commits: [GitHubCommitData]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        indicator.isHidden = true
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func gotoARAction() {
        DispatchQueue.main.async {
            self.indicator.isHidden = false
            self.indicator.startAnimating()
        }
        
        guard usernameTextField.text!.characters.count > 0 else {
            let alertC = UIAlertController(title: "Please enter a username", message: nil, preferredStyle: .alert)
            let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertC.addAction(alertAction)
            self.present(alertC, animated: true, completion: nil)
            
            DispatchQueue.main.async {
                self.indicator.stopAnimating()
                self.indicator.isHidden = true
            }
            
            return
        }
        
        let gch = GitHubCommitHelper.sharedInstance
        commits = gch.fetchCommits(with: usernameTextField.text!)
        
        guard commits != nil else {
            let alertC = UIAlertController(title: "Fail to load commits", message: nil, preferredStyle: .alert)
            let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertC.addAction(alertAction)
            self.present(alertC, animated: true, completion: nil)
            
            DispatchQueue.main.async {
                self.indicator.stopAnimating()
                self.indicator.isHidden = true
            }
            
            return
        }
        
        DispatchQueue.main.async {
            self.indicator.stopAnimating()
            self.indicator.isHidden = true
        }
        
        self.performSegue(withIdentifier: "arSegue", sender: commits!)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "arSegue" {
            let vc = segue.destination as! ViewController
            vc.commits = (sender as! [GitHubCommitData])
        }
    }
    
}
