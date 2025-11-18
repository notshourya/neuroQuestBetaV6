# SwiftUI to UIKit Quick Reference Guide

A fast lookup table for converting common SwiftUI patterns to programmatic UIKit equivalents.

## View Structure

| SwiftUI | UIKit |
|---------|-------|
| `struct MyView: View` | `class MyViewController: UIViewController` |
| `var body: some View { }` | `override func viewDidLoad()` + `setupUI()` |
| `@State private var name = ""` | `private var name = ""` + manual updates |
| `@Binding var value: Int` | Property + delegate/closure pattern |
| `@StateObject private var model` | `private let model = Model()` |
| `@ObservedObject var model` | `var model: Model!` + Combine |
| `@EnvironmentObject var service` | Dependency injection via init/property |

## Layout

| SwiftUI | UIKit |
|---------|-------|
| `VStack { }` | `UIStackView(axis: .vertical)` |
| `HStack { }` | `UIStackView(axis: .horizontal)` |
| `ZStack { }` | Multiple `addSubview()` calls |
| `Spacer()` | Flexible constraints or spacing |
| `padding()` | `NSLayoutConstraint` with constants |
| `frame(width:height:)` | `widthAnchor/heightAnchor.constraint()` |

## Navigation

| SwiftUI | UIKit |
|---------|-------|
| `NavigationStack { }` | `UINavigationController` |
| `NavigationLink(destination:)` | `navigationController?.pushViewController()` |
| `.navigationTitle("Title")` | `title = "Title"` |
| `.navigationBarHidden(true)` | `navigationController?.setNavigationBarHidden(true)` |
| `TabView { }` | `UITabBarController` |
| `Tab("Title", systemImage:)` | `UITabBarItem(title:image:)` |

## Presentation

| SwiftUI | UIKit |
|---------|-------|
| `.sheet(isPresented:)` | `present(_:animated:)` with `.pageSheet` |
| `.fullScreenCover()` | `present(_:animated:)` with `.fullScreen` |
| `.popover()` | `present(_:animated:)` with `.popover` |
| `.alert()` | `UIAlertController.Style.alert` |
| `.confirmationDialog()` | `UIAlertController.Style.actionSheet` |

## UI Components

| SwiftUI | UIKit |
|---------|-------|
| `Text("Hello")` | `UILabel()` with `text` |
| `Button("Tap") { }` | `UIButton()` with `addTarget()` |
| `Image(systemName:)` | `UIImage(systemName:)` in `UIImageView` |
| `TextField("", text:)` | `UITextField()` with delegate |
| `SecureField("", text:)` | `UITextField(isSecureTextEntry: true)` |
| `Toggle("", isOn:)` | `UISwitch()` |
| `Slider(value:)` | `UISlider()` |
| `Picker("", selection:)` | `UIPickerView` or `UISegmentedControl` |
| `List { }` | `UITableView` |
| `ScrollView { }` | `UIScrollView` |
| `LazyVGrid` / `LazyHGrid` | `UICollectionView` |

## Modifiers

| SwiftUI | UIKit |
|---------|-------|
| `.font(.title)` | `label.font = UIFont.systemFont(ofSize:weight:)` |
| `.foregroundColor(.blue)` | `label.textColor = .systemBlue` |
| `.background(.blue)` | `view.backgroundColor = .systemBlue` |
| `.cornerRadius(10)` | `view.layer.cornerRadius = 10` |
| `.shadow()` | `layer.shadowColor`, `shadowOpacity`, etc. |
| `.opacity(0.5)` | `view.alpha = 0.5` |
| `.padding()` | Constraint constants |
| `.frame()` | Width/height constraints |
| `.offset(x:y:)` | Transform or constraints |
| `.scaleEffect()` | `view.transform = CGAffineTransform(scaleX:y:)` |
| `.rotationEffect()` | `view.transform = CGAffineTransform(rotationAngle:)` |

## Animations

| SwiftUI | UIKit |
|---------|-------|
| `withAnimation { }` | `UIView.animate(withDuration:) { }` |
| `.animation(.spring)` | `UIView.animate(usingSpringWithDamping:)` |
| `.transition(.slide)` | Custom `UIViewControllerTransitioningDelegate` |
| `.matchedGeometryEffect()` | Hero animations with frame matching |

## Lists & Collections

| SwiftUI | UIKit |
|---------|-------|
| `List { ForEach() }` | `UITableView` with `UITableViewDataSource` |
| `Section(header:) { }` | `numberOfSections`, `titleForHeaderInSection` |
| `.listStyle(.plain)` | `tableView.style = .plain` |
| `.swipeActions()` | `UISwipeActionsConfiguration` |
| `LazyVGrid(columns:)` | `UICollectionView` with flow layout |

## State Observation

| SwiftUI | UIKit |
|---------|-------|
| `@Published var value` | Same (use with Combine) |
| `.onChange(of:)` | Property observers (`didSet`) or Combine |
| `.onAppear()` | `viewDidAppear()` |
| `.onDisappear()` | `viewDidDisappear()` |
| `.task { }` | `viewDidLoad()` + async task |

## Common Patterns

### Creating a View

**SwiftUI:**
```swift
struct MyView: View {
    var body: some View {
        Text("Hello")
    }
}
```

**UIKit:**
```swift
class MyViewController: UIViewController {
    private let label = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        label.text = "Hello"
        view.addSubview(label)
        // Add constraints...
    }
}
```

### Button with Action

**SwiftUI:**
```swift
Button("Tap Me") {
    print("Tapped")
}
```

