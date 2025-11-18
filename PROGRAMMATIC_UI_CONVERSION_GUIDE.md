# NeuroQuest: SwiftUI to Programmatic UIKit Conversion Guide

## Table of Contents
1. [Overview](#overview)
2. [Architecture Changes](#architecture-changes)
3. [Step-by-Step Conversion Strategy](#step-by-step-conversion-strategy)
4. [Code Patterns & Examples](#code-patterns--examples)
5. [State Management](#state-management)
6. [Navigation & Routing](#navigation--routing)
7. [Best Practices](#best-practices)
8. [Testing Strategy](#testing-strategy)

---

## Overview

This guide provides a comprehensive approach to converting the NeuroQuest iOS application from SwiftUI to programmatic UIKit. The project currently contains 48 Swift files implementing a cognitive wellness app for Parkinson's patients using pure SwiftUI with no Storyboards or XIBs.

### Why Programmatic UIKit?

- **Performance**: Better control over view lifecycle and rendering
- **Compatibility**: Wider iOS version support
- **Industry Standard**: Many production apps still use UIKit
- **Fine-grained Control**: More precise control over animations and transitions
- **Team Familiarity**: Some teams prefer UIKit patterns

### Current Tech Stack
- **Language**: Swift
- **UI Framework**: SwiftUI
- **Additional Frameworks**: PencilKit, WebKit, SpriteKit
- **State Management**: SwiftUI property wrappers (@State, @StateObject, @EnvironmentObject, @Binding)

### Target Tech Stack
- **Language**: Swift
- **UI Framework**: UIKit (Programmatic - no Storyboards/XIBs)
- **Additional Frameworks**: PencilKit, WebKit, SpriteKit (compatible with UIKit)
- **State Management**: Delegates, Closures, NotificationCenter, Combine

---

## Architecture Changes

### 1. App Entry Point

#### Current (SwiftUI)
```swift
@main
struct NeuroQuestApp: App {
    @StateObject private var auth = Authentication()
    @StateObject private var gameDataStore = GameDataStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(gameDataStore)
        }
    }
}
```

#### Target (UIKit)
```swift
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    // Shared services
    let auth = Authentication()
    let gameDataStore = GameDataStore()
    
    func application(_ application: UIApplication, 
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let rootViewController = RootViewController()
        rootViewController.auth = auth
        rootViewController.gameDataStore = gameDataStore
        
        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()
        
        return true
    }
}
```

### 2. View Structure

#### SwiftUI Pattern
- `View` protocol with `body: some View`
- Declarative UI definition
- Automatic layout with stacks
- State-driven UI updates

#### UIKit Pattern
- `UIViewController` subclasses
- Imperative UI setup in `viewDidLoad()` / `loadView()`
- Programmatic Auto Layout with constraints
- Manual UI updates via methods

---

## Step-by-Step Conversion Strategy

### Phase 1: Foundation Setup (Week 1)
1. **Create AppDelegate & SceneDelegate**
   - Replace `@main struct` with `@main class AppDelegate`
   - Set up window and initial view controller
   - Migrate shared services (Authentication, GameDataStore)

2. **Create Base View Controllers**
   - BaseViewController with common functionality
   - BaseTableViewController for list views
   - BaseTabBarController for tab navigation

3. **Set Up Dependency Injection**
   - Create service container or coordinator pattern
   - Pass dependencies through initializers
   - Avoid singletons where possible

### Phase 2: Core Navigation (Week 2)
1. **Convert RootView**
   - Create RootViewController
   - Implement state-based view switching
   - Handle authentication state changes

2. **Convert TabBar Views**
   - PatientContentView → PatientTabBarController
   - AdminContentView → AdminTabBarController
   - Set up tab items with icons

3. **Set Up Navigation Controllers**
   - Wrap each tab in UINavigationController
   - Configure navigation bar appearance
   - Set up navigation titles

### Phase 3: Authentication Flow (Week 3)
1. **Convert Welcome & Auth Views**
   - WelcomeView → WelcomeViewController
   - LoginView → LoginViewController
   - SignUpView → SignUpViewController
   
2. **Implement Form Handling**
   - UITextField delegates
   - Form validation
   - Keyboard handling

3. **Add Onboarding**
   - FeatureCarouselView → OnboardingPageViewController
   - UIPageViewController for carousel
   - Health permissions flow

### Phase 4: Patient Module (Week 4-5)
1. **Home Screen**
   - HomeView → HomeViewController
   - Custom views for dashboard cards
   - UICollectionView for games grid
   - Charts integration (3rd party or custom)

2. **Games Module**
   - ExerciseView → GamesViewController
   - GameDetailView → GameDetailViewController
   - Level selection with UICollectionView
   - SpriteKit integration for game scenes

3. **Health & Profile**
   - PatientHealthView → HealthViewController
   - UITableView for appointments & reminders
   - PatientProfileView → ProfileViewController

### Phase 5: Caregiver Module (Week 6)
1. **Admin Dashboard**
   - AdminHomeView → AdminHomeViewController
   - Patient list with UITableView
   - Data visualization with custom views

2. **Activity Tracking**
   - ActivityView → ActivityViewController
   - Charts and statistics views

3. **Scheduling**
   - AdminHealthView → ScheduleViewController
   - Form inputs for appointments

### Phase 6: Polish & Testing (Week 7-8)
1. **Animations & Transitions**
   - UIView.animate for view animations
   - Custom UIViewControllerAnimatedTransitioning
   - Spring animations and timing curves

2. **Accessibility**
   - VoiceOver support
   - Dynamic Type
   - Accessibility identifiers

3. **Performance Optimization**
   - Lazy loading
   - Memory management
   - Cell reuse optimization

---

## Code Patterns & Examples

### Example 1: Simple View Conversion

#### SwiftUI Version (WelcomeView snippet)
```swift
struct WelcomeView: View {
    @EnvironmentObject var auth: Authentication
    @State private var showAuthSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                RadialGradient(...)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    AppIconView(...)
                    
                    Text("Welcome to NeuroQuest")
                        .font(.system(size: 32, weight: .bold))
                    
                    Button("Get Started") {
                        // Action
                    }
                }
            }
        }
    }
}
```

#### UIKit Version (WelcomeViewController)
```swift
class WelcomeViewController: UIViewController {
    
    // MARK: - Properties
    var auth: Authentication!
    
    // MARK: - UI Components
    private let gradientLayer = CAGradientLayer()
    private let iconView = UIView()
    private let titleLabel = UILabel()
    private let getStartedButton = UIButton(type: .system)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        // Background Gradient
        gradientLayer.colors = [
            UIColor.systemBlue.withAlphaComponent(0.15).cgColor,
            UIColor.systemBackground.cgColor
        ]
        gradientLayer.type = .radial
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        // Title Label
        titleLabel.text = "Welcome to NeuroQuest"
        titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Get Started Button
        getStartedButton.setTitle("Get Started", for: .normal)
        getStartedButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        getStartedButton.backgroundColor = .systemBlue
        getStartedButton.setTitleColor(.white, for: .normal)
        getStartedButton.layer.cornerRadius = 12
        getStartedButton.translatesAutoresizingMaskIntoConstraints = false
        getStartedButton.addTarget(self, action: #selector(getStartedTapped), for: .touchUpInside)
        view.addSubview(getStartedButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Title Label
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            // Get Started Button
            getStartedButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            getStartedButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            getStartedButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            getStartedButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            getStartedButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }
    
    // MARK: - Actions
    @objc private func getStartedTapped() {
        let carouselVC = FeatureCarouselViewController()
        carouselVC.auth = auth
        navigationController?.pushViewController(carouselVC, animated: true)
    }
}
```

### Example 2: List View with Data

#### SwiftUI Version
```swift
struct ExerciseView: View {
    @EnvironmentObject var gameDataStore: GameDataStore
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach($gameDataStore.games) { $game in
                    GameCardView(game: $game)
                }
            }
        }
    }
}
```

#### UIKit Version
```swift
class GamesViewController: UIViewController {
    
    // MARK: - Properties
    var gameDataStore: GameDataStore!
    
    // MARK: - UI Components
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemGroupedBackground
        cv.delegate = self
        cv.dataSource = self
        cv.register(GameCardCell.self, forCellWithReuseIdentifier: "GameCardCell")
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupObservers()
    }
    
    private func setupUI() {
        title = "Games"
        view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupObservers() {
        // Observe game data changes
        gameDataStore.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.collectionView.reloadData()
            }
        }.store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - UICollectionViewDataSource
extension GamesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gameDataStore.games.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GameCardCell", for: indexPath) as! GameCardCell
        let game = gameDataStore.games[indexPath.item]
        cell.configure(with: game)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension GamesViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let game = gameDataStore.games[indexPath.item]
        let detailVC = GameDetailViewController()
        detailVC.game = game
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension GamesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 32 // Account for insets
        return CGSize(width: width, height: 180)
    }
}
```

### Example 3: Custom Reusable Cell

```swift
class GameCardCell: UICollectionViewCell {
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let progressRingView = CircularProgressView()
    private let playButton = UIButton(type: .system)
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Container with glass effect
        containerView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.7)
        containerView.layer.cornerRadius = 35
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // Icon
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconImageView)
        
        // Title
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Progress Ring
        progressRingView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(progressRingView)
        
        // Play Button
        playButton.setTitle("Play", for: .normal)
        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.backgroundColor = .systemBlue
        playButton.setTitleColor(.white, for: .normal)
        playButton.layer.cornerRadius = 20
        playButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(playButton)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            iconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            iconImageView.widthAnchor.constraint(equalToConstant: 55),
            iconImageView.heightAnchor.constraint(equalToConstant: 55),
            
            progressRingView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            progressRingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            progressRingView.widthAnchor.constraint(equalToConstant: 55),
            progressRingView.heightAnchor.constraint(equalToConstant: 55),
            
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: playButton.leadingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),
            
            playButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
            playButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),
            playButton.heightAnchor.constraint(equalToConstant: 40),
            playButton.widthAnchor.constraint(equalToConstant: 90)
        ])
    }
    
    // MARK: - Configuration
    func configure(with game: Game) {
        titleLabel.text = game.card.title
        iconImageView.image = UIImage(systemName: game.card.imageName)
        iconImageView.tintColor = game.card.accentColor
        progressRingView.progress = game.overallProgress ?? 0.0
        progressRingView.color = game.card.accentColor
    }
}
```

---

## State Management

### SwiftUI State Management → UIKit Equivalents

| SwiftUI | UIKit Alternative | Use Case |
|---------|-------------------|----------|
| `@State` | Private properties + `setNeedsLayout()` | Local view state |
| `@StateObject` | Strong property + lifecycle management | Owned model objects |
| `@ObservedObject` | Weak/unowned property + observation | Injected model objects |
| `@EnvironmentObject` | Dependency injection via initializer | Shared services |
| `@Binding` | Delegate pattern / Closures | Two-way communication |
| `@Published` | Same (works with Combine in UIKit) | Observable properties |
| `onChange` | Property observers / KVO / Combine | Reacting to changes |

### Example: Authentication State

#### Current (SwiftUI)
```swift
class Authentication: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isAuthenticating: Bool = false
    @Published var userRole: UserRole = .none
}

struct RootView: View {
    @EnvironmentObject var auth: Authentication
    
    var body: some View {
        Group {
            if auth.isAuthenticated {
                switch auth.userRole {
                case .patient: PatientContentView()
                case .admin: AdminContentView()
                case .none: WelcomeView()
                }
            } else {
                WelcomeView()
            }
        }
    }
}
```

#### Target (UIKit with Combine)
```swift
// Keep Authentication class with @Published (Combine works with UIKit)
class Authentication: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isAuthenticating: Bool = false
    @Published var userRole: UserRole = .none
}

class RootViewController: UIViewController {
    
    var auth: Authentication!
    private var cancellables = Set<AnyCancellable>()
    
    private var currentViewController: UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupObservers()
        updateRootViewController()
    }
    
    private func setupObservers() {
        // Observe authentication state changes
        auth.$isAuthenticated
            .combineLatest(auth.$userRole)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _ in
                self?.updateRootViewController()
            }
            .store(in: &cancellables)
    }
    
    private func updateRootViewController() {
        // Remove current child view controller
        currentViewController?.willMove(toParent: nil)
        currentViewController?.view.removeFromSuperview()
        currentViewController?.removeFromParent()
        
        // Determine and add new view controller
        let newViewController: UIViewController
        
        if auth.isAuthenticated {
            switch auth.userRole {
            case .patient:
                let tabBarVC = PatientTabBarController()
                tabBarVC.auth = auth
                newViewController = tabBarVC
            case .admin:
                let tabBarVC = AdminTabBarController()
                tabBarVC.auth = auth
                newViewController = tabBarVC
            case .none:
                newViewController = WelcomeViewController()
            }
        } else {
            let welcomeVC = WelcomeViewController()
            welcomeVC.auth = auth
            newViewController = UINavigationController(rootViewController: welcomeVC)
        }
        
        // Add new view controller
        addChild(newViewController)
        view.addSubview(newViewController.view)
        newViewController.view.frame = view.bounds
        newViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        newViewController.didMove(toParent: self)
        
        currentViewController = newViewController
        
        // Animate transition
        UIView.transition(with: view, duration: 0.3, options: .transitionCrossDissolve, animations: nil)
    }
}
```

### Alternative: Delegate Pattern (for simpler cases)

```swift
protocol AuthenticationDelegate: AnyObject {
    func authenticationStateDidChange(_ auth: Authentication)
}

class Authentication {
    weak var delegate: AuthenticationDelegate?
    
    var isAuthenticated: Bool = false {
        didSet {
            delegate?.authenticationStateDidChange(self)
        }
    }
}
```

---

## Navigation & Routing

### SwiftUI Navigation → UIKit Navigation

#### 1. NavigationStack → UINavigationController

**SwiftUI:**
```swift
NavigationStack {
    HomeView()
}
```

**UIKit:**
```swift
let homeVC = HomeViewController()
let navController = UINavigationController(rootViewController: homeVC)
```

#### 2. NavigationLink → pushViewController

**SwiftUI:**
```swift
NavigationLink(destination: GameDetailView(game: game)) {
    Text("View Game")
}
```

**UIKit:**
```swift
let detailVC = GameDetailViewController()
detailVC.game = game
navigationController?.pushViewController(detailVC, animated: true)
```

#### 3. TabView → UITabBarController

**SwiftUI:**
```swift
TabView(selection: $selectedTab) {
    Tab("Summary", systemImage: "rectangle.3.offgrid.fill") {
        HomeView()
    }
    Tab("Games", systemImage: "arcade.stick.console") {
        ExerciseView()
    }
}
```

**UIKit:**
```swift
class PatientTabBarController: UITabBarController {
    
    var auth: Authentication!
    var gameDataStore: GameDataStore!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
    }
    
    private func setupTabs() {
        let homeVC = HomeViewController()
        homeVC.auth = auth
        homeVC.tabBarItem = UITabBarItem(
            title: "Summary",
            image: UIImage(systemName: "rectangle.3.offgrid"),
            selectedImage: UIImage(systemName: "rectangle.3.offgrid.fill")
        )
        let homeNav = UINavigationController(rootViewController: homeVC)
        
        let gamesVC = GamesViewController()
        gamesVC.gameDataStore = gameDataStore
        gamesVC.tabBarItem = UITabBarItem(
            title: "Games",
            image: UIImage(systemName: "arcade.stick.console"),
            tag: 1
        )
        let gamesNav = UINavigationController(rootViewController: gamesVC)
        
        viewControllers = [homeNav, gamesNav]
    }
}
```

#### 4. Sheet Presentation → Present Modally

**SwiftUI:**
```swift
.sheet(isPresented: $showProfile) {
    ProfileView()
}
```

**UIKit:**
```swift
@objc private func showProfile() {
    let profileVC = ProfileViewController()
    let navController = UINavigationController(rootViewController: profileVC)
    navController.modalPresentationStyle = .pageSheet
    present(navController, animated: true)
}
```

---

## Best Practices

### 1. View Controller Organization

```swift
class GameDetailViewController: UIViewController {
    
    // MARK: - Properties
    var game: Game!
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupObservers()
        loadData()
    }
    
    // MARK: - Setup
    private func setupUI() {
        // UI setup code
    }
    
    private func setupConstraints() {
        // Constraint setup code
    }
    
    private func setupObservers() {
        // Observation setup
    }
    
    // MARK: - Data
    private func loadData() {
        // Data loading
    }
    
    // MARK: - Actions
    @objc private func buttonTapped() {
        // Action handling
    }
    
    // MARK: - Helpers
    private func updateUI() {
        // UI updates
    }
}
```

### 2. Reusable Components

Create reusable view classes for common UI patterns:

```swift
class GlassEffectView: UIView {
    
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
        
        // Add blur effect
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(blurView, at: 0)
    }
}
```

### 3. Constraint Helpers

```swift
extension UIView {
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
}
```

### 4. Animations

```swift
// Simple fade-in animation
UIView.animate(withDuration: 0.3) {
    self.titleLabel.alpha = 1.0
}

// Spring animation
UIView.animate(
    withDuration: 0.6,
    delay: 0,
    usingSpringWithDamping: 0.7,
    initialSpringVelocity: 0.5,
    options: .curveEaseOut
) {
    self.iconView.transform = .identity
}

// Keyframe animation
UIView.animateKeyframes(withDuration: 1.0, delay: 0) {
    UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
        self.iconView.alpha = 1.0
    }
    UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
        self.titleLabel.alpha = 1.0
    }
}
```

### 5. Memory Management

```swift
class HomeViewController: UIViewController {
    
    // Use weak/unowned for delegates and closures
    weak var coordinator: AppCoordinator?
    
    // Store cancellables for Combine subscriptions
    private var cancellables = Set<AnyCancellable>()
    
    // Clean up in deinit
    deinit {
        cancellables.removeAll()
        NotificationCenter.default.removeObserver(self)
    }
}
```

---

## Testing Strategy

### 1. Unit Tests for View Controllers

```swift
class HomeViewControllerTests: XCTestCase {
    
    var sut: HomeViewController!
    var mockAuth: MockAuthentication!
    
    override func setUp() {
        super.setUp()
        mockAuth = MockAuthentication()
        sut = HomeViewController()
        sut.auth = mockAuth
        sut.loadViewIfNeeded()
    }
    
    override func tearDown() {
        sut = nil
        mockAuth = nil
        super.tearDown()
    }
    
    func testViewLoads() {
        XCTAssertNotNil(sut.view)
    }
    
    func testTitleIsSet() {
        XCTAssertEqual(sut.title, "Home")
    }
}
```

### 2. UI Tests

```swift
class NeuroQuestUITests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launch()
    }
    
    func testLoginFlow() {
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("test@example.com")
        
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("password123")
        
        app.buttons["Log In"].tap()
        
        // Verify navigation to home screen
        XCTAssertTrue(app.tabBars.buttons["Summary"].exists)
    }
}
```

---

## Additional Considerations

### 1. Maintaining SwiftUI Components

Some components can remain in SwiftUI and be wrapped:

```swift
import SwiftUI

class SpriteKitGameViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Use UIHostingController to embed SwiftUI view if needed
        let swiftUIView = SomeComplexSwiftUIView()
        let hostingController = UIHostingController(rootView: swiftUIView)
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.frame = view.bounds
        hostingController.didMove(toParent: self)
    }
}
```

### 2. Charts Library

For data visualization, consider:
- **Core Graphics**: Custom drawing for full control
- **Charts (Swift Package)**: Can work with UIKit via UIHostingController
- **Third-party**: DGCharts, Charts framework

### 3. PencilKit Integration

PencilKit works seamlessly with UIKit:

```swift
import PencilKit

class DrawingViewController: UIViewController {
    
    private let canvasView = PKCanvasView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        canvasView.frame = view.bounds
        canvasView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        canvasView.backgroundColor = .white
        view.addSubview(canvasView)
        
        // Enable drawing
        canvasView.drawingPolicy = .anyInput
    }
}
```

### 4. SpriteKit Integration

SpriteKit works with both UIKit and SwiftUI:

```swift
import SpriteKit

class GameSceneViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let skView = SKView(frame: view.bounds)
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(skView)
        
        let scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)
    }
}
```

---

## Migration Checklist

### Pre-Migration
- [ ] Set up version control branch
- [ ] Document current app behavior
- [ ] Create UI/UX screenshots for reference
- [ ] Back up current codebase

### Phase 1: Foundation
- [ ] Create AppDelegate and SceneDelegate
- [ ] Set up base view controllers
- [ ] Implement dependency injection pattern
- [ ] Create reusable UI components

### Phase 2: Authentication
- [ ] Convert welcome screen
- [ ] Convert login/signup forms
- [ ] Implement form validation
- [ ] Test authentication flow

### Phase 3: Main Navigation
- [ ] Convert tab bar structure
- [ ] Set up navigation controllers
- [ ] Implement navigation transitions
- [ ] Test navigation flow

### Phase 4: Patient Features
- [ ] Convert home dashboard
- [ ] Convert games module
- [ ] Convert health/wellness views
- [ ] Convert profile screen
- [ ] Test patient workflow

### Phase 5: Caregiver Features
- [ ] Convert admin dashboard
- [ ] Convert activity tracking
- [ ] Convert scheduling
- [ ] Test caregiver workflow

### Phase 6: Polish
- [ ] Implement animations
- [ ] Add accessibility features
- [ ] Optimize performance
- [ ] Add unit tests
- [ ] Add UI tests

### Phase 7: QA
- [ ] Full regression testing
- [ ] Performance testing
- [ ] Accessibility audit
- [ ] User acceptance testing

---

## Conclusion

Converting from SwiftUI to programmatic UIKit is a significant undertaking that requires careful planning and execution. This guide provides a foundation, but each team should adapt these patterns to their specific needs and coding standards.

### Key Takeaways:

1. **Plan Incrementally**: Convert one module at a time
2. **Maintain Functionality**: Don't add new features during conversion
3. **Test Thoroughly**: Write tests before and after conversion
4. **Use Modern UIKit**: Leverage UIKit improvements like diffable data sources
5. **Keep Combine**: Continue using Combine for reactive patterns
6. **Document Changes**: Keep this guide updated with project-specific patterns

### Resources:

- [Apple UIKit Documentation](https://developer.apple.com/documentation/uikit)
- [Apple Auto Layout Guide](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/AutolayoutPG/)
- [UIViewController Lifecycle](https://developer.apple.com/documentation/uikit/uiviewcontroller)
- [Combine Framework](https://developer.apple.com/documentation/combine)

---

**Last Updated**: 2025-11-18  
**Version**: 1.0  
**Author**: NeuroQuest Development Team
