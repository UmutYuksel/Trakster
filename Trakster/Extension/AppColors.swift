//
//  AppColors.swift
//  Trakster
//
//  Created by Umut Yüksel on 25.07.2024.
//

import Foundation
import UIKit

extension UIButton {
 
    func seperatorColorBorder() {
        layer.cornerRadius = 10
        layer.borderColor = UIColor.separator.cgColor
        layer.borderWidth = 1
    }
    
    func tintColorBorder() {
        layer.cornerRadius = 10
        layer.borderColor = UIColor.border.cgColor
        layer.borderWidth = 1
    }
}
