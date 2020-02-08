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

module serpent.graphics.pipeline.noop;

public import serpent.graphics.pipeline;

/**
 * The NoopPipeline exists to help us flesh out features in a meaningful
 * way and test performance.
 */
final class NoopPipeline : Pipeline
{

public:

    /**
     * Construct a new NoopPipeline.
     */
    this(Context context, Display display)
    {
        super(context, display);
    }

    /**
     * Currently do nothing in bootstrap
     */
    final override void bootstrap() @system
    {
    }

    /**
     * Shut down the pipeline
     */
    final override void shutdown() @system
    {
    }

    /**
     * Render everything in one cycle
     */
    final override void render(View!ReadOnly queryView) @system
    {
    }

    /**
     * Reset due to windowing change.
     */
    final override void reset() @system
    {

    }
}
