//
//  SignUpViewModel.swift
//  Trakster
//
//  Created by Umut Yüksel on 26.07.2024.
//

import Foundation
import Combine
import Firebase
import JGProgressHUD
import GoogleSignIn
import AuthenticationServices

class SignUpViewModel: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    @Published var isSecure: Bool = true
    private var cancellables = Set<AnyCancellable>()
    
    private let appleAuthService: AuthenticationService
    private let googleAuthService: AuthenticationService

    private let buttonTouchDownSubject = PassthroughSubject<Void, Never>()
    private let buttonTouchUpSubject = PassthroughSubject<Void, Never>()
    
    var onSignUpSuccess: (() -> Void)?
    var onSignUpFailure: ((Error) -> Void)?

    init(appleAuthService: AuthenticationService, googleAuthService: AuthenticationService) {
        self.appleAuthService = appleAuthService
        self.googleAuthService = googleAuthService
        super.init()
        
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

    // Function to handle Apple Sign-In process
    func signInWithApple() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }

    // Delegate method called when Apple Sign-In is completed
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            // Call the authentication service
            appleAuthService.signInWithApple { [weak self] result in
                switch result {
                case .success(let user):
                    let uid = user.uid
                    let email = user.email ?? ""
                    self?.saveUserDetails(userId: uid, username: "Apple User", email: email, password: "")
                case .failure(let error):
                    self?.onSignUpFailure?(error)
                }
            }
        }
    }
    
    // Delegate method called when Apple Sign-In fails
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Sign in with Apple failed: \(error.localizedDescription)")
        self.onSignUpFailure?(error)
    }
    
    // Presentation anchor for the ASAuthorizationController
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first { $0.isKeyWindow }!
    }

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
        googleAuthService.signInWithGoogle(idToken: idToken, accessToken: accessToken) { [weak self] result in
            switch result {
            case .success(let user):
                let uid = user.uid
                let email = user.email ?? ""
                self?.saveUserDetails(userId: uid, username: email, email: email, password: "")
            case .failure(let error):
                self?.onSignUpFailure?(error)
            }
        }
    }

    private func handleSignUpError(_ error: Error, in view: UIView) {
        let signUpHud = JGProgressHUD(style: .light)
        signUpHud.dismiss(afterDelay: 0.5)
        
        let errorHud = JGProgressHUD(style: .light)
        errorHud.indicatorView = JGProgressHUDErrorIndicatorView()
        errorHud.textLabel.text = "Sign Up Failed."
        errorHud.detailTextLabel.text = "\(error.localizedDescription)"
        errorHud.show(in: view, animated: true, afterDelay: 1)
        errorHud.dismiss(afterDelay: 2)
    }

    func saveUserDetails(userId: String, username: String, email: String, password: String) {
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
        let attributedString1 = NSAttributedString(string: "Already have an account?", attributes:
            [NSAttributedString.Key.foregroundColor: UIColor.greyLabel])
        let attributedString2 = NSAttributedString(string: "Sign In", attributes:
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