**UIKit:**
```swift
let button = UIButton()
button.setTitle("Tap Me", for: .normal)
button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

@objc func buttonTapped() {
    print("Tapped")
}
```

### List/Table

**SwiftUI:**
```swift
List(items) { item in
    Text(item.name)
}
```

**UIKit:**
```swift
// In class:
let tableView = UITableView()

// In viewDidLoad:
tableView.dataSource = self
tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

// DataSource methods:
func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
}

func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
    cell.textLabel?.text = items[indexPath.row].name
    return cell
}
```

### Navigation

**SwiftUI:**
```swift
NavigationLink("Details", destination: DetailView())
```

**UIKit:**
```swift
let detailVC = DetailViewController()
navigationController?.pushViewController(detailVC, animated: true)
```

### Modal Presentation

**SwiftUI:**
```swift
.sheet(isPresented: $showModal) {
    ModalView()
}
```

**UIKit:**
```swift
let modalVC = ModalViewController()
modalVC.modalPresentationStyle = .pageSheet
present(modalVC, animated: true)
```

### Stack Views

**SwiftUI:**
```swift
VStack(spacing: 16) {
    Text("Title")
    Text("Subtitle")
}
```

**UIKit:**
```swift
let stackView = UIStackView()
stackView.axis = .vertical
stackView.spacing = 16

let titleLabel = UILabel()
titleLabel.text = "Title"

let subtitleLabel = UILabel()
subtitleLabel.text = "Subtitle"

stackView.addArrangedSubview(titleLabel)
stackView.addArrangedSubview(subtitleLabel)
```

## Auto Layout Quick Patterns

### Pin to Superview
```swift
view.translatesAutoresizingMaskIntoConstraints = false
NSLayoutConstraint.activate([
    view.topAnchor.constraint(equalTo: superview.topAnchor),
    view.leadingAnchor.constraint(equalTo: superview.leadingAnchor),
    view.trailingAnchor.constraint(equalTo: superview.trailingAnchor),
    view.bottomAnchor.constraint(equalTo: superview.bottomAnchor)
])
```

### Center in Superview
```swift
NSLayoutConstraint.activate([
    view.centerXAnchor.constraint(equalTo: superview.centerXAnchor),
    view.centerYAnchor.constraint(equalTo: superview.centerYAnchor)
])
```

### Fixed Size
```swift
NSLayoutConstraint.activate([
    view.widthAnchor.constraint(equalToConstant: 100),
    view.heightAnchor.constraint(equalToConstant: 50)
])
```

### Safe Area
```swift
NSLayoutConstraint.activate([
    view.topAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.topAnchor),
    view.bottomAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.bottomAnchor)
])
```

## Combine Patterns

### Observing Published Properties

**SwiftUI (automatic):**
```swift
@ObservedObject var viewModel: ViewModel
```

**UIKit (manual with Combine):**
```swift
var viewModel: ViewModel!
private var cancellables = Set<AnyCancellable>()

viewModel.$property
    .receive(on: DispatchQueue.main)
    .sink { [weak self] value in
        self?.updateUI(with: value)
    }
    .store(in: &cancellables)
```

## Common View Controller Template

```swift
import UIKit
import Combine

class MyViewController: UIViewController {
    
    // MARK: - Properties
    var dependency: SomeType!
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Components
    private let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupObservers()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(label)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Constraints here
        ])
    }
    
    private func setupObservers() {
        // Combine subscriptions
    }
    
    // MARK: - Actions
    @objc private func buttonTapped() {
        // Handle action
    }
    
    // MARK: - Cleanup
    deinit {
        cancellables.removeAll()
    }
}
```

## Tips & Gotchas

1. **Always set** `translatesAutoresizingMaskIntoConstraints = false` when using Auto Layout
2. **Use lazy var** for views that need `self` in their configuration
3. **Store Combine subscriptions** in `cancellables` to prevent memory leaks
4. **Use weak self** in closures to avoid retain cycles
5. **Call** `view.setNeedsLayout()` / `view.layoutIfNeeded()` to force layout updates
6. **Remember** to remove observers in `deinit` if not using Combine
7. **Enable** `clipsToBounds` or `masksToBounds` when using `cornerRadius`
8. **Use** `UIView.animate` for simple animations, CAAnimation for complex ones
9. **Set** `.isUserInteractionEnabled = false` on container views if needed
10. **Test** on multiple device sizes and orientations

## Animation Conversion

**SwiftUI:**
```swift
withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
    scale = 1.0
}
```

**UIKit:**
```swift
UIView.animate(
    withDuration: 0.6,
    delay: 0,
    usingSpringWithDamping: 0.7,
    initialSpringVelocity: 0.5,
    options: .curveEaseOut
) {
    self.view.transform = .identity
}
```

## Gradients

**SwiftUI:**
```swift
LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
```

**UIKit:**
```swift
let gradientLayer = CAGradientLayer()
gradientLayer.colors = [UIColor.blue.cgColor, UIColor.purple.cgColor]
gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
gradientLayer.frame = view.bounds
view.layer.insertSublayer(gradientLayer, at: 0)
```

## Blur Effects

**SwiftUI:**
```swift
.background(.ultraThinMaterial)
```

**UIKit:**
```swift
let blurEffect = UIBlurEffect(style: .systemMaterial)
let blurView = UIVisualEffectView(effect: blurEffect)
blurView.frame = view.bounds
view.addSubview(blurView)
```

---

**Quick Tip**: Keep this guide handy while converting views. Most SwiftUI patterns have direct UIKit equivalents with just slightly more verbose syntax.
