//
//  Publisher+orEmpty.swift
//  CombineDemo
//
//  Created by Sylvain Rebaud on 3/1/20.
//  Copyright © 2020 Plutinosoft. All rights reserved.
//

import Foundation
import Combine

extension Publisher where Output == Optional<String> {
    // Transforms an nil value into an empty string.
    public func orEmpty() -> Publishers.Map<Self, String>  {
        return self.map { $0 ?? "" }
    }
}
