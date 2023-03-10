//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Seun Adebanwo on 19/02/2023.
//

import Foundation

// By using the HTTPClientResult enum
// we end up with only two representable paths.
public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    // Theres no need to make the HTTPClient a singleton
    // or a shared instance, apart from convenience
    // to locate the instance directly
    // This is considered an anti pattern because it
    // can introduce tight coupling use DI instead
    // DI conforms to the open closed principle
    // and keeps the design modular
    //static var shared = HTTPCLient()

    // Use protocol instead of class.
    // This is just a contract defining which external functionality
    // the remote feed loader needs.
    // We dont need to create a new type to confirm it.
    // We can easily create an extension on URLSession
    // or AlamoFire to conform to the protocol
    // This ensures our RemoteFeedLoader does not have to depend
    // on concrete types like URLSession which makes it more flexible
    // and open for extension
    
    // In protocol you dont have implementation just the definition
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}

public final class RemoteFeedLoader {
    // `public` makes the class accessible from other modules
    // By making final you prevent subclassing
    private let url: URL
    private let client: HTTPClient
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping(Result) -> Void) {
        client.get(from: url) { result in
            switch result {
            case let .success(data, response):
                do {
                    let items = try FeedItemsMapper.map(data, response)
                    completion(.success(items))
                } catch {
                    completion(.failure(.invalidData))
                }
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}

private class FeedItemsMapper {
    private struct Root: Decodable {
        let items: [Item]
    }

    private struct Item: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: URL
        
        var item: FeedItem {
            return FeedItem(
                id: id,
                description: description,
                location: location,
                imageURL: image
            )
        }
    }
    
    static var OK_200: Int { return 200 }
    
    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [FeedItem] {
        guard response.statusCode == OK_200 else {
            throw RemoteFeedLoader.Error.invalidData
        }
        
        let root = try JSONDecoder().decode(Root.self, from: data)
        return root.items.map{
            $0.item
        }
    }
}
