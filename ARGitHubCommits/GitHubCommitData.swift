//
//  GitHubCommitData.swift
//  ARGitHubCommits
//
//  Created by 宋 奎熹 on 2017/7/31.
//  Copyright © 2017年 宋 奎熹. All rights reserved.
//

import Foundation
import UIKit

class GitHubCommitData: CustomStringConvertible {
    var date: Date
    var color: UIColor
    var count: Int
    
    var dateFormatter: DateFormatter {
        get {
            let newDateFormatter = DateFormatter()
            newDateFormatter.timeZone = TimeZone(identifier: "UTC")
            newDateFormatter.dateFormat = "yyyy-MM-dd"
            return newDateFormatter
        }
    }
    
    var dateString: String {
        return dateFormatter.string(from: date)
    }
    
    var description: String {
        return "On \(dateString), with \(count) commits in color \(color.description)."
    }
    
    init(date: Date, color: UIColor, count: Int) {
        self.date = date
        self.color = color
        self.count = count
    }
}
