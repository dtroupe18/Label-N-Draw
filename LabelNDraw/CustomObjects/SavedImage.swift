//
//  SavedImage.swift
//  SnapChatCamera
//
//  Created by Dave on 12/22/17.
//  Copyright © 2017 Dave. All rights reserved.
//

import Foundation
import UIKit

class SavedImage: NSObject {
    
    var relativePath: String!
    var image: UIImage!
    
    init(relativePath: String, image: UIImage) {
        self.relativePath = relativePath
        self.image = image
    }
}
