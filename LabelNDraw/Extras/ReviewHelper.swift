//
//  ReviewHelper.swift
//  LabelNDraw
//
//  Created by Dave on 5/12/18.
//

import Foundation
import StoreKit

struct ReviewHelper {
    
    private static let defaults = UserDefaults.standard
    private static let savedImageKey = "savedImageCount"
    
    static func incrementSavedImageCount() {
        guard var savedImageCount = defaults.value(forKey: savedImageKey) as? Int else {
            defaults.set(1, forKey: savedImageKey)
            return
        }
        savedImageCount += 1
        defaults.set(savedImageCount, forKey: savedImageKey)
    }
    
    static func checkAndAskForReview() {
        
        guard let savedImageCount = defaults.value(forKey: savedImageKey) as? Int else {
            defaults.set(1, forKey: savedImageKey)
            return
        }
        
        switch savedImageCount {
        case 4:
            ReviewHelper().requestReview()
        case _ where savedImageCount % 10 == 0:
            // User will only be asked a max of 3 times per year
            //
            ReviewHelper().requestReview()
        default:
            print("Saved image count: \(savedImageCount)")
            break
        }
    }
    
    fileprivate func requestReview() {
        if #available(iOS 10.3, *) {
            SKStoreReviewController.requestReview()
        }
    }
    
    private enum UserDefaultKeys: String {
        case launchCount
    }
}
