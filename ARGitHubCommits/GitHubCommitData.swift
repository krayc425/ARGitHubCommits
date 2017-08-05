//
//  GitHubCommitData.swift
//  ARGitHubCommits
//
//  Created by 宋 奎熹 on 2017/7/31.
//  Copyright © 2017年 宋 奎熹. All rights reserved.
//

import Foundation
import UIKit

struct GitHubCommitData {
    let date: Date
    let color: UIColor
    let count: Int
}

extension GitHubCommitData: CustomStringConvertible {
    var dateString: String {
        let formatter = GitHubCommitHelper.sharedInstance.dateFormatter
        return formatter.string(from: date)
    }
    
    var description: String {
        return "On \(dateString), with \(count) commits in color \(color)."
    }
}
