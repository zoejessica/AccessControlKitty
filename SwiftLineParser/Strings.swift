//
//  Strings.swift
//  SwiftLineParser
//
//  Created by Zoe Smith on 4/24/18.
//  Copyright © 2018 Hot Beverage. All rights reserved.
//

import Foundation

// .*? means match any character as few times as possible
let stringRegex = try! NSRegularExpression(pattern: "\".*?\"[^\"]", options: [])
let multiLineRegex = try! NSRegularExpression(pattern: "\"\"\"\n", options: [])
