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

module serpent.display;

import bindbc.sdl;
import bindbc.bgfx;
import std.string : toStringz, format;
import std.exception : enforce;

import serpent : SystemException;
import serpent.pipeline;
import serpent.game;
import serpent.scene;

/**
 * The Display handler
 *
 * The Display class is responsible for the main lifecycle of the game.
 * As a core part of the framework, it is the main entry point into
 * running and developing games.
 *
 * It will initialise dependent subsystems and prepare the window for
 * construction within the run routine.
 */
final class Display
{

private:
    int height;
    int width;
    SDL_Window* window = null;
    bool running = false;
    string _title = "serpent";
    bgfx_init_t bInit;
    Pipeline _pipeline = null;
    Game _game = null;

    /* Our scenes mapping */
    Scene[string] scenes;

    /* Active scene */
    Scene _scene;

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
        bgfx_init_ctor(&bInit);
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
     * Handle any events pending in the queue and appropriately
     * dispatch them.
     */
    final void processEvents() @system @nogc nothrow
    {
        SDL_Event event;

        while (SDL_PollEvent(&event))
        {
            switch (event.type)
            {
            case SDL_QUIT:
                running = false;
                break;
            default:
                break;
            }
        }
    }

    /**
     * Perform any required rendering
     */
    final void render() @system @nogc nothrow
    {
        /* Set up the view */
        bgfx_set_view_rect(0, 0, 0, cast(ushort) width, cast(ushort) height);

        /* Debug crap. Draw things. */
        bgfx_touch(0);
        bgfx_dbg_text_clear(0, false);
        bgfx_dbg_text_printf(2, 1, 0x03, "Hullo, bgfx + SDL. :)");
        bgfx_dbg_text_printf(2, 2, 0x01, "Serpent Game Framework");
        bgfx_dbg_text_printf(2, 8, 0x08, "- Lispy Snake, Ltd");

        /* Skip frame now */
        bgfx_frame(false);
    }

public:

    /** Must have window attributes to construct */
    @disable this();

    /**
     * Construct a new Display
     *
     * This will construct a new display with the given width and height.
     */
    final this(int width, int height) @system
    {
        init();
        this.width = width;
        this.height = height;
    }

    final ~this() @system @nogc nothrow
    {
        if (window)
        {
            SDL_DestroyWindow(window);
        }
        shutdown();
    }

    /**
     * Bring up windowing resources and start the main game loop.
     */
    final int run() @system
    {
        auto flags = SDL_WINDOW_HIDDEN;
        SDL_Event e;

        enforce(_pipeline !is null, "Cannot run without a valid pipeline!");
        enforce(_game !is null, "Cannot run without a valid game!");

        window = SDL_CreateWindow(toStringz(_title), SDL_WINDOWPOS_UNDEFINED,
                SDL_WINDOWPOS_UNDEFINED, width, height, flags);
        if (!window)
        {
            throw new SystemException("Couldn't create Window: %s".format(SDL_GetError()));
        }

        integrateWindowBgfx();
        scope (exit)
        {
            bgfx_shutdown();
        }

        /* TODO: Init on separate render thread */
        bgfx_init(&bInit);
        bgfx_reset(width, height, BGFX_RESET_VSYNC, bInit.resolution.format);
        bgfx_set_debug(BGFX_DEBUG_TEXT);

        running = true;

        _game.display = this;

        /* Init the game instance against our configured display */
        if (!_game.init())
        {
            return 1;
        }

        scope (exit)
        {
            _game.shutdown();
        }

        SDL_ShowWindow(window);

        while (running)
        {
            processEvents();
            render();
        }

        return 0;
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
        if (_scene is null)
        {
            _scene = s;
        }
    }

    /**
     * Return the currently set window title
     */
    @property final string title() @nogc @safe nothrow
    {
        return _title;
    }

    /**
     * Set the window title.
     */
    @property final Display title(string title) @system nothrow
    {
        this._title = title;
        if (!running)
        {
            return this;
        }
        SDL_SetWindowTitle(window, toStringz(_title));
        return this;
    }

    /**
     * Return the pipeline associated with this display
     */
    @property final Pipeline pipeline() @nogc @safe nothrow
    {
        return _pipeline;
    }

    /**
     * Set the pipeline to be used.
     */
    @property final Display pipeline(Pipeline p) @safe
    {
        enforce(p !is null, "Pipeline instance must be valid");
        enforce(!running, "Cannot change pipeline once running");
        _pipeline = p;
        _pipeline.display = this;
        return this;
    }

    /**
     * Returns the Game for this Display to run
     */
    @property final Game game() @nogc @safe nothrow
    {
        return _game;
    }

    /**
     * Set the Game for this Display to run
     */
    @property final Display game(Game g) @safe
    {
        enforce(g !is null, "Game instance must be valid");
        enforce(!running, "Cannot change game once running");
        _game = g;
        _game.display = this;
        return this;
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
}
