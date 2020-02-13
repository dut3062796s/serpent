/*
 * This file is part of serpent.
 *
 * Copyright © 2019-2020 Lispy Snake, Ltd.
 *
 * This software is provided 'as-is', without any express or implied
 * warranty. In no event will the authors be held liable for any damages
 * arising from the use of this software.
 *
 * Permission is granted to anyone to use this software for any purpose,
 * including commercial applications, and to alter it and redistribute it
 * freely, subject to the following restrictions:
 *
 * 1. The origin of this software must not be misrepresented; you must not
 *    claim that you wrote the original software. If you use this software
 *    in a product, an acknowledgment in the product documentation would be
 *    appreciated but is not required.
 * 2. Altered source versions must be plainly marked as such, and must not be
 *    misrepresented as being the original software.
 * 3. This notice may not be removed or altered from any source distribution.
 */

module serpent.tiled;

public import serpent.tiled.component;
public import serpent.tiled.layer;
public import serpent.tiled.map;
public import serpent.tiled.renderer;
public import serpent.tiled.tileset;
public import serpent.tiled.tmx;
public import serpent.tiled.tsx;

/**
 * TileFlipMode stores the high-bit-values for Tiled map guids.
 * Each guid stores any TileFlipMode internaly.
 */
final enum TileFlipMode
{
    Horizontal = 0x80000000, /**< Tile is flipped horizontally */
    Vertical = 0x40000000, /**< Tile is flipped vertically */
    Diagonal = 0x20000000, /**< Tile is flipped diagonally */

    /** Mask can be used to trivially unmask a guid. */
    Mask = TileFlipMode.Horizontal | TileFlipMode.Vertical | TileFlipMode.Diagonal,
};
