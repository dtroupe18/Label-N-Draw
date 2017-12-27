//
//  Draw.swift
//  SnapChatCamera
//
//  Created by Dave on 9/23/17.
//  Copyright © 2017 Dave. All rights reserved.
//

import UIKit

class DrawSquare: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let h = rect.height
        let w = rect.width
        let color:UIColor = UIColor.yellow
        
        let drect = CGRect(x: (w * 0.25),y: (h * 0.25),width: (w * 0.5),height: (h * 0.5))
        let bpath:UIBezierPath = UIBezierPath(rect: drect)
        
        color.set()
        bpath.stroke()
    }
    
}
