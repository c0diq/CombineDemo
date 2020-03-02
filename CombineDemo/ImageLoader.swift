//
//  ImageLoader.swift
//  RxDemo
//
//  Created by Sylvain Rebaud on 12/4/18.
//  Copyright © 2018 Plutinosoft. All rights reserved.
//

import Combine
import SwiftGif
import UIKit

protocol ImageLoading {
    func fetch(at url: URL) -> AnyPublisher<UIImage?, Never>
}

class ImageLoader: ImageLoading {
    private var cache = NSCache<NSString, UIImage>()
    private let backgroundQueue = DispatchQueue(label: "Image", qos: .background)

    func fetch(at url: URL) -> AnyPublisher<UIImage?, Never> {
        return Just(url)
            .receive(on: backgroundQueue)
            .flatMap { [weak self] url -> AnyPublisher<UIImage?, Never> in
                if let image = self?.cache.object(forKey: url.absoluteString as NSString){
                    return Just(image).eraseToAnyPublisher()
                }

                return URLSession.shared.dataTaskPublisher(for: url)
                    .map { $0.data }
                    .map { (data: $0, image: UIImage.gif(data: $0)) }
                    .handleEvents(receiveOutput: { [weak self] data, image in
                        if image != nil {
                            self?.cache.setObject(image!, forKey: url.absoluteString as NSString, cost: data.count)
                        }
                    })
                    .map { $0.image }
                    .replaceError(with: nil)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    init(maxBytesSize: Int) {
        cache.totalCostLimit = maxBytesSize
    }
}
