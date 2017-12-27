//
//  ImageCell.swift
//  SnapChatCamera
//
//  Created by Dave on 12/20/17.
//  Copyright © 2017 Dave. All rights reserved.
//

import UIKit

class ImageCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    
    // Closures
    var deleteTapAction: ((UICollectionViewCell) -> Void)?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = UIImage()
    }
    
    @IBAction func deletePressed(_ sender: Any) {
        if sender is UIButton {
            deleteTapAction?(self)
        }
    }
}
