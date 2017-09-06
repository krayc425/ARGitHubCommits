//
//  GitHubCommitHelper.swift
//  ARGitHubCommits
//
//  Created by 宋 奎熹 on 2017/7/31.
//  Copyright © 2017年 宋 奎熹. All rights reserved.
//

import Foundation
import UIKit

class GitHubCommitHelper {
    static let sharedInstance = GitHubCommitHelper()
    private init() { }
    
    private(set) lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()
    
    private lazy var reg: NSRegularExpression = {
        let pattern = "(fill=\")(#[^\"]{6})(\" data-count=\")([^\"]{1,})(\" data-date=\")([^\"]{10})(\"/>)"
        do {
            return try NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)
        } catch {
            fatalError("Regex error")
        }
    }()
    
    func fetchCommits(ofUser id: String) -> [GitHubCommitData]? {
        let url = URL(string: "https://github.com/users/\(id)/contributions")!
        
        guard let webData = try? String(contentsOf: url, encoding: .utf8) else {
            print("Get data error")
            return nil
        }
        
        let matched = reg.matches(in: webData, range: NSRange(location: 0, length: webData.characters.count))
        
        let commitArray: [GitHubCommitData] = matched.map { item in
            func substringForRange(at index: Int) -> String {
                return webData.substring(with: Range(item.rangeAt(index), in: webData)!)
            }
            let color = UIColor(hexString: substringForRange(at: 2))
            let count = Int(substringForRange(at: 4))!
            let date = dateFormatter.date(from: substringForRange(at: 6))!
            
            let itemData = GitHubCommitData(date: date, color: color, count: count)
            print(itemData)
            return itemData
        }
        
        return commitArray
    }
}
