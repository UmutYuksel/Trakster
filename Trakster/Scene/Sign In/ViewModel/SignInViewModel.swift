//
//  SignInViewModel.swift
//  Trakster
//
//  Created by Umut Yüksel on 25.07.2024.
//

import Foundation
import UIKit
import Combine
import Firebase
import GoogleSignIn
import AuthenticationServices

class SignInViewModel : NSObject {
    
    @Published var isSecure: Bool = true
    private var cancellables = Set<AnyCancellable>()
    
    private let buttonTouchDownSubject = PassthroughSubject<Void, Never>()
    private let buttonTouchUpSubject = PassthroughSubject<Void, Never>()
    
    var onSignInSuccess: (() -> Void)?
    var onSignInFailure: ((Error) -> Void)?
    
    override init() {
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
    
    // Handle button touch down event
    func handleButtonTouchDown() {
        buttonTouchDownSubject.send(())
    }
    
    // Handle button touch up event
    func handleButtonTouchUp() {
        buttonTouchUpSubject.send(())
    }
    
    // Toggle secure entry for the password field
    private func toggleSecureEntry() {
        isSecure.toggle()
    }
    
    // Return the appropriate image for the secure text button
    func buttonImage() -> UIImage? {
        return UIImage(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
    }
    
    // Create an attributed string for the sign-up button
    func signUpAttributedString(button: UIButton) {
        let attributedString1 = NSAttributedString(
            string: "Don't have an account?",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.greyLabel]
        )
        let attributedString2 = NSAttributedString(
            string: "Sign Up",
            attributes: [
                NSAttributedString.Key.foregroundColor: UIColor.greenTint,
                NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        )
        
        let combination = NSMutableAttributedString()
        combination.append(attributedString1)
        combination.append(NSAttributedString(string: " "))
        combination.append(attributedString2)
        
        button.setAttributedTitle(combination, for: .normal)
    }
    
    // Navigate to the SignUpViewController
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

// MARK: - SignIn with Email
extension SignInViewModel {
    // Sign in with email and password
    func signInWithEmail(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                self.onSignInFailure?(error)
                return
            }
            
            guard let firebaseUser = result?.user else {
                completion(.failure(NSError(domain: "SignInError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not found."])))
                return
            }
            
            // Fetch additional user details from Firestore
            let db = Firestore.firestore()
            db.collection("Users").document(firebaseUser.uid).getDocument { document, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let document = document, document.exists, let data = document.data() else {
                    completion(.failure(NSError(domain: "FirestoreError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User details not found."])))
                    return
                }
                
                let username = data["Username"] as? String ?? ""
                let user = User(uid: firebaseUser.uid, email: firebaseUser.email ?? "", username: username)
                completion(.success(user))
                self.onSignInSuccess?()
            }
        }
    }
}

// MARK: - Google SignIn
extension SignInViewModel {
    // Sign in with Google
    func signInWithGoogle(presentingViewController: UIViewController, completion: @escaping (Result<String, Error>) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(.failure(NSError(domain: "ClientIDError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Client ID not found."])))
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
            guard let user = result?.user, error == nil, let idToken = user.idToken?.tokenString else {
                completion(.failure(error ?? NSError(domain: "SignInError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Google sign-in failed."])))
                return
            }
            
            // Handle the Google sign-in result
            completion(.success(idToken))
            self.onSignInSuccess?()
        }
    }
}

// MARK: - Apple SignIn
extension SignInViewModel: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    // Initiate Apple Sign-In process
    func signInWithApple() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    // Handle successful Apple Sign-In
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
            
            // Handle the Apple sign-in result
            print("Apple sign-in successful.")
            self.onSignInSuccess?()
        }
    }
    
    // Handle failed Apple Sign-In
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple sign-in failed: \(error.localizedDescription)")
        self.onSignInFailure?(error)
    }
    
    // Provide the presentation anchor for ASAuthorizationController
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Get the current UIWindowScene
        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0 is UIWindowScene }) as? UIWindowScene {
            return windowScene.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
        }
        // Fallback in case no window scene is found
        return ASPresentationAnchor()
    }
}
