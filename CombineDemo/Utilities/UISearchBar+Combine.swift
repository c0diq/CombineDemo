//
//  UISearchBar+Combine.swift
//  CombineDemo
//
//  Created by Sylvain Rebaud on 2/28/20.
//  Copyright © 2020 Plutinosoft. All rights reserved.
//

import Combine
import CombineCocoa
import DelegateProxy
import UIKit

final class UISearchBarDelegateProxy: DelegateProxy, UISearchBarDelegate, DelegateProxyType {
    func resetDelegateProxy(owner: UISearchBar) {
        owner.delegate = self
    }
}

// Extension that adds Publishers to UISearchBar
public extension UISearchBar {
    internal var delegateProxy: UISearchBarDelegateProxy {
        return .proxy(for: self)
    }

    /// A publisher emitting any text changes to a this search field.
    var textPublisher: AnyPublisher<String?, Never> {
        let textDidChange = delegateProxy.methodInvoked(selector: #selector(UISearchBarDelegate.searchBar(_:textDidChange:)))
        let textEndEditing = delegateProxy.methodInvoked(selector:#selector( UISearchBarDelegate.searchBarTextDidEndEditing(_:)))

        return textDidChange.merge(with: textEndEditing)
            .map { [weak self] _ in self?.text}
            .prepend(self.text)
            .eraseToAnyPublisher()
    }

    /// A publisher emitting void when search button is tapped.
    var searchButtonClickedPublisher: AnyPublisher<Void, Never> {
        delegateProxy.methodInvoked(selector: #selector(UISearchBarDelegate.searchBarSearchButtonClicked(_:)))
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    /// A publisher emitting void when cancel button is tapped.
    var cancelButtonClickedPublisher: AnyPublisher<Void, Never> {
        delegateProxy.methodInvoked(selector: #selector(UISearchBarDelegate.searchBarCancelButtonClicked(_:)))
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}

