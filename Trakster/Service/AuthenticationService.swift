//
//  AuthenticationService.swift
//  Trakster
//
//  Created by İrem Eriçek on 2.09.2024.
//

import Foundation
import AuthenticationServices
import GoogleSignIn
import Firebase

protocol AuthenticationService {
    func signInWithApple(completion: @escaping (Result<User, Error>) -> Void)
    func signInWithGoogle(idToken: String, accessToken: String, completion: @escaping (Result<User, Error>) -> Void)
}

