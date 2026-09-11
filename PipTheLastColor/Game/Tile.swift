//
//  Tile.swift
//  Pip: The Last Color
//

import SpriteKit

enum TileState {
    case faded
    case restored
}

struct TilePosition: Hashable {
    let col: Int
    let row: Int
}
