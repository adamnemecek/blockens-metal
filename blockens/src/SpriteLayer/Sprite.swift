//
// Created by Bjorn Tipling on 8/8/16.
// Copyright (c) 2016 apphacker. All rights reserved.
//

import Foundation

protocol Sprite {
    func gridNumber() -> Int32
    func update() -> [Int32]
}