//
//  SearchViewController.swift
//  MyNetflix
//
//  Created by joonwon lee on 2020/04/02.
//  Copyright © 2020 com.joonwon. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var resultCollectionView: UICollectionView!
    
    var movies: [Movie] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

extension SearchViewController: UICollectionViewDataSource {
    // 몇개 넘어옴?

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return movies.count
    }
    // 어떻게 표현할꺼야?

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ResultCell", for: indexPath ) as?
                ResultCell else {
                    return UICollectionViewCell()
                }
        
                cell.backgroundColor = .red
                return cell
    }
}

extension SearchViewController: UICollectionViewDelegate {
    
}

extension SearchViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let margin: CGFloat = 8
        let itemSpacing: CGFloat = 10
        
        let width = (collectionView.bounds.width - margin * 2 - itemSpacing * 2) / 3
        let hegiht = width * 10 / 7
        return CGSize(width: width, height: hegiht)
    }
}

class ResultCell: UICollectionViewCell {
    @IBOutlet weak var movieThumbnail: UIImageView!
}

extension SearchViewController: UISearchBarDelegate {
    
    private func dismissKeyboard() {
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        
        // 검색 시작
        
        // 키보드가 올라올 때, 내려가게 처리
        dismissKeyboard()
        // 검색어가 있는지
        
        guard let searchTerm = searchBar.text, searchTerm.isEmpty == false else { return }

        // 네트워킹을 통한 검색
        // - 목표: 서치텀을 가지고 네트워킹을 통해서 영화 검색
        // - [x] 검색API 필요
        // - [x] 결과를 받아올 모델 movie, respone
        // - 결과를 받아와서, CollectionView로 표현하기
        
        SearchAPI.search(searchTerm) { movies in
            // collectionView로 표현
            print("--> 몇 개 넘어왔어??:\(movies.count), 첫번째꺼 제목: \(movies.first?.title)")
            
            self.movies = movies
            self.resultCollectionView.reloadData()

        }
        
        print("--> 검색어: \(searchTerm)")
    }
}

class SearchAPI {
    static func search(_ term: String, completion: @escaping ([Movie]) -> Void) {
        let session = URLSession(configuration: .default)
        var urlComponents = URLComponents(string: "https://itunes.apple.com/search?")!
        let mediaQuery = URLQueryItem(name: "media", value: "movie")
        let entityQuery = URLQueryItem(name: "entity", value: "movie")
        let termQuery = URLQueryItem(name: "term", value: term)
        urlComponents.queryItems?.append(mediaQuery)
        urlComponents.queryItems?.append(entityQuery)
        urlComponents.queryItems?.append(termQuery)
        
        let requestURL = urlComponents.url!
        
        let dataTask = session.dataTask(with: requestURL) { data, response, error in
            let successRange = 200..<300
            guard error == nil,
                let statusCode = (response as? HTTPURLResponse)?.statusCode,
                successRange.contains(statusCode) else {
                    completion([])
                    return
            }
            
            guard let resultData = data else {
                completion([])
                return
            }
            
            let movies = SearchAPI.parseMovies(resultData)
            completion(movies)
        }
        dataTask.resume()
    }
    
    static func parseMovies(_ data: Data) -> [Movie] {
        let decoder = JSONDecoder()

        do {
            let response = try decoder.decode(Response.self, from: data)
            let movies = response.movies
            return movies
        } catch let error {
            print("--> parsing error: \(error.localizedDescription)")
            return []
        }
    }
}

struct Response: Codable {
    let resultCount: Int
    let movies: [Movie]
    
    enum CodingKeys: String, CodingKey {
        case resultCount
        case movies = "results"
    }
}

struct Movie: Codable {
    let title: String
    let director: String
    let thumbnailPath: String
    let previewURL: String
    
    enum CodingKeys: String, CodingKey {
        case title = "trackName"
        case director = "artistName"
        case thumbnailPath = "artworkUrl100"
        case previewURL = "previewUrl"
    }
}