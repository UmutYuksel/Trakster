//
//  AppleAuthenticationService.swift
//  Trakster
//
//  Created by İrem Eriçek on 2.09.2024.
//

import AuthenticationServices
import FirebaseAuth

class AppleAuthenticationService: NSObject, AuthenticationService, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    private var signInCompletion: ((Result<User, Error>) -> Void)?
    
    func signInWithGoogle(idToken: String, accessToken: String, completion: @escaping (Result<User, Error>) -> Void) {
            // AppleAuthenticationService does not handle Google Sign-In
            fatalError("Google Sign-In is not supported by AppleAuthenticationService")
        }
    
    func signInWithApple(completion: @escaping (Result<User, Error>) -> Void) {
        self.signInCompletion = completion
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
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
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nil)
            
            Auth.auth().signIn(with: credential) { result, error in
                if let error = error {
                    self.signInCompletion?(.failure(error))
                } else if let user = result?.user {
                    let user = User(uid: user.uid, email: user.email!,username: user.email!)
                    self.signInCompletion?(.success(user))
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        self.signInCompletion?(.failure(error))
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first { $0.isKeyWindow }!
    }
}
