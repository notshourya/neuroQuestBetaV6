# NeuroQuest: Programmatic UIKit Implementation Examples

This document provides detailed, copy-paste ready code examples for converting specific NeuroQuest views from SwiftUI to programmatic UIKit.

## Table of Contents
1. [App Entry Point](#app-entry-point)
2. [Root View Controller](#root-view-controller)
3. [Authentication Views](#authentication-views)
4. [Tab Bar Controllers](#tab-bar-controllers)
5. [Home Dashboard](#home-dashboard)
6. [Games Module](#games-module)
7. [Reusable Components](#reusable-components)

---

## App Entry Point

### AppDelegate.swift

```swift
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    // MARK: - Shared Services
    let auth = Authentication()
    let gameDataStore = GameDataStore()
    
    func application(_ application: UIApplication, 
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Create window
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // Create root view controller
        let rootVC = RootViewController()
        rootVC.auth = auth
        rootVC.gameDataStore = gameDataStore
        
        // Set root and make visible
        window?.rootViewController = rootVC
        window?.makeKeyAndVisible()
        
        // Configure appearance
        configureAppearance()
        
        return true
    }
    
    private func configureAppearance() {
        // Navigation Bar Appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = .systemBackground
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        
        // Tab Bar Appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = .systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    // MARK: - UISceneSession Lifecycle (for iOS 13+)
    
    func application(_ application: UIApplication, 
                    configurationForConnecting connectingSceneSession: UISceneSession, 
                    options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
```

### SceneDelegate.swift (Optional, for iOS 13+)

```swift
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        window = UIWindow(windowScene: windowScene)
        
        let rootVC = RootViewController()
        rootVC.auth = appDelegate.auth
        rootVC.gameDataStore = appDelegate.gameDataStore
        
        window?.rootViewController = rootVC
        window?.makeKeyAndVisible()
    }
}
```

---

## Root View Controller

### RootViewController.swift

```swift
import UIKit
import Combine

class RootViewController: UIViewController {
    
    // MARK: - Properties
    var auth: Authentication!
    var gameDataStore: GameDataStore!
    
    private var cancellables = Set<AnyCancellable>()
    private var currentViewController: UIViewController?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupObservers()
        updateRootViewController(animated: false)
    }
    
    // MARK: - Setup
    private func setupObservers() {
        // Observe authentication state
        Publishers.CombineLatest3(
            auth.$isAuthenticated,
            auth.$isAuthenticating,
            auth.$isSigningOut
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] _, _, _ in
            self?.updateRootViewController(animated: true)
        }
        .store(in: &cancellables)
        
        // Observe user role changes
        auth.$userRole
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                if self?.auth.isAuthenticated == true {
                    self?.updateRootViewController(animated: true)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - View Management
    private func updateRootViewController(animated: Bool) {
        let newViewController: UIViewController
        
        // Determine which view controller to show
        if auth.isSigningOut {
            newViewController = SignOutLoadingViewController()
        } else if auth.isAuthenticating {
            newViewController = PostAuthLoadingViewController()
        } else if auth.isAuthenticated {
            switch auth.userRole {
            case .patient:
                let tabBarVC = PatientTabBarController()
                tabBarVC.auth = auth
                tabBarVC.gameDataStore = gameDataStore
                newViewController = tabBarVC
                
            case .admin:
                let tabBarVC = AdminTabBarController()
                tabBarVC.auth = auth
                newViewController = tabBarVC
                
            case .none:
                let welcomeVC = WelcomeViewController()
                welcomeVC.auth = auth
                newViewController = UINavigationController(rootViewController: welcomeVC)
            }
        } else {
            let welcomeVC = WelcomeViewController()
            welcomeVC.auth = auth
            newViewController = UINavigationController(rootViewController: welcomeVC)
        }
        
        // Transition to new view controller
        transitionToViewController(newViewController, animated: animated)
    }
    
    private func transitionToViewController(_ newViewController: UIViewController, animated: Bool) {
        // Remove old view controller
        if let oldVC = currentViewController {
            oldVC.willMove(toParent: nil)
            
            if animated {
                UIView.transition(with: view, duration: 0.3, options: .transitionCrossDissolve) {
                    oldVC.view.removeFromSuperview()
                } completion: { _ in
                    oldVC.removeFromParent()
                }
            } else {
                oldVC.view.removeFromSuperview()
                oldVC.removeFromParent()
            }
        }
        
        // Add new view controller
        addChild(newViewController)
        newViewController.view.frame = view.bounds
        newViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        if animated {
            newViewController.view.alpha = 0
            view.addSubview(newViewController.view)
            
            UIView.animate(withDuration: 0.3) {
                newViewController.view.alpha = 1
            } completion: { _ in
                newViewController.didMove(toParent: self)
            }
        } else {
            view.addSubview(newViewController.view)
            newViewController.didMove(toParent: self)
        }
        
        currentViewController = newViewController
    }
}
```

---

## Authentication Views

### WelcomeViewController.swift

```swift
import UIKit
import SpriteKit

class WelcomeViewController: UIViewController {
    
    // MARK: - Properties
    var auth: Authentication!
    
    // MARK: - UI Components
    private let gradientLayer = CAGradientLayer()
    private var spriteView: SKView?
    
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let iconContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "waveform.mid")
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Welcome to NeuroQuest"
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Your personal, game based path to wellness."
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let buttonStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var getStartedButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Get Started"
        config.cornerStyle = .large
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(getStartedTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var loginButton: UIButton = {
        var config = UIButton.Configuration.plain()
        
        let attributedTitle = AttributedString(
            "Already have an account? Log In",
            attributes: AttributeContainer([
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.label
            ])
        )
        config.attributedTitle = attributedTitle
        
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateEntrance()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
        spriteView?.frame = view.bounds
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Gradient Background
        gradientLayer.colors = [
            UIColor.systemBlue.withAlphaComponent(0.15).cgColor,
            UIColor.systemBackground.cgColor
        ]
        gradientLayer.type = .radial
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        // Particle Effect (optional)
        setupParticleEffect()
        
        // Add icon to container
        iconContainerView.addSubview(iconImageView)
        
        // Add views to content stack
        contentStackView.addArrangedSubview(iconContainerView)
        
        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 12
        textStack.alignment = .center
        contentStackView.addArrangedSubview(textStack)
        
        // Add buttons to button stack
        buttonStackView.addArrangedSubview(getStartedButton)
        buttonStackView.addArrangedSubview(loginButton)
        
        // Add to view
        view.addSubview(contentStackView)
        view.addSubview(buttonStackView)
        
        // Initial state for animation
        iconImageView.alpha = 0
        iconImageView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        titleLabel.alpha = 0
        titleLabel.transform = CGAffineTransform(translationX: 0, y: 20)
        subtitleLabel.alpha = 0
        subtitleLabel.transform = CGAffineTransform(translationX: 0, y: 20)
        buttonStackView.alpha = 0
        buttonStackView.transform = CGAffineTransform(translationX: 0, y: 30)
    }
    
    private func setupParticleEffect() {
        let skView = SKView(frame: view.bounds)
        skView.backgroundColor = .clear
        skView.allowsTransparency = true
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(skView, at: 1)
        
        let scene = ParticleScene(size: skView.bounds.size)
        scene.backgroundColor = .clear
        skView.presentScene(scene)
        
        spriteView = skView
        spriteView?.alpha = 0
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Icon Image View
            iconImageView.widthAnchor.constraint(equalToConstant: 200),
            iconImageView.heightAnchor.constraint(equalToConstant: 200),
            iconImageView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            
            // Icon Container
            iconContainerView.widthAnchor.constraint(equalToConstant: 200),
            iconContainerView.heightAnchor.constraint(equalToConstant: 200),
            
            // Content Stack
            contentStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            contentStackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            contentStackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40),
            
            // Button Stack
            buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            buttonStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            
            // Get Started Button
            getStartedButton.heightAnchor.constraint(equalToConstant: 54),
            getStartedButton.widthAnchor.constraint(equalTo: buttonStackView.widthAnchor)
        ])
    }
    
    // MARK: - Animations
    private func animateEntrance() {
        // Icon animation
        UIView.animate(
            withDuration: 0.6,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut
        ) {
            self.iconImageView.alpha = 1.0
            self.iconImageView.transform = .identity
        }
        
        // Particle effect fade in
        UIView.animate(withDuration: 0.4, delay: 0.1) {
            self.spriteView?.alpha = 1.0
        }
        
        // Title animation
        UIView.animate(
            withDuration: 0.5,
            delay: 0.15,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut
        ) {
            self.titleLabel.alpha = 1.0
            self.titleLabel.transform = .identity
            self.subtitleLabel.alpha = 1.0
            self.subtitleLabel.transform = .identity
        }
        
        // Buttons animation
        UIView.animate(
            withDuration: 0.5,
            delay: 0.35,
            usingSpringWithDamping: 0.8,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut
        ) {
            self.buttonStackView.alpha = 1.0
            self.buttonStackView.transform = .identity
        }
    }
    
    // MARK: - Actions
    @objc private func getStartedTapped() {
        let carouselVC = FeatureCarouselViewController()
        carouselVC.auth = auth
        navigationController?.pushViewController(carouselVC, animated: true)
    }
    
    @objc private func loginTapped() {
        let loginVC = LoginViewController()
        loginVC.auth = auth
        loginVC.modalPresentationStyle = .fullScreen
        present(loginVC, animated: true)
    }
}
```

### LoginViewController.swift

```swift
import UIKit
import Combine

class LoginViewController: UIViewController {
    
    // MARK: - Properties
    var auth: Authentication!
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Components
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Log In"
        label.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let emailTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Email"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .emailAddress
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Password"
        textField.borderStyle = .roundedRect
        textField.isSecureTextEntry = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var loginButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Log In"
        config.cornerStyle = .large
        config.baseBackgroundColor = .systemBlue
        
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemRed
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupKeyboardHandling()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Add close button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(emailTextField)
        contentView.addSubview(passwordTextField)
        contentView.addSubview(loginButton)
        contentView.addSubview(errorLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content View
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // Email Field
            emailTextField.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            emailTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            emailTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            emailTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Password Field
            passwordTextField.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 16),
            passwordTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            passwordTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Login Button
            loginButton.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 24),
            loginButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            loginButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            loginButton.heightAnchor.constraint(equalToConstant: 54),
            
            // Error Label
            errorLabel.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 16),
            errorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            errorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            errorLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -24)
        ])
    }
    
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        
        // Tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Actions
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func loginButtonTapped() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showError("Please fill in all fields")
            return
        }
        
        // Validate email format
        guard isValidEmail(email) else {
            showError("Please enter a valid email address")
            return
        }
        
        // Perform login (mock implementation)
        performLogin(email: email, password: password)
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        
        let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    // MARK: - Helpers
    private func performLogin(email: String, password: String) {
        // Mock authentication - in real app, use AuthHelpers
        auth.isAuthenticating = true
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            if password == "password123" {
                self?.auth.isAuthenticated = true
                self?.auth.userRole = email.contains("admin") ? .admin : .patient
                self?.auth.isAuthenticating = false
                self?.dismiss(animated: true)
            } else {
                self?.auth.isAuthenticating = false
                self?.showError("Invalid credentials")
            }
        }
    }
    
    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
        
        // Shake animation
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.6
        animation.values = [-20, 20, -20, 20, -10, 10, -5, 5, 0]
        errorLabel.layer.add(animation, forKey: "shake")
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    // MARK: - Cleanup
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
```

---

## Tab Bar Controllers

### PatientTabBarController.swift

```swift
import UIKit

class PatientTabBarController: UITabBarController {
    
    // MARK: - Properties
    var auth: Authentication!
    var gameDataStore: GameDataStore!
    
    private let patientModel = PatientDataModel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setupTabs()
    }
    
    // MARK: - Setup
    private func setupTabBar() {
        tabBar.tintColor = .systemBlue
        tabBar.unselectedItemTintColor = .systemGray
    }
    
    private func setupTabs() {
        // Home/Summary Tab
        let homeVC = HomeViewController()
        homeVC.auth = auth
        homeVC.gameDataStore = gameDataStore
        homeVC.patientModel = patientModel
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(
            title: "Summary",
            image: UIImage(systemName: "rectangle.3.offgrid"),
            selectedImage: UIImage(systemName: "rectangle.3.offgrid.fill")
        )
        homeNav.tabBarItem.tag = 0
        
        // Games Tab
        let gamesVC = GamesViewController()
        gamesVC.gameDataStore = gameDataStore
        gamesVC.patientModel = patientModel
        let gamesNav = UINavigationController(rootViewController: gamesVC)
        gamesNav.tabBarItem = UITabBarItem(
            title: "Games",
            image: UIImage(systemName: "arcade.stick.console"),
            tag: 1
        )
        
        // My Plan Tab
        let healthVC = HealthViewController()
        healthVC.auth = auth
        healthVC.patientModel = patientModel
        let healthNav = UINavigationController(rootViewController: healthVC)
        healthNav.tabBarItem = UITabBarItem(
            title: "My Plan",
            image: UIImage(systemName: "calendar.badge.clock"),
            tag: 2
        )
        
        // AI Chat Tab (placeholder)
        let chatVC = UIViewController()
        chatVC.view.backgroundColor = .systemBackground
        chatVC.title = "AI Chat"
        let chatLabel = UILabel()
        chatLabel.text = "Companion Chat"
        chatLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        chatLabel.textAlignment = .center
        chatLabel.translatesAutoresizingMaskIntoConstraints = false
        chatVC.view.addSubview(chatLabel)
        NSLayoutConstraint.activate([
            chatLabel.centerXAnchor.constraint(equalTo: chatVC.view.centerXAnchor),
            chatLabel.centerYAnchor.constraint(equalTo: chatVC.view.centerYAnchor)
        ])
        let chatNav = UINavigationController(rootViewController: chatVC)
        chatNav.tabBarItem = UITabBarItem(
            title: "AI Chat",
            image: UIImage(systemName: "apple.image.playground"),
            tag: 3
        )
        
        // Set view controllers
        viewControllers = [homeNav, gamesNav, healthNav, chatNav]
    }
}
```

---

## Home Dashboard

### HomeViewController.swift

```swift
import UIKit
import Combine

class HomeViewController: UIViewController {
    
    // MARK: - Properties
    var auth: Authentication!
    var gameDataStore: GameDataStore!
    var patientModel: PatientDataModel!
    
    private var cancellables = Set<AnyCancellable>()
    private var hasAppeared = false
    
    // MARK: - UI Components
    private let gradientLayer = CAGradientLayer()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        return scrollView
    }()
    
    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 30
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let headerView = HeaderStackView()
    private let dashboardCard = DashboardCardView()
    private let focusSection = FocusSectionView()
    private let consistencySection = ConsistencySectionView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupObservers()
        configureNavigationBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !hasAppeared {
            animateEntrance()
            hasAppeared = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Gradient background
        gradientLayer.colors = [
            UIColor.systemBlue.withAlphaComponent(0.15).cgColor,
            UIColor.systemGroupedBackground.cgColor
        ]
        gradientLayer.type = .radial
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        
        // Configure header
        headerView.profileButtonTapped = { [weak self] in
            self?.showProfile()
        }
        
        // Add sections to stack
        contentStackView.addArrangedSubview(headerView)
        contentStackView.addArrangedSubview(dashboardCard)
        contentStackView.setCustomSpacing(20, after: headerView)
        
        let focusContainer = UIView()
        focusContainer.translatesAutoresizingMaskIntoConstraints = false
        focusContainer.addSubview(focusSection)
        focusSection.pinToSuperview(insets: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        contentStackView.addArrangedSubview(focusContainer)
        
        let consistencyContainer = UIView()
        consistencyContainer.translatesAutoresizingMaskIntoConstraints = false
        consistencyContainer.addSubview(consistencySection)
        consistencySection.pinToSuperview(insets: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        contentStackView.addArrangedSubview(consistencyContainer)
        
        // Initial state for animations
        headerView.alpha = 0
        headerView.transform = CGAffineTransform(translationX: 0, y: 20)
        dashboardCard.alpha = 0
        dashboardCard.transform = CGAffineTransform(translationX: 0, y: 20)
        focusSection.alpha = 0
        focusSection.transform = CGAffineTransform(translationX: 0, y: 20)
        consistencySection.alpha = 0
        consistencySection.transform = CGAffineTransform(translationX: 0, y: 20)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    private func setupObservers() {
        // Observe patient data changes
        patientModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateDashboard()
            }
            .store(in: &cancellables)
    }
    
    private func configureNavigationBar() {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    // MARK: - Data Updates
    private func updateDashboard() {
        dashboardCard.configure(with: patientModel)
        consistencySection.configure(with: patientModel)
    }
    
    // MARK: - Animations
    private func animateEntrance() {
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut) {
            self.headerView.alpha = 1
            self.headerView.transform = .identity
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.2, options: .curveEaseOut) {
            self.dashboardCard.alpha = 1
            self.dashboardCard.transform = .identity
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.4, options: .curveEaseOut) {
            self.focusSection.alpha = 1
            self.focusSection.transform = .identity
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.6, options: .curveEaseOut) {
            self.consistencySection.alpha = 1
            self.consistencySection.transform = .identity
        }
    }
    
    // MARK: - Actions
    private func showProfile() {
        let profileVC = ProfileViewController()
        profileVC.auth = auth
        let navController = UINavigationController(rootViewController: profileVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
}

// MARK: - Custom View Components

class HeaderStackView: UIView {
    
    var profileButtonTapped: (() -> Void)?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Welcome Back"
        label.font = UIFont.systemFont(ofSize: 34, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        label.text = formatter.string(from: Date())
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var profileButton: UIButton = {
        let button = UIButton(type: .custom)
        let config = UIImage.SymbolConfiguration(pointSize: 36, weight: .regular)
        let image = UIImage(systemName: "person.circle.fill", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .secondaryLabel
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(profileTapped), for: .touchUpInside)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(titleLabel)
        addSubview(dateLabel)
        addSubview(profileButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            dateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            dateLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            profileButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            profileButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            profileButton.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 16),
            profileButton.widthAnchor.constraint(equalToConstant: 44),
            profileButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc private func profileTapped() {
        profileButtonTapped?()
    }
}
```

---

## Reusable Components

### GlassEffectView.swift

```swift
import UIKit

class GlassEffectView: UIView {
    
    private let blurView: UIVisualEffectView = {
        let blur = UIBlurEffect(style: .systemMaterial)
        let view = UIVisualEffectView(effect: blur)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGlassEffect()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGlassEffect()
    }
    
    private func setupGlassEffect() {
        backgroundColor = UIColor.systemBackground.withAlphaComponent(0.7)
        layer.cornerRadius = 20
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        layer.masksToBounds = true
        
        // Add shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 8
        
        // Insert blur view
        insertSubview(blurView, at: 0)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
```

### CircularProgressView.swift

```swift
import UIKit

class CircularProgressView: UIView {
    
    // MARK: - Properties
    var progress: Double = 0 {
        didSet {
            progressLayer.strokeEnd = CGFloat(progress)
            updatePercentageLabel()
        }
    }
    
    var color: UIColor = .systemBlue {
        didSet {
            progressLayer.strokeColor = color.cgColor
            percentageLabel.textColor = color
        }
    }
    
    var lineWidth: CGFloat = 5 {
        didSet {
            backgroundLayer.lineWidth = lineWidth
            progressLayer.lineWidth = lineWidth
        }
    }
    
    // MARK: - UI Components
    private let backgroundLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    
    private let percentageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
        setupLabel()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
        setupLabel()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updatePaths()
    }
    
    // MARK: - Setup
    private func setupLayers() {
        // Background layer
        backgroundLayer.strokeColor = UIColor.systemGray5.cgColor
        backgroundLayer.fillColor = UIColor.clear.cgColor
        backgroundLayer.lineWidth = lineWidth
        backgroundLayer.lineCap = .round
        layer.addSublayer(backgroundLayer)
        
        // Progress layer
        progressLayer.strokeColor = color.cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        layer.addSublayer(progressLayer)
    }
    
    private func setupLabel() {
        addSubview(percentageLabel)
        NSLayoutConstraint.activate([
            percentageLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            percentageLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    private func updatePaths() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = (min(bounds.width, bounds.height) - lineWidth) / 2
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + 2 * CGFloat.pi
        
        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )
        
        backgroundLayer.path = path.cgPath
        progressLayer.path = path.cgPath
    }
    
    private func updatePercentageLabel() {
        let percentage = Int(progress * 100)
        percentageLabel.text = "\(percentage)%"
    }
    
    // MARK: - Animation
    func animateProgress(to newProgress: Double, duration: TimeInterval = 0.3) {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = progressLayer.strokeEnd
        animation.toValue = newProgress
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        progressLayer.strokeEnd = CGFloat(newProgress)
        progressLayer.add(animation, forKey: "progressAnimation")
        
        progress = newProgress
    }
}
```

### UIView+Extensions.swift

```swift
import UIKit

extension UIView {
    /// Pins the view to its superview with optional insets
    func pinToSuperview(insets: UIEdgeInsets = .zero) {
        guard let superview = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.topAnchor, constant: insets.top),
            leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: -insets.right),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -insets.bottom)
        ])
    }
    
    /// Adds a subtle shadow to the view
    func addShadow(
        color: UIColor = .black,
        opacity: Float = 0.1,
        offset: CGSize = CGSize(width: 0, height: 4),
        radius: CGFloat = 8
    ) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.masksToBounds = false
    }
    
    /// Rounds specific corners of the view
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}
```

---

## Conclusion

These implementation examples provide a solid foundation for converting the NeuroQuest app from SwiftUI to programmatic UIKit. Each example demonstrates:

1. **Proper view controller lifecycle management**
2. **Programmatic Auto Layout constraints**
3. **Dependency injection patterns**
4. **Combine framework for reactive updates**
5. **Smooth animations and transitions**
6. **Memory management best practices**
7. **Reusable component architecture**

Continue following these patterns as you convert the remaining views in the application.
