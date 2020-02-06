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

module serpent.graphics.display;

import bindbc.sdl;
import bindbc.bgfx;
import std.string : toStringz, format;
import std.exception : enforce;

public import gfm.math;
public import std.stdint;

import serpent : SystemException;
import serpent.core.context;
import serpent.scene;
import serpent.graphics.pipeline;

/**
 * The Display handler
 *
 * The Display class is responsible for managing scenes and
 * drawing them. Effectively it is just a window.
 *
 * It will initialise dependent subsystems and prepare the window for
 * construction within the run routine.
 */
final class Display
{

private:
    bool didInit = false;
    int _height;
    int _width;
    bool _visible = false;
    SDL_Window* window = null;
    bool _resizable = false;
    string _title = "serpent";
    bgfx_init_t bInit;
    /* Default to Vulkan. */
    DriverType _driverType = DriverType.Vulkan;
    Pipeline _pipeline;

    /* Our scenes mapping */
    Scene[string] scenes;

    /* Active scene */
    Scene _scene;

    Context _context;

    uint32_t _backgroundColor = 0x303030ff;

    bool _debugMode = false;
    bool _fullscreen = false;

    uint _logicalWidth = 0;
    uint _logicalHeight = 0;
    bool _logicalSizeSet = false;

private:

    /**
     * Helper to initialise our dependent systems.
     */
    final void init() @system
    {
        if (SDL_Init(0 | SDL_INIT_GAMECONTROLLER) != 0)
        {
            throw new SystemException("Failed to initialise SDL: %s".format(SDL_GetError()));
        }
    }

    /**
     * Helper to shutdown our dependent systems.
     */
    final void shutdown() @system @nogc nothrow
    {
        SDL_Quit();
    }

    /**
     * Integrate bgfx with our SDL_Window's native handles.
     *
     * We don't do any SDL rendering whether via SDL_Renderer or
     * OpenGL context. /All/ drawing is performed through the bgfx
     * library.
     */
    final void integrateWindowBgfx() @system
    {
        SDL_SysWMinfo wm;
        SDL_VERSION(&wm.version_);

        if (!SDL_GetWindowWMInfo(window, &wm))
        {
            throw new SystemException("Couldn't get Window Info: %s".format(SDL_GetError()));
        }

        bgfx_platform_data_t pd;
        version (Posix)
        {
            /* X11 displays. Note we need to fix OSX integration separate. */
            pd.ndt = wm.info.x11.display;
            pd.nwh = cast(void*) wm.info.x11.window;
        }
        else
        {
            throw new SystemException("Unsupported platform");
        }

        pd.context = null;
        pd.backBuffer = null;
        pd.backBufferDS = null;
        bgfx_set_platform_data(&pd);
    }

    /**
     * reset bgfx buffer
     */
    final void reset(uint flags = BGFX_RESET_VSYNC) @system @nogc nothrow
    {
        if (!didInit)
        {
            return;
        }
        bgfx_reset(_width, _height, flags, bInit.resolution.format);
        if (scene !is null && scene.camera !is null)
        {
            scene.camera.update();
        }
    }

    /**
     * process pending window events
     */
    final bool processWindow(SDL_WindowEvent* event) @system
    {
        switch (event.event)
        {
        case SDL_WINDOWEVENT_RESIZED:
            _width = event.data1;
            _height = event.data2;
            reset();
            return true;
        default:
            return false;
        }
    }

    final void updateDebug() @system @nogc nothrow
    {
        if (!_debugMode)
        {
            bgfx_set_debug(0);
            return;
        }
        bgfx_set_debug(BGFX_DEBUG_STATS | BGFX_DEBUG_TEXT);
    }

public:

    /** Must have window attributes to construct */
    @disable this();

    /**
     * Construct a new Display
     *
     * This will construct a new display with the given width and height.
     */
    final this(Context ctx, int width, int height) @system
    {
        init();

        this.context = ctx;
        this._pipeline = new Pipeline(ctx, this);

        this._width = width;
        this._height = height;
    }

    final ~this() @system @nogc nothrow
    {
        if (window)
        {
            bgfx_shutdown();
            SDL_DestroyWindow(window);
        }
        shutdown();
    }

