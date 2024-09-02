//
//  GoogleAuthenticationService.swift
//  Trakster
//
//  Created by İrem Eriçek on 2.09.2024.
//

import Foundation
import Firebase
import GoogleSignIn

class GoogleAuthenticationService: AuthenticationService {
    func signInWithGoogle(idToken: String, accessToken: String, completion: @escaping (Result<User, Error>) -> Void) {
        let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
        
        Auth.auth().signIn(with: credential) { result, error in
            if let error = error {
                completion(.failure(error))
            } else if let user = result?.user {
                let user = User(uid: user.uid, email: user.email!,username: user.email!)
                completion(.success(user))
            }
        }
    }
    
    // Empty implementation for Apple Sign-In
    func signInWithApple(completion: @escaping (Result<User, Error>) -> Void) {
        // GoogleAuthenticationService does not handle Apple Sign-In
        fatalError("Apple Sign-In is not supported by GoogleAuthenticationService")
    }
}

