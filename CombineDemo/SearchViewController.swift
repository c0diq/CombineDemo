//
//  SearchViewController.swift
//  RxDemo
//
//  Created by Sylvain Rebaud on 11/23/18.
//  Copyright © 2018 Plutinosoft. All rights reserved.
//

import UIKit
import SwiftGif
import Combine
import CombineCocoa
import CombineDataSources
import CombinePrintout

class SearchViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!

    private let searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = "Search"
        searchController.searchBar.autocorrectionType = .no
        searchController.searchBar.autocapitalizationType = .none
        searchController.obscuresBackgroundDuringPresentation = false
        return searchController
    }()

    private var subscriptions = Set<AnyCancellable>()
    private var viewModel = SearchViewModel()
    private let imageLoader = ImageLoader(maxBytesSize: 2000*1024)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupProperties()
        setupCombine()
    }

    private func setupProperties() {
        collectionView.dataSource = nil
        collectionView.delegate = nil

        let flowLayout = UICollectionViewFlowLayout()
        let numColumns = 1
        let size = (collectionView.frame.size.width - CGFloat(10)) / CGFloat(numColumns)
        flowLayout.itemSize = CGSize(width: size, height: size)
        collectionView.setCollectionViewLayout(flowLayout, animated: false)

        navigationItem.searchController = searchController
        navigationItem.title = "Giphy"
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationController?.navigationBar.prefersLargeTitles = false
        definesPresentationContext = true
    }

    private func setupCombine() {
        // forward search entry to viewmodel
        searchController.searchBar.textPublisher
            .orEmpty()
            .assign(to: \.query, on: viewModel)
            .store(in: &subscriptions)

        // make search controller inactive when search button is tapped
        searchController.searchBar.searchButtonClickedPublisher
            .handleEvents(receiveOutput: { [searchController] _ in
                searchController.isActive = false
            })
            .sink(receiveValue: {})
            .store(in: &subscriptions)

        // bind view model search results to collection view
        viewModel.$results
            // convert API models to View models
            .map { [imageLoader] results in
                results.compactMap { CellViewModel(model: $0, imageLoader: imageLoader) }
            }
            .handleEvents(receiveOutput: { [collectionView] values in
                // scroll back to the top when receiving new values
                if values.count > 0 {
                    collectionView?.contentOffset = CGPoint(x: 0, y: 0)
                }
            })
            .bind(subscriber: collectionView.itemsSubscriber(cellIdentifier: "cell", cellType: Cell.self) { cell, indexPath, model in
                cell.model = model
            })
            .store(in: &subscriptions)
    }
}

class Cell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!

    private var cancellable: AnyCancellable?

    override func prepareForReuse() {
        // cancel in-flight image fetching when cell gets reused
        cancellable?.cancel()
        imageView.image = nil
    }

    var model: CellViewModel! {
        didSet {
            // fetch image and assign to imageView
            cancellable = model.fetchImage()
                .receive(on: DispatchQueue.main)
                .assign(to: \.image, on: imageView)
//                .printCancellable()
        }
    }
}
