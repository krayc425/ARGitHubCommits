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
    
    var dateFormatter: DateFormatter
    var commitArray: [GitHubCommitData]
    
    private init() {
        commitArray = [GitHubCommitData]()
        dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd"
    }
    
    func fetchCommits(with id: String) -> [GitHubCommitData]? {
        commitArray.removeAll()
        
        let url = URL(string: String(format:"https://github.com/users/%@/contributions", arguments: [id]))
        let webData: String
        do {
            webData = try String(contentsOf: url!, encoding: String.Encoding.utf8)
        } catch {
            print("Get data error")
            return nil
        }
        let pattern = "(fill=\")(#[^\"]{6})(\" data-count=\")([^\"]{1,})(\" data-date=\")([^\"]{10})(\"/>)"
        var reg: NSRegularExpression
        do {
            reg = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options(rawValue: 0))
        } catch {
            print("Regex error")
            return nil
        }
        let matched = reg.matches(in: webData, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSRange(location: 0, length: webData.characters.count))
        
        let nsWebData = NSString(string: webData)
        for item in matched {
            let colorString = nsWebData.substring(with: item.range(at:2))
            let data = nsWebData.substring(with: item.range(at:4))
            let dateString = nsWebData.substring(with: item.range(at:6))
            
            let itemData = GitHubCommitData(date: dateFormatter.date(from: dateString)!,
                                            color: colorFrom(hexString: colorString),
                                            count: Int(data)!)
            commitArray.append(itemData)
        }
        
        for commitItem in commitArray {
            print(commitItem.description)
        }
        
        return commitArray
    }
    
    private func colorFrom(hexString string: String) -> UIColor {
        var rgbValue: UInt32 = 0
        let scanner = Scanner(string: string)
        scanner.scanLocation = 1
        scanner.scanHexInt32(&rgbValue)
        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0xFF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0xFF) / 255.0
        return UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1.0)
    }
}
