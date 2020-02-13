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

module serpent.graphics.texture;

import bindbc.sdl;
import bindbc.sdl.image;
import std.string : toStringz;
import bindbc.bgfx;
import gfm.math;

/**
 * This is a very temporary type which will undergo many changes as
 * the engine evolves.
 */
final class Texture
{

private:

    SDL_Surface* surface = null;
    float _width = 0;
    float _height = 0;
    string _path = null;

    /**
     * Default clip will be set later.
     */
    box2f _clip = box2f(0.0f, 0.0f, 1.0f, 1.0f);

    bgfx_texture_handle_t _handle = cast(bgfx_texture_handle_t) 0;

public:

    /**
     * Construct a new Texture from the given filename
     *
     * TODO: Make less hacky, try DDS load first, fallback to SDL_Image
     * unoptimised path.
     */
    this(string filename)
    {
        surface = IMG_Load(toStringz(filename));
        _path = filename;
        if (!surface)
        {
            return;
        }

        /* Convert the surface to something usable */
        auto surface2 = SDL_ConvertSurfaceFormat(surface, SDL_PIXELFORMAT_RGBA32, 0);
        SDL_FreeSurface(surface);
        surface = surface2;

        _width = surface.w;
        _height = surface.h;

        _clip = rectanglef(0.0f, 0.0f, _width, _height);

        /* TODO: Optimise to the platform. */
        auto fmt = bgfx_texture_format_t.BGFX_TEXTURE_FORMAT_RGBA8;
        _handle = bgfx_create_texture_2d(cast(ushort) surface.w, cast(ushort) surface.h, false, 1, fmt,
                BGFX_SAMPLER_U_CLAMP | BGFX_SAMPLER_V_CLAMP,
                bgfx_make_ref(surface.pixels, surface.h * surface.pitch));
    }

    ~this()
    {
        if (surface !is null)
        {
            bgfx_destroy_texture(handle);
            SDL_FreeSurface(surface);
        }
    }

    /**
     * Return the underlying bgfx handle.
     */
    pure @property final const bgfx_texture_handle_t handle() @nogc @safe nothrow
    {
        return _handle;
    }

    /**
     * Return texture width
     */
    pure @property final const float width() @nogc @safe nothrow
    {
        return _width;
    }

    /**
     * Return texture height
     */
    pure @property final const float height() @nogc @safe nothrow
    {
        return _height;
    }

    /**
     * Return the clipping region for drawing.
     */
    pure @property final const box2f clip() @nogc @safe nothrow
    {
        return _clip;
    }

    /**
     * Return the path used for this texture (for sorting)
     */
    pure @property final const string path() @nogc @safe nothrow
    {
        return _path;
    }
}
