//
//  SignUpViewController.swift
//  Trakster
//
//  Created by Umut Yüksel on 26.07.2024.
//

import UIKit
import Combine
import Firebase
import GoogleSignIn
import AuthenticationServices

class SignUpViewController: UIViewController {
    

    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var appleSignInButton: UIButton!
    @IBOutlet weak var googleSignInButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var secureTextButton: UIButton!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    
    var viewModel: SignUpViewModel!

    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Başlatıcı bağımlılıkları buradan geçiyoruz
        let appleAuthService = AppleAuthenticationService() // Bu sınıfı uygun şekilde oluşturun
        let googleAuthService = GoogleAuthenticationService() // Bu sınıfı uygun şekilde oluşturun
        viewModel = SignUpViewModel(appleAuthService: appleAuthService, googleAuthService: googleAuthService)
            
        prepareSheetVC()
        prepareButtonBorders()
        secureTextButtonAddTarget()
        bindViewModel()
            
        viewModel.onSignUpSuccess = { [weak self] in
            DispatchQueue.main.async {
                self?.performSegue(withIdentifier: "signUpToHome", sender: nil)
            }
        }
        
        viewModel.onSignUpFailure = { error in
            DispatchQueue.main.async {
                print("Sign up failed: \(error.localizedDescription)")
            }
        }
    }
    
    fileprivate func bindViewModel() {
        viewModel.$isSecure
            .sink { [weak self] isSecure in
                DispatchQueue.main.async {
                    self?.passwordTextField.isSecureTextEntry = isSecure
                    self?.updateButtonImage()
                }
            }
            .store(in: &cancellables)
    }
    
    fileprivate func prepareTextFields() {
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        emailTextField.delegate = self
                
        updateSignUpButtonState()
                
        usernameTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        emailTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        updateSignUpButtonState()
    }
    
    private func updateSignUpButtonState() {
        let isUsernameEmpty = usernameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
        let isPasswordEmpty = passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
        let isEmailEmpty = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
            
        signUpButton.isEnabled = !isUsernameEmpty && !isPasswordEmpty && !isEmailEmpty
    }
    
    fileprivate func prepareButtonBorders() {
        appleSignInButton.seperatorColorBorder()
        googleSignInButton.seperatorColorBorder()
        viewModel.signInAttributedString(button: signInButton)
    }
    
    @objc private func buttonTouchDown(_ sender: UIButton) {
        viewModel.handleButtonTouchDown()
    }
    
    @objc private func buttonTouchUp(_ sender: UIButton) {
        viewModel.handleButtonTouchUp()
    }
    
    private func updateButtonImage() {
        let image = viewModel.secureTextButtonImage()
        secureTextButton.setImage(image, for: .normal)
    }
    
    fileprivate func secureTextButtonAddTarget() {
        secureTextButton.addTarget(self, action: #selector(buttonTouchDown(_:)), for: .touchDown)
        secureTextButton.addTarget(self, action: #selector(buttonTouchUp(_:)), for: .touchUpInside)
        secureTextButton.addTarget(self, action: #selector(buttonTouchUp(_:)), for: .touchUpOutside)
    }
    
    @IBAction func signInButtonPressed(_ sender: Any) {
        dismiss(animated: true) {
            self.viewModel.toSignInViewController()
        }
    }
    
    @IBAction func googleSignInPressed(_ sender: Any) {
        viewModel.signInWithGoogle(presentingViewController: self) { result in
                switch result {
                case .success(let message):
                    print(message) // "Sign-in successful."
                case .failure(let error):
                    print("Sign-in failed: \(error.localizedDescription)")
                }
            }
    }

    
    @IBAction func appleSignInPressed(_ sender: Any) {
        viewModel.signInWithApple()
    }
    
    @IBAction func signUpButtonPressed(_ sender: Any) {
        guard let username = usernameTextField.text,
              let password = passwordTextField.text,
              let email = emailTextField.text else { return }
    
        viewModel.signUpWithEmail(username: username, password: password, email: email, view: self.view)
    }

    private func prepareSheetVC() {
        sheetPresentationController?.delegate = self
        sheetPresentationController?.selectedDetentIdentifier = .medium
        sheetPresentationController?.prefersGrabberVisible = true
        sheetPresentationController?.detents = [.custom(resolver: { context in
            return 560
        })]
    }
}

extension SignUpViewController : UISheetPresentationControllerDelegate {
    override var sheetPresentationController: UISheetPresentationController? {
        presentationController as? UISheetPresentationController
    }
}

extension SignUpViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        updateSignUpButtonState()
        return true
    }
}
