import Combine
import SwiftUI


// MARK: - Protocol

protocol InnerViewAction {}


// MARK: - Action Wrapper

@propertyWrapper public struct Action<T> {
  
  private let currentValue: CurrentValueSubject<T, Never>
  
  init(_ receivedValue: T) {
    
    self.currentValue = CurrentValueSubject(receivedValue)
    
    _ = eventSubject
    
      .flatMap { receivedEvent -> AnyPublisher<InnerViewAction, Never> in
        return EventEnum.actionsByEvent(receivedEvent).publisher.eraseToAnyPublisher()
      }
    
      .compactMap { receivedAction in
        return receivedAction as? T
      }
    
      .subscribe(on: DispatchQueue.main)
    
      .assign(to: \.wrappedValue, on: self)
  }
  
  public var wrappedValue: T {
    get { currentValue.value }
    
    nonmutating set {
      currentValue.value = newValue
    }
  }
  
  public var projectedValue: AnyPublisher<T, Never> {
    get {
      currentValue
        .compactMap({ $0 })
        .eraseToAnyPublisher()
    }
  }
}


// MARK: - Event

enum EventEnum: Equatable {
  case initial
  case changeBothSidesColors
  
  static func actionsByEvent(_ event: Self) -> [any InnerViewAction] {
    switch event {
    case .initial:
      return []
    case .changeBothSidesColors:
      return [LeftScreen.InnerAction.changeLeftColor, RightScreen.InnerAction.changeRightColor]
    }
  }
}


// MARK: - Subject

let eventSubject: CurrentValueSubject<EventEnum, Never> = .init(.initial)


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
    .onReceive($action.dropFirst()) { newAction in
      switch newAction {
        
      case .initial:
        break
        
      case .changeLeftColor:
        color = randomColor()
      }
    }
  }
  
  enum InnerAction: InnerViewAction {
    case initial
    case changeLeftColor
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
    .onReceive($action.dropFirst()) { newAction in
      switch newAction {
        
      case .initial:
        break
        
      case .changeRightColor:
        color = randomColor()
      }
    }
  }
  
  enum InnerAction: InnerViewAction {
    case initial
    case changeRightColor
  }
}


// MARK: - Random Color func

func randomColor() -> Color {
  let red   = CGFloat.random(in: 0...1)
  let green = CGFloat.random(in: 0...1)
  let blue  = CGFloat.random(in: 0...1)
  return Color(uiColor: UIColor(red: red, green: green, blue: blue, alpha: 1.0))
}
