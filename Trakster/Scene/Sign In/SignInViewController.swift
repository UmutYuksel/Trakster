//
//  SignInViewController.swift
//  Trakster
//
//  Created by Umut Yüksel on 25.07.2024.
//

import UIKit
import Combine

class SignInViewController: UIViewController {
    
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
