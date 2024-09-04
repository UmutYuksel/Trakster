//
//  SignInViewController.swift
//  Trakster
//
//  Created by Umut Yüksel on 25.07.2024.
//

import UIKit
import Combine

class SignInViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var secureTextButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var appleSignInButton: UIButton!
    @IBOutlet weak var googleSignInButton: UIButton!
    
    var viewModel = SignInViewModel()
    private var cancellables = Set<AnyCancellable>()
        
    @objc private func buttonTouchDown(_ sender: UIButton) {
        viewModel.handleButtonTouchDown() // Notify ViewModel that the button was pressed down
    }
        
    @objc private func buttonTouchUp(_ sender: UIButton) {
        viewModel.handleButtonTouchUp() // Notify ViewModel that the button was released
    }
        
    private func updateButtonImage() {
        let image = viewModel.buttonImage()
        secureTextButton.setImage(image, for: .normal)
    }
    
    fileprivate func secureTextButtonAddTarget() {
        // Bind button touch events
        secureTextButton.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        secureTextButton.addTarget(self, action: #selector(buttonTouchUp(_:)), for: .touchUpInside)
        secureTextButton.addTarget(self, action: #selector(buttonTouchUp(_:)), for: .touchUpOutside)
    }
    
    fileprivate func bindViewModel() {
        // Bind ViewModel's isSecure property to the text field
        viewModel.$isSecure
            .sink { [weak self] isSecure in
                DispatchQueue.main.async { // Perform UI updates on the main thread
                    self?.passwordTextField.isSecureTextEntry = isSecure
                    self?.updateButtonImage()
                }
            }
            .store(in: &cancellables)
    }
    
    fileprivate func prepareButtonBorders() {
        appleSignInButton.seperatorColorBorder()
        googleSignInButton.seperatorColorBorder()
        viewModel.signUpAttributedString(button: signUpButton)
    }
        
    @IBAction func signInWithEmail(_ sender: Any) {
        guard let email = emailTextField.text, !email.isEmpty,
                let password = passwordTextField.text, !password.isEmpty else {
            // Show error: Email and password cannot be empty
            return
        }
            
        viewModel.signInWithEmail(email: email, password: password) { result in
            switch result {
            case .success(let user):
                // Handle successful sign-in
                print("Sign in successful: \(user)")
                // Navigate to the main screen or perform other actions
            case .failure(let error):
                // Handle sign-in error
                print("Sign in failed: \(error.localizedDescription)")
            }
        }
    }
        
    @IBAction func signInWithGoogle(_ sender: Any) {
        viewModel.signInWithGoogle(presentingViewController: self) { result in
            switch result {
            case .success(let idToken):
                // Handle successful Google sign-in
                print("Google sign-in successful with token: \(idToken)")
                // Navigate to the main screen or perform other actions
            case .failure(let error):
                // Handle Google sign-in error
                print("Google sign-in failed: \(error.localizedDescription)")
            }
        }
    }
        
    @IBAction func signInWithApple(_ sender: Any) {
        viewModel.signInWithApple()
    }
    
    @IBAction func signUpButtonPressed(_ sender: Any) {
        dismiss(animated: true) {
            self.viewModel.toSignUpViewController()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareSheetVC()
        prepareButtonBorders()
        secureTextButtonAddTarget()
        bindViewModel()
        
        viewModel.onSignInSuccess = { [weak self] in
            DispatchQueue.main.async {
                self?.performSegue(withIdentifier: "signUpToHome", sender: nil)
            }
        }
        
        viewModel.onSignInFailure = { error in
            DispatchQueue.main.async {
                print("Sign up failed: \(error.localizedDescription)")
            }
        }

    }
}

extension SignInViewController: UISheetPresentationControllerDelegate {
    
    override var sheetPresentationController: UISheetPresentationController? {
        presentationController as? UISheetPresentationController
    }
            
    private func prepareSheetVC() {
        sheetPresentationController?.delegate = self
        sheetPresentationController?.selectedDetentIdentifier = .medium
        sheetPresentationController?.prefersGrabberVisible = true
        sheetPresentationController?.detents = [.custom(resolver: { context in
            return 550
        })]
    }
}
