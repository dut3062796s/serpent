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

module serpent.app;

import serpent.context;

/**
 * The App interface is used to control lifecycle and entry points,
 * to make life that bit easier for the end developer. This avoids
 * ugly C-style func hooks.
 */
abstract class App
{

private:
    Context _context;

public:
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
    @property final void context(Context c) @safe @nogc nothrow
    {
        _context = c;
    }

    /**
     * Implementations should attempt to init themselves at this
     * point as the Window is up and running. Once this method
     * has returned safely, the window will be shown for the first
     * time.
     *
     * At this point we safely have a rendering context and any
     * loading can begin.
     */
    abstract bool init();

    /**
     * Implementations should take care to clean up any resources
     * they've allocated and not rely solely on the destructor.
     */
    void shutdown()
    {
    }
}
