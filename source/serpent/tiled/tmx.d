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

module serpent.tiled.tmx;

public import serpent.tiled.map;

import std.file;
import std.xml;
import std.exception : enforce;
import std.conv : to;
import std.format;

/**
 * The TMXParser exists solely as a utility class to load TMX files.
 * Currently this is a janky utility class until such point as we have
 * a proper loader mechanism in place.
 */
final class TMXParser
{

private:

    /**
     * Begin parsing the actual XML document.
     */
    static final Map parseMap(Document doc) @safe
    {
        enforce(doc.tag.name == "map", "First element should be <map>");
        auto map = new Map();

        /* Grab our basic map attributes */
        foreach (attr, attrValue; doc.tag.attr)
        {
            switch (attr)
            {
            case "tileheight":
                map.tileHeight = to!int(attrValue);
                break;
            case "tilewidth":
                map.tileWidth = to!int(attrValue);
                break;
            case "width":
                map.width = to!int(attrValue);
                break;
            case "height":
                map.height = to!int(attrValue);
                break;
            case "orientation":
                switch (attrValue)
                {
                case "orthogonal":
                    map.orientation = MapOrientation.Orthogonal;
                    break;
                case "isometric":
                    map.orientation = MapOrientation.Isometric;
                    break;
                case "staggered":
                    map.orientation = MapOrientation.Staggered;
                    break;
                case "hexagonal":
                    map.orientation = MapOrientation.Hexagonal;
                    break;
                default:
                    enforce("Unknown orientation in Map");
                    break;
                }
                break;
            default:
                break;
            }
        }

        map.validate();

        foreach (ref element; doc.elements)
        {
            switch (element.tag.name)
            {
            case "tileset":
                parseTileset(map, element);
                break;
            case "layer":
                parseLayer(map, element);
                break;
            default:
                /* Unknown */
                break;
            }
        }

        return map;
    }

    /**
     * In future we'll actually need to do something with the tilesheet,
     * determine if it is embedded, etc. For now, skip it.
     */
    static final void parseTileset(Map map, Element e) @safe @nogc nothrow
    {
    }

    /**
     * Handle each layer in the map, assigning a MapLayer instance to the
     * map.layers array.
     */
    static final void parseLayer(Map map, Element e) @safe
    {
        auto layer = new MapLayer();
        auto encoding = LayerEncoding.XML;
        auto compression = LayerCompression.None;

        foreach (attr, attrValue; e.tag.attr)
        {
            switch (attr)
            {
            case "id":
                layer.id = attrValue;
                break;
            case "name":
                layer.name = attrValue;
                break;
            case "width":
                layer.width = to!int(attrValue);
                break;
            case "height":
                layer.height = to!int(attrValue);
                break;
            default:
                break;
            }
        }

        enforce(layer.height > 0, "Layer height should be more than zero");
        enforce(layer.width > 0, "Layer width should be more than zero");

        layer.allocateBlob();

        /* TODO: Find out if these enforce s work across all data payloads. */
        enforce(e.elements.length == 1, "Layer payload should contain 1 data blob");
        auto data = e.elements[0];
        enforce(data.tag.name == "data", "Payload element should be named 'data'");

        /* Determine the payload encoding + compression */
        foreach (attr, attrValue; data.tag.attr)
        {
            switch (attr)
            {
            case "encoding":
                switch (attrValue)
                {
                case "base64":
                    encoding = LayerEncoding.Base64;
                    break;
                case "csv":
                    encoding = LayerEncoding.CSV;
                    break;
                case "xml":
                    encoding = LayerEncoding.XML;
                    break;
                default:
                    enforce("Unknown encoding: %s".format(attrValue));
                    break;
                }
                break;
            case "compression":
                switch (attrValue)
                {
                case "zlib":
                    compression = LayerCompression.Deflate;
                    break;
                case "gzip":
                    compression = LayerCompression.GZip;
                    break;
                default:
                    enforce("Uknown compression: %s".format(attrValue));
                    break;
                }
                break;
            default:
                break;
            }
        }

        /* TODO: Parse the blob now. */

        map.appendLayer(layer);
    }

public:

    /**
     * As a static utility class, there is no point in constructing us.
     */
    @disable this();

    /**
     * Load a map from the given path.
     * In future we need to use crossplatform path + loading capabilities.
     */
    static final Map loadTMX(string path) @trusted
    {
        auto r = cast(string) std.file.read(path);
        std.xml.check(r);

        auto doc = new Document(r);
        return parseMap(doc);
    }
}
