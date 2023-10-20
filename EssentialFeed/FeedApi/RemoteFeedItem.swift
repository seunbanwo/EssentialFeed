//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Oluwaseun Adebanwo on 16/10/2023.
//

import Foundation

internal struct RemoteFeedItem: Decodable {
    internal let id: UUID
    internal let description: String?
    internal let location: String?
    internal let image: URL
}