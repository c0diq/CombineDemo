//
//  Single.swift
//  CombineDemo
//
//  Created by Sylvain Rebaud on 2/29/20.
//  Copyright © 2020 Plutinosoft. All rights reserved.
//

import Foundation
import Combine

@propertyWrapper
public class Single<Value> {
    @Published var value: Value

    public var wrappedValue: Value {
        get { value }
        set { value = newValue }
    }

    public var projectedValue: AnyPublisher<Value, Never> {
        return $value
            .prefix(1)
            .eraseToAnyPublisher()
    }
    
    public init(wrappedValue initialValue: Value) {
        value = initialValue
    }
}
