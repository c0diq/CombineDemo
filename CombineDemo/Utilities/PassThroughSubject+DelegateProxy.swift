//
//  PassThroughSubject+DelegateProxy.swift
//  CombineDemo
//
//  Created by Sylvain Rebaud on 2/29/20.
//  Copyright © 2020 Plutinosoft. All rights reserved.
//

import Foundation
import Combine
import DelegateProxy

extension PassthroughSubject: Receivable where Output == Arguments, Failure == Never {
    public func send(arguments: Arguments) {
        send(arguments)
    }
}

extension DelegateProxy {
    func methodInvoked(selector: Selector) -> AnyPublisher<Arguments, Never> {
        return PassthroughSubject().subscribe(to: self, selector: selector).eraseToAnyPublisher()
    }
}
