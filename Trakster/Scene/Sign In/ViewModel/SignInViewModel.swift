//
//  SignInViewModel.swift
//  Trakster
//
//  Created by Umut Yüksel on 25.07.2024.
//

import Foundation
import UIKit
import Combine

class SignInViewModel {
    
    @Published var isSecure: Bool = true
    private var cancellables = Set<AnyCancellable>()
    
    private let buttonTouchDownSubject = PassthroughSubject<Void, Never>()
    private let buttonTouchUpSubject = PassthroughSubject<Void, Never>()
    
    init() {
        buttonTouchDownSubject
            .sink { [weak self] in
                self?.toggleSecureEntry()
            }
            .store(in: &cancellables)
        
        buttonTouchUpSubject
            .sink { [weak self] in
                self?.toggleSecureEntry()
            }
            .store(in: &cancellables)
    }
    
    func handleButtonTouchDown() {
        buttonTouchDownSubject.send(())
    }
    
    func handleButtonTouchUp() {
        buttonTouchUpSubject.send(())
    }
    
    private func toggleSecureEntry() {
        isSecure.toggle()
    }
    
    func buttonImage() -> UIImage? {
        return UIImage(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
    }
    
    func signUpAttributedString(button: UIButton) {
        let attributedString1 = NSAttributedString(string: "Hesabın yok mu?", attributes:
                                                    [NSAttributedString.Key.foregroundColor: UIColor.greyLabel])
        let attributedString2 = NSAttributedString(string: "Üye Ol", attributes:
                                                    [NSAttributedString.Key.foregroundColor: UIColor.greenTint,
                                                     NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue])
        
        let combination = NSMutableAttributedString()
        combination.append(attributedString1)
        combination.append(NSAttributedString(string: " "))
        combination.append(attributedString2)
        
        button.setAttributedTitle(combination, for: .normal)
    }
    
    func toSignUpViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let signUpViewController = storyboard.instantiateViewController(withIdentifier: "SignUpViewController") as? SignUpViewController {
            // Get the current UIWindowScene
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                if let rootViewController = windowScene.windows.first?.rootViewController {
                    rootViewController.present(signUpViewController, animated: true, completion: nil)
                }
            }
        }
    }
}
