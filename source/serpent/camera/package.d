/*
 * This file is part of serpent.
 *
 * Copyright © 2019 Lispy Snake, Ltd.
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

module serpent.camera;
import serpent.scene;

public import serpent.camera.orthographic;

import gfm.math;
import std.exception : enforce;

/**
 * The Camera class is responsible for providing the correct positions
 * for an Entity to be rendered. Without a camera, the correct perpective
 * and positions will not be used.
 *
 * Typically you need to instaniate a subclass of Camera for it to be
 * effective.
 */
abstract class Camera
{

private:
    Scene _scene;
    string _name;
    mat4f _matrix;
    mat4f _identity;

public:

    this()
    {
        _identity = _identity.identity();
    }

    /**
     * Apply the Camera transformation prior to rendering.
     */
    abstract void apply() @nogc nothrow;

    /**
     * Update Camera for display
     */
    abstract void update() @nogc @safe nothrow;

    /**
     * Return the Scene associated with this Camera
     */
    @property final Scene scene() @nogc @safe nothrow
    {
        return _scene;
    }

    /**
     * Set the Scene associated with this Camera
     */
    @property final void scene(Scene s) @safe
    {
        enforce(s !is null, "Should not have a null Scene");
        _scene = s;
        this.update();
    }

    /**
     * Return the name for this camera
     */
    @property final string name() @nogc @safe nothrow
    {
        return _name;
    }

    /**
     * Set the Camera name
     */
    @property final void name(string s) @safe
    {
        enforce(s !is null, "Camera name cannot be null");
        _name = s;
    }

    /**
     * Return the current matrix.
     */
    pure @property final mat4f matrix() @nogc @safe nothrow
    {
        return _matrix;
    }

    /**
     * Set the current matrix.
     */
    @property final void matrix(mat4f m) @nogc @safe nothrow
    {
        _matrix = m;
    }

    /**
     * Return the current identity
     */
    pure @property final mat4f identity() @nogc @safe nothrow
    {
        return _identity;
    }

    /**
     * Set the current identity
     */
    @property final void identity(mat4f i) @nogc @safe nothrow
    {
        _identity = i;
    }
}
