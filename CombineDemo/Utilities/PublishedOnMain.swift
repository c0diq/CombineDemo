//
//  PublishedOnMain.swift
//  CombineDemo
//
//  Created by Sylvain Rebaud on 2/29/20.
//  Copyright © 2020 Plutinosoft. All rights reserved.
//

import Combine
import Foundation

// Property Wrapper that adds main thread delivery to @Published
@propertyWrapper
public class PublishedOnMain<Value> {
    @Published var value: Value

    public var wrappedValue: Value {
        get { value }
        set { value = newValue }
    }

    public var projectedValue: AnyPublisher<Value, Never> {
      return $value
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }

    public init(wrappedValue initialValue: Value) {
        value = initialValue
    }
}
