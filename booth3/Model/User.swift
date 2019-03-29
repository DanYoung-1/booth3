//
//  User.swift
//  booth2
//
//  Created by Daniel Young on 3/26/19.
//  Copyright © 2019 Daniel Young. All rights reserved.
//

import Foundation

// folder scope?? needed type, wierd

let kUserDefaultsKey: String = "user"

struct User: Codable {
    let id: Int
    let email: String
}
