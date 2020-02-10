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

import serpent;
import std.stdio : writeln, writefln;
import std.exception;
import bindbc.sdl;
import serpent.tiled;
import std.format;

/**
 * We apply a PhysicsComponent when there is some position manipulation
 * to be had.
 */
@serpentComponent final struct PhysicsComponent
{
    float velocityX = 0.0f;
    float velocityY = 0.0f;
}

/**
 * Demo physics - if have velocity, go.
 */
final class BasicPhysics : Processor!ReadWrite
{
    final override void run(View!ReadWrite view)
    {
        /* Find all physics entities */
        foreach (ent; view.withComponent!PhysicsComponent())
        {
            auto transform = view.data!TransformComponent(ent);
            auto physics = view.data!PhysicsComponent(ent);

            auto frameTime = context.frameTime();

            transform.position.x += physics.velocityX * frameTime;
            transform.position.y += physics.velocityY * frameTime;
        }
    }
}

/**
 * Provided merely for demo purposes.
 */
final class DemoGame : App
{

private:
    Scene s;
    Entity[] background;
    Texture[7] robotTextures;
    Texture[10] mechTextures;
    Entity sprite;
    Entity mech;
    ulong robotIndex;
    Duration passed;

    Duration passedMech;
    ulong mechIndex;

    /**
     * A keyboard key was just released
     */
    final void onKeyReleased(KeyboardEvent e) @system
    {
        switch (e.scancode())
        {
        case SDL_SCANCODE_F:
            context.display.fullscreen = !context.display.fullscreen;
            break;
        case SDL_SCANCODE_Q:
            writeln("Quitting time.");
            context.quit();
            break;
        case SDL_SCANCODE_D:
            context.display.pipeline.debugMode = !context.display.pipeline.debugMode;
            break;
        default:
            writeln("Key released");
            break;
        }
    }

public:

    /**
     * All initial game setup should be done from bootstrap.
     */
    final override bool bootstrap(View!ReadWrite initView) @system
    {
        writeln("Game Init");

        /* We need input working. */
        context.input.keyReleased.connect(&onKeyReleased);

        /* Create our first scene */
        s = new Scene("sample");
        context.display.addScene(s);
        s.addCamera(new OrthographicCamera());

        context.component.registerComponent!PhysicsComponent;
        context.systemGroup.add(new BasicPhysics());

        auto texture = new Texture("assets/SciFi/Environments/bulkhead-walls/PNG/bg-wall.png");
        auto floortexture = new Texture("assets/SciFi/Environments/bulkhead-walls/PNG/floor.png");
        auto altTexture = new Texture(
                "assets/SciFi/Environments/bulkhead-walls/PNG/bg-wall-with-supports.png");

        float x = 0;
        int idx = 0;
        while (x < context.display.logicalWidth + 300)
        {
            background ~= initView.createEntity();
            auto component = initView.addComponent!SpriteComponent(background[idx]);
            if (idx % 2 == 0)
            {
                component.texture = altTexture;
            }
            else
            {
                component.texture = texture;
            }
            auto transform = initView.data!TransformComponent(background[idx]);
            transform.position.x = x;
            transform.position.z = -0.1f;
            x += component.texture.width;
            idx++;
        }

        int columns = 480 / cast(int) floortexture.width + 5;
        foreach (i; 0 .. columns)
        {
            auto floor = initView.createEntity();
            initView.addComponent!SpriteComponent(floor).texture = floortexture;
            initView.data!TransformComponent(floor).position.x = i * floortexture.width;
            initView.data!TransformComponent(floor)
                .position.y = texture.height - floortexture.height;
        }

        foreach (i; 0 .. 7)
        {
            robotTextures[i] = new Texture(
                    "assets/SciFi/Sprites/bipedal-Unit/PNG/sprites/bipedal-unit%d.png".format(i + 1));
        }

        sprite = initView.createEntity();
        initView.addComponent!SpriteComponent(sprite).texture = robotTextures[0];
        initView.data!TransformComponent(sprite).position.x = 30.0f;
        initView.data!TransformComponent(sprite).position.y = texture.height - 73.0f;
        initView.data!TransformComponent(sprite).position.z = 0.1f;

        foreach (i; 0 .. 10)
        {
            mechTextures[i] = new Texture(
                    "assets/SciFi/Sprites/mech-unit/sprites/mech-unit-export%d.png".format(i + 1));
        }

        mech = initView.createEntity();
        initView.addComponent!SpriteComponent(mech).texture = mechTextures[0];
        initView.data!TransformComponent(mech).position.z = 0.1f;
        initView.data!TransformComponent(mech).position.x = -80.0f;
        initView.data!TransformComponent(mech)
            .position.y = texture.height - mechTextures[0].height - 12;

        auto meterSize = 70; /* 70 pixels is our one meter */

        /* Mech travels 70cm per second */
        auto physMech = initView.addComponent!PhysicsComponent(mech);
        physMech.velocityX = (meterSize * 0.7) / 1000.0f;

        /* Robot travels 90cm per second */
        auto physRobot = initView.addComponent!PhysicsComponent(sprite);
        physRobot.velocityX = (meterSize * 0.9f) / 1000.0f;

        return true;
    }

    final override void update(View!ReadWrite view)
    {
        updateRobot(view);
        updateMech(view);
    }

    final void updateMech(View!ReadWrite view)
    {
        import std.datetime;

        passedMech += context.deltaTime();
        if (passedMech <= dur!"msecs"(80))
        {
            return;
        }
        passedMech = context.deltaTime();
        mechIndex++;
        if (mechIndex >= mechTextures.length)
        {
            mechIndex = 0;
        }
        view.data!SpriteComponent(mech).texture = mechTextures[mechIndex];
    }

    final void updateRobot(View!ReadWrite view)
    {
        import gfm.math;

        auto component = view.data!TransformComponent(sprite);

        auto boundsX = (component.position.x + robotTextures[robotIndex].width / 2) - (
                context.display.logicalWidth() / 2);
        auto boundsY = 0.0f;
        s.camera.position = vec3f(boundsX, 0.0f, 0.0f);
        auto bounds = rectanglef(0.0f, 0.0f, 480.0f + 200.0f, 176.0f);
        auto viewport = rectanglef(0.0f, 0.0f, 480.0f, 176.0f);
        s.camera.clamp(bounds, viewport);
        import std.datetime;

        passed += context.deltaTime();
        if (passed <= dur!"msecs"(80))
        {
            return;
        }
        passed = context.deltaTime();
        robotIndex++;
        if (robotIndex >= robotTextures.length)
        {
            robotIndex = 0;
        }
        view.data!SpriteComponent(sprite).texture = robotTextures[robotIndex];
    }
}