    final bool process(SDL_Event* event) @system
    {
        switch (event.type)
        {
        case SDL_WINDOWEVENT:
            return processWindow(&event.window);
        default:
            return false;
        }
    }

    /**
     * Ensure initialisation
     */
    final void prepare() @system
    {
        if (didInit)
        {
            return;
        }
        import std.stdio;

        didInit = true;

        SDL_WindowFlags flags = cast(SDL_WindowFlags) 0;
        if (fullscreen)
        {
            flags |= SDL_WINDOW_FULLSCREEN_DESKTOP;
        }
        if (visible)
        {
            flags |= SDL_WINDOW_SHOWN;
        }
        else
        {
            flags |= SDL_WINDOW_HIDDEN;
        }

        window = SDL_CreateWindow(toStringz(_title), SDL_WINDOWPOS_UNDEFINED,
                SDL_WINDOWPOS_UNDEFINED, _width, _height, flags);
        if (!window)
        {
            throw new SystemException("Couldn't create Window: %s".format(SDL_GetError()));
        }

        bgfx_init_ctor(&bInit);

        integrateWindowBgfx();

        /* TODO: Init on separate render thread */
        bInit.type = context.info.convDriver(this._driverType);
        bgfx_init(&bInit);
        reset();
        updateDebug();

        /* Set clearing of view0 background. */
        _pipeline.clear(0);
    }

    /**
     * Add a scene to the display for rendering.
     * If no scenes are currently active, this will be set as the
     * current scene.
     */
    final void addScene(Scene s) @safe
    {
        enforce(s.name !in scenes, "Duplicate scene name");
        scenes[s.name] = s;
        s.display = this;
        if (_scene is null)
        {
            _scene = s;
        }
    }

    /**
     * Return the currently set window title
     */
    pure @property final string title() @nogc @safe nothrow
    {
        return _title;
    }

    /**
     * Set the window title.
     */
    @property final Display title(string title) @system nothrow
    {
        this._title = title;
        SDL_SetWindowTitle(window, toStringz(_title));
        return this;
    }

    /**
     * Return the size of the display
     */
    @property final vec2i size() @safe @nogc nothrow
    {
        return vec2i(_width, _height);
    }

    /**
     * Set the size to a given vec2i
     */
    @property final Display size(vec2i size) @system @nogc nothrow
    {
        _width = size.x;
        _height = size.y;
        SDL_SetWindowSize(window, _width, _height);
        reset();
        return this;
    }

    /**
     * Set the size using integers
     */
    @property final Display size(int w, int h) @system @nogc nothrow
    {
        return size(vec2i(w, h));
    }

    /**
     * Returns the current scene.
     */
    @property final Scene scene() @nogc @safe nothrow
    {
        return _scene;
    }

    /**
     * Set the scene to a scene object, that must already be added.
     */
    @property final void scene(Scene s) @safe
    {
        enforce(s.name in scenes, "Cannot use scene that hasn't been added to Display");
        enforce(s !is null, "Cannot use a null Scene");
        _scene = s;
    }

    /**
     * Set the scene to the name of a previously added scene.
     */
    @property final void scene(string s) @safe
    {
        enforce(s in scenes, "Cannot use unknown scene '%s'".format(s));
        enforce(s !is null, "Cannot use a null scene ID");
        _scene = scenes[s];
    }

    /**
     * Return our width.
     */
    pure @property final const int width() @nogc @safe nothrow
    {
        return _width;
    }

    /**
     * Return our height.
     */
    pure @property final const int height() @nogc @safe nothrow
    {
        return _height;
    }

    /**
     * Return the logical width for the underlying render system
     */
    pure @property final const int logicalWidth() @nogc @safe nothrow
    {
        if (_logicalSizeSet)
        {
            return _logicalWidth;
        }
        return _width;
    }

    /**
     * Return the logical height for the underlying render system
     */
    pure @property final const int logicalHeight() @nogc @safe nothrow
    {
        if (_logicalSizeSet)
        {
            return _logicalHeight;
        }
        return _height;
    }

