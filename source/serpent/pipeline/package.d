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

module serpent.pipeline;

public import serpent.display;
public import serpent.pipeline.sprite;

/**
 * The pipeline abstraction allows us to split our rendering logic from
 * our display/input management logic. Rendering is implemented internally
 * through Renderer instances.
 *
 * Internally implementations just use bgfx and render through them.
 */
final class Pipeline
{

private:
    Display _display;
    Renderer[] _renderers;

public:

    this()
    {
        /* Just try to optimise startup. */
        _renderers.reserve(3);
    }

    /**
     * Clear any drawing
     */
    final void clear()
    {
    }

    /**
     * Flush any drawing.
     */
    final void flush()
    {
    }

    /**
     * Add a renderer to the pipeline
     */
    final void addRenderer(Renderer r) @safe nothrow
    {
        r.pipeline = this;
        this._renderers ~= r;
    }

    /**
     * Return the associated display
     */
    @property final Display display() @safe @nogc nothrow
    {
        return _display;
    }

    /**
     * Set the associated display
     */
    @property final void display(Display d) @safe @nogc nothrow
    {
        this._display = d;
    }
}

/**
 * A renderer knows how to draw Things. It must be added to the
 * stages of a Pipeline for drawing to actually happen.
 */
abstract class Renderer
{

private:
    Pipeline _pipeline;

public:

    /**
     * Return the associated pipeline
     */
    @property final Pipeline pipeline() @safe @nogc nothrow
    {
        return _pipeline;
    }

    /**
     * Set the associated pipeline
     */
    @property final void pipeline(Pipeline p) @safe @nogc nothrow
    {
        this._pipeline = p;
    }

    /**
     * This renderer must do its job now.
     */
    abstract void render();
}
