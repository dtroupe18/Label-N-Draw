//
//  Helper.swift
//  LabelNDraw
//
//  Created by Dave on 1/23/18.
//

import Foundation
import UIKit

class Helper {
    
    // Function that can be used to show a generic alert message
    //
    static func showAlertMessage(vc: UIViewController, title: String, message: String) -> Void {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(defaultAction)
        DispatchQueue.main.async {
            vc.present(alert, animated: true, completion: nil)
        }
    }
}