    /**
     * Set the logical size of the display
     */
    pure @property final const vec2i logicalSize() @nogc @safe nothrow
    {
        if (_logicalSizeSet)
        {
            return vec2i(_logicalWidth, _logicalHeight);
        }
        return vec2i(_width, _height);
    }

    /**
     * Set the logical size of the display
     */
    pure @property final void logicalSize(vec2i size) @nogc @safe nothrow
    {
        if (size.x <= 0 && size.y <= 0)
        {
            _logicalSizeSet = false;
            return;
        }
        _logicalSizeSet = true;
        _logicalHeight = size.y;
        _logicalWidth = size.x;
    }

    /**
     * Return the logical size of the display
     */
    pure @property final void logicalSize(int w, int h) @nogc @safe nothrow
    {
        logicalSize(vec2i(w, h));
    }

    /**
     * Returns true if the window is resizable
     */
    pure @property final bool resizable() @nogc @safe nothrow
    {
        return _resizable;
    }

    /**
     * Enable or disable resizing for the window
     */
    @property final void resizable(bool b) @nogc @system nothrow
    {
        if (b == resizable)
        {
            return;
        }
        _resizable = b;
        if (window == null)
        {
            return;
        }
        SDL_SetWindowResizable(window, _resizable ? SDL_TRUE : SDL_FALSE);
    }

    /**
     * Returns true if the window is visible
     */
    pure @property final bool visible() @nogc @safe nothrow
    {
        return _visible;
    }

    /**
     * Hide or show the window
     */
    @property final void visible(bool b) @system
    {
        if (b == _visible)
        {
            return;
        }
        _visible = b;
        if (window == null)
        {
            return;
        }
        if (b)
        {
            SDL_ShowWindow(window);
        }
        else
        {
            SDL_HideWindow(window);
        }
    }

    /**
     * Returns whether we're in fullscreen mode
     */
    pure @property final bool fullscreen() @nogc @safe nothrow
    {
        return _fullscreen;
    }

    @property final void fullscreen(bool b) @system
    {
        if (b == _fullscreen)
        {
            return;
        }
        _fullscreen = b;
        if (window == null)
        {
            return;
        }
        SDL_SetWindowFullscreen(window, b ? SDL_WINDOW_FULLSCREEN_DESKTOP : SDL_WINDOW_SHOWN);
        import std.stdio;

        writefln("ERROR: Need to bgfx_reset and follow window changes. Check TODO!");
    }

    /**
     * Get the display associated with this Game
     */
    pure @property final Context context() @safe @nogc nothrow
    {
        return _context;
    }

    /**
     * Set the display associated with this Game
     */
    @property final void context(Context c) @safe
    {
        enforce(c !is null, "Context cannot be null");
        _context = c;
    }

    /**
     * Return the display background color
     */
    pure @property final uint32_t backgroundColor() @safe @nogc nothrow
    {
        return _backgroundColor;
    }

    /**
     * Set the display background color
     */
    @property final void backgroundColor(uint32_t bg) @system @nogc nothrow
    {
        if (bg == _backgroundColor)
        {
            return;
        }
        _backgroundColor = bg;
        if (!didInit)
        {
            return;
        }
        _pipeline.clear(0);
    }

    /**
     * Return true if debugMode is set
     */
    pure @property final bool debugMode() @safe @nogc nothrow
    {
        return _debugMode;
    }

    /**
     * Update the debugMode
     */
    @property final void debugMode(bool b) @system @nogc nothrow
    {
        if (_debugMode == b)
        {
            return;
        }
        _debugMode = b;
        if (!didInit)
        {
            return;
        }
        updateDebug();
    }

    /**
     * Return the real driverType in use once the display is up and
     * running
     */
    pure @property final DriverType driverType() @safe @nogc nothrow
    {
        return context.info.driverType();
    }

    /**
     * Override the default Driver to use before the display is up
     * and running. This allows forcibly switching to OpenGL, Vulkan, etc.
     */
    @property final Display driverType(DriverType d) @safe
    {
        enforce(!didInit, "Cannot change driverType when running.");
        _driverType = d;
        return this;
    }

    /**
     * Return underlying pipeline
     */
    @property final Pipeline pipeline() @safe @nogc nothrow
    {
        return _pipeline;
    }
}
