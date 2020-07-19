//
//  SearchViewModel.swift
//  RxDemo
//
//  Created by Sylvain Rebaud on 11/30/18.
//  Copyright © 2018 Plutinosoft. All rights reserved.
//

import Combine
import UIKit
import SwiftGif

struct APISearchResultModel: Decodable {
    struct APISearchResultImage: Decodable {
        let url: URL?
    }

    let id: String
    let type: String
    let url: URL
    let title: String

    let images: [String: APISearchResultImage]
}

struct APISearchResultsModel: Decodable {
    let data: [APISearchResultModel]
}

enum APIError: Error, LocalizedError {
    case unknown
    case apiError(reason: String)
    case parserError(underlyingError: Error)
    case networkError(from: URLError)

    var errorDescription: String? {
        switch self {
        case .unknown:
            return "Unknown error"
        case .apiError(let reason):
            return reason
        case .parserError(let underlyingError):
            return underlyingError.localizedDescription
        case .networkError(let from):
            return from.localizedDescription
        }
    }
}

class SearchViewModel {
    // inputs
    var query: String = "" {
        didSet {
            querySubject.send(query)
        }
    }

    // outputs
    @PublishedOnMain var results = [APISearchResultModel]()

    // private
    private let querySubject = PassthroughSubject<String, Never>()
    private let backgroundQueue = DispatchQueue(label: "API", qos: .background)
    private var cancellable: AnyCancellable?

    init() {
        cancellable = self.fetchResults()
            .assign(to: \.results, on: self)
    }

    private func fetchResults() -> AnyPublisher<[APISearchResultModel], Never> {
        return querySubject
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .map { [backgroundQueue] query -> AnyPublisher<[APISearchResultModel], Never> in
                guard query.count > 1 else { return Just([]).eraseToAnyPublisher() }
                
                let url = URL(string: "https://api.giphy.com/v1/gifs/search?api_key=3BOEDnc7pIsEvmr8iqiFhf5ZuQkR8h6N&q=\(query)")!
                let request = URLRequest(url: url)

                return URLSession.DataTaskPublisher(request: request, session: .shared)
                    // perform API call and parsing on background thread
                    .subscribe(on: backgroundQueue)
                    .tryMap { data, response in
                        guard let httpResponse = response as? HTTPURLResponse else {
                            throw APIError.unknown
                        }
                        if (httpResponse.statusCode == 401) {
                            throw APIError.apiError(reason: "Unauthorized");
                        }
                        if (httpResponse.statusCode == 403) {
                            throw APIError.apiError(reason: "Resource forbidden");
                        }
                        if (httpResponse.statusCode == 404) {
                            throw APIError.apiError(reason: "Resource not found");
                        }
                        if (405..<500 ~= httpResponse.statusCode) {
                            throw APIError.apiError(reason: "client error");
                        }
                        if (500..<600 ~= httpResponse.statusCode) {
                            throw APIError.apiError(reason: "server error");
                        }
                        return data
                    }
                    .mapError { error -> Error in
                       // if it's our kind of error already, we can return it directly
                       if let error = error as? APIError {
                           return error
                       }
                       // if it is a URLError, we can convert it into our more general error kind
                       if let urlerror = error as? URLError {
                           return APIError.networkError(from: urlerror)
                       }
                       // if all else fails, return the unknown error condition
                       return APIError.unknown
                    }
                    .decode(type: APISearchResultsModel.self, decoder: JSONDecoder())
                    .mapError { error -> Error in
                        // remap decodable error
                        APIError.parserError(underlyingError: error)
                    }
                    .map { $0.data }
                    .replaceError(with: [])
                    // clear previously returned results first
                    .prepend([])
                    .eraseToAnyPublisher()
            }
            // cancel any in flight API call
            .switchToLatest()
            // switch back to main thread
            .eraseToAnyPublisher()
    }
}
