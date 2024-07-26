//
//  SignUpViewModel.swift
//  Trakster
//
//  Created by Umut Yüksel on 26.07.2024.
//

import Foundation
import UIKit
import Combine
import Firebase
import JGProgressHUD
import GoogleSignIn

class SignUpViewModel {
    @Published var isSecure: Bool = true
    private var cancellables = Set<AnyCancellable>()
    
    private let buttonTouchDownSubject = PassthroughSubject<Void, Never>()
    private let buttonTouchUpSubject = PassthroughSubject<Void, Never>()
    
    var onSignUpSuccess: (() -> Void)?
    var onSignUpFailure: ((Error) -> Void)?

    func signUpWithEmail(username: String, password: String, email: String, view: UIView) {
            
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                self?.handleSignUpError(error, in: view)
                return
            }
                
            guard let user = authResult?.user else {
                return
            }
            
            self?.saveUserDetails(userId: user.uid, username: username, email: email, password: password)
        }
    }
    
    func signInWithGoogle(idToken: String, accessToken: String) {
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken,accessToken: accessToken)
        
        Auth.auth().signIn(with: credential) { [weak self] result, error in

            guard let _ = result, error == nil else {return}
            
            let userUID = result?.user.uid
            let username = result?.user.email
            let email = result?.user.email
            
            self?.saveUserDetails(userId: userUID!, username: username!, email: email!, password: "")
            
        }
            
    }

    private func handleSignUpError(_ error: Error, in view: UIView) {
            
        let signUpHud = JGProgressHUD(style: .light)
        signUpHud.dismiss(afterDelay: 0.5)
            
        let errorHud = JGProgressHUD(style: .light)
        errorHud.indicatorView = JGProgressHUDErrorIndicatorView()
        errorHud.textLabel.text = "Üye Olunamadı."
        errorHud.detailTextLabel.text = "\(error.localizedDescription)"
        errorHud.show(in: view, animated: true, afterDelay: 1)
        errorHud.dismiss(afterDelay: 2)
        
    }

    private func saveUserDetails(userId: String, username: String, email: String, password: String) {
        let db = Firestore.firestore()
        
        let userDetails = ["Username" : username,
                            "UserID" : userId,
                            "E-Mail" : email,
                            "Password" : password]
            
        db.collection("Users").document(userId).setData(userDetails) { error in
            if let error = error {
                self.onSignUpFailure?(error)
                return
            }
                self.onSignUpSuccess?()
        }
    }
    
    func googleSignIn() {
        
    }
    
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
    
    func secureTextButtonImage() -> UIImage? {
        return UIImage(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
    }
    
    func signInAttributedString(button: UIButton) {
        let attributedString1 = NSAttributedString(string: "Hesabın var mı?", attributes:
                                                    [NSAttributedString.Key.foregroundColor: UIColor.greyLabel])
        let attributedString2 = NSAttributedString(string: "Giriş Yap", attributes:
                                                    [NSAttributedString.Key.foregroundColor: UIColor.greenTint,
                                                     NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue])
        
        let combination = NSMutableAttributedString()
        combination.append(attributedString1)
        combination.append(NSAttributedString(string: " "))
        combination.append(attributedString2)
        
        button.setAttributedTitle(combination, for: .normal)
    }
    
    func toSignInViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let signUpViewController = storyboard.instantiateViewController(withIdentifier: "SignInViewController") as? SignInViewController {
            // Get the current UIWindowScene
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                if let rootViewController = windowScene.windows.first?.rootViewController {
                    rootViewController.present(signUpViewController, animated: true, completion: nil)
                }
            }
        }
    }
}
