//
//  CellViewModel.swift
//  CombineDemo
//
//  Created by Sylvain Rebaud on 3/1/20.
//  Copyright © 2020 Plutinosoft. All rights reserved.
//

import Combine
import Foundation
import UIKit

class CellViewModel: Identifiable {
    var id: String
    var url: URL

    private let imageLoader: ImageLoading

    init?(id: String, url: URL?, imageLoader: ImageLoading) {
        guard let url = url else { return nil }

        self.id = id
        self.url = url
        self.imageLoader = imageLoader
    }

    convenience init?(model: APISearchResultModel, imageLoader: ImageLoading) {
        guard let url = model.images["fixed_height"]?.url else { return nil }

        self.init(id: model.id, url: url, imageLoader: imageLoader)
    }

    func fetchImage() -> AnyPublisher<UIImage?, Never> {
        return imageLoader.fetch(at: url)
            .eraseToAnyPublisher()
    }
}

extension CellViewModel: Hashable {
    static func == (lhs: CellViewModel, rhs: CellViewModel) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
