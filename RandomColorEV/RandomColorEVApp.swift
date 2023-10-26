import Combine
import SwiftUI


// MARK: - Subject

let eventSubject: PassthroughSubject<EventEnum, Never> = .init()


// MARK: - Protocol

protocol ViewAction: Equatable, CaseIterable {
  static var `default`: Self { get }
}


// MARK: - Action Wrapper

@propertyWrapper struct Action<T: ViewAction> {
  
  private let currentValue: CurrentValueSubject<T, Never>
  
  init(_ receivedValue: T) {
    
    self.currentValue = CurrentValueSubject(receivedValue)
    
    _ = eventSubject
    
      .map { receivedEvent in
        (receivedEvent, T.allCases)
      }
    
      .filter { receivedEvent, allCases in
        allCases.contains {
          receivedCase in String(reflecting: receivedCase).contains(receivedEvent.rawValue)
        }
      }
    
      .flatMap { _, filteredCases -> AnyPublisher<T, Never> in
        filteredCases.publisher.eraseToAnyPublisher()
      }
    
      .subscribe(on: DispatchQueue.main)
    
      .assign(to: \.wrappedValue, on: self)
  }
  
  public var wrappedValue: T {
    get { currentValue.value }
    
    nonmutating set {
      currentValue.value = newValue
      currentValue.value = T.default
    }
  }
  
  public var projectedValue: AnyPublisher<T, Never> {
    get {
      currentValue
        .compactMap({ $0 })
        .drop { $0 == T.default }
        .eraseToAnyPublisher()
    }
  }
}


// MARK: - Event

enum EventEnum: String, Equatable {
  
  case initial
  case changeBothSidesColors
}


// MARK: - Main

@main struct RandomColorEVApp: App {
  
  enum TabItem: Equatable {
    case left, center, right
  }
  
  @State var selectedTab: TabItem = .center
  
  var body: some Scene {
    WindowGroup {
      
      TabView(selection: $selectedTab) {
        LeftScreen()
          .tag(TabItem.left)
        
        CenterScreen()
          .tag(TabItem.center)
        
        RightScreen()
          .tag(TabItem.right)
      }
      
      .ignoresSafeArea()
      
      .tabViewStyle(PageTabViewStyle())
    }
  }
}


// MARK: - Left Screen

struct LeftScreen: View {
  
  @Action(InnerAction.initial) var action
  
  @State var color: Color? = nil
  
  var body: some View {
    
    ZStack {
      color ?? .white
      Text("Left").font(.largeTitle).foregroundColor(color != nil ? .white : .black)
    }
    
    .ignoresSafeArea()
    
    .onReceive($action) { newAction in
      switch newAction {
        
      case .initial:
        break
        
      case .changeLeftColor_changeBothSidesColors:
        color = randomColor()
      }
    }
  }
  
  enum InnerAction: String, ViewAction, CaseIterable {
    static var `default`: LeftScreen.InnerAction { .initial }
    
    case initial
    case changeLeftColor_changeBothSidesColors
  }
}


// MARK: - Center Screen

struct CenterScreen: View {
  
  var body: some View {
    
    ZStack {
      
      Color.teal
      
      VStack {
        Text("Center").font(.largeTitle).foregroundColor(.white).padding()
        
        Button {
          eventSubject.send(.changeBothSidesColors)
        } label: {
          Text("Change colors")
            .foregroundColor(.white)
            .font(.title)
        }
        .buttonStyle(BorderedButtonStyle())
        
      }
    }
    .ignoresSafeArea()
    
  }
}


// MARK: - Right Screen

struct RightScreen: View {
  
  @Action(InnerAction.initial) var action
  
  @State var color: Color? = nil
  
  var body: some View {
    
    ZStack {
      color ?? .white
      Text("Right").font(.largeTitle).foregroundColor(color != nil ? .white : .black)
    }
    
    .ignoresSafeArea()
    
    .onReceive($action) { newAction in
      switch newAction {
        
      case .initial:
        break
        
      case .changeRightColor_changeBothSidesColors:
        color = randomColor()
      }
    }
  }
  
  enum ChangeBothSidesColors: String, ViewAction, CaseIterable {
    static var `default`: RightScreen.ChangeBothSidesColors { .initial }
    
    case initial
  }
  
  enum InnerAction: ViewAction {
    static var `default`: RightScreen.InnerAction { .initial }
    
    case initial
    case changeRightColor_changeBothSidesColors
  }
}


// MARK: - Random Color func

func randomColor() -> Color {
  let red   = CGFloat.random(in: 0...1)
  let green = CGFloat.random(in: 0...1)
  let blue  = CGFloat.random(in: 0...1)
  return Color(uiColor: UIColor(red: red, green: green, blue: blue, alpha: 1.0))
}
