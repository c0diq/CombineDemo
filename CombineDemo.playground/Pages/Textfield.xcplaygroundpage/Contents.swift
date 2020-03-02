//: A UIKit based Playground for presenting user interface

import UIKit
import Combine
import CombineCocoa
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

class MyViewController : UIViewController {
    var label : UILabel!
    var textField : UITextField!
    private var subscriptions = Set<AnyCancellable>()

    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white

        textField = UITextField()
        textField.borderStyle = .roundedRect
        textField.autocorrectionType = .no
        view.addSubview(textField)

        label = UILabel()
        label.numberOfLines = 0
        label.textColor = .black

        view.addSubview(label)
        self.view = view

        // Layout
        textField.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        let margins = view.layoutMarginsGuide
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: margins.topAnchor, constant: 20),
            textField.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: margins.trailingAnchor),

            label.leadingAnchor.constraint(equalTo: textField.leadingAnchor),
            label.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 10),
        ])
    }

    override func viewDidLoad() {
        let text = textField.textPublisher
            .map { $0 ?? "" }

//        textField.textPublisher
//            .map { $0 ?? "" }
//            .map { $0.count }
//            .filter { $0 > 3 }
//            .sink {
//                print("\($0)")
//            }
//            .store(in: &subscriptions)

//        textField.textPublisher
//            .map { $0 ?? "" }
//            .map { $0.count }
//            .filter { $0 > 3 }
//            .debounce(for: .seconds(.5), scheduler: DispatchQueue.main)
//            .removeDuplicates()
//            .sink {
//                print("\($0)")
//            }
//            .store(in: &subscriptions)

        text
            .scan([]) { (accumulator, newText) in
                return [newText] + accumulator
            }
            .map { $0.prefix(10) }
            .map { $0.joined(separator: "\n") }
            .assign(to: \.text, on: label)
            .store(in: &subscriptions)
    }
}
let window = UIWindow(frame: CGRect(x: 0,
                                    y: 0,
                                    width: 768,
                                    height: 1024))
let viewController = MyViewController()
window.rootViewController = viewController
window.makeKeyAndVisible()
PlaygroundPage.current.liveView = window
