So, long story short, we have 2 repos (prior effort and current) and many, many private
branches of this project. Add to that, we have 2 months where we ourselves weren't fully
online with the rest of the world due to various issues, health, etc.

So, let's get this document in order now to organise this months work to get Serpent into
basic demo shape.

 - [x] Bring back basic keyboard handling (F, etc.)
    - Expose underlying SDL_Event for now but in future expand to be more useful.
 - [x] Bring back fullscreen switching/support
    - [x] Port from `lispysnake2d` demo
    - [ ] Fix busted bgfx integration, ensure scaling ratio + track window changes
 - [ ] Time to mature the ECS design to something ... not immature.
        - Introduce integer-keyed entitys with an entity manager
        - Have component *types* as tags to construct supertypes (archetypes)
        - Group "same" archetypes to same-sized storage chunks for entity groups
        - Each supertype chunk is statically sized (value-width) and indexed by component type.
        - Each entity "group" (supertype chunk) is entity-indexed (int) storage
            - blob = entityManager.getComponentBlob(entity.supertype)
            - componentBlob = blob.getData!ComponentType()
        - No need for a runtime burst compiler. :P
        - Need advanced query matching.. by archetype and individual component. Should
          also work in a generator mode. This will automatically open up parallelism opportunities.
          Thus, don't look to *return* copies, instead use function pointers to act upon *discovered*
          data.
 - [ ] Allow loading/setting the textures per-sprite-data (instead of everything being Ship.png..)
 - [ ] Let's kill the stupid plane demo and focus on recreating the `lispysnake2d` demo.
 - [ ] Bring back parsers for Tiled, but let's just focus on ~~JSON now, not XML (future-maybe?)~~
   **Edit**: XML is more complete and can be sanity-checked, as well as offering space savings
   via Base64/ZLib decoding. JSON is an export, not a primary format. Fully support TMX/TSX.
 - [ ] Bring back parsers for Tilesheet sprites, to get a player on screen
 - [ ] Implement tilemap renderer with commonality to sprite renderer.
 - [ ] Reintroduce animation framework through the Context Job system (perhaps stage -> static class?)
 - [ ] Retain stateful approaches to per-level/stage concepts.
 - [ ] Stop relying on PNG assets + debugmode. Compile these assets and implement ResourceManager ZIPs
 - [ ] Fix crash on exit (unlink order of shader programs)
 - [ ] Optimise event handling (recycle event structures instead of keep constructing them)

Nice to have:

 - Chunked data processors. Right now we can run our units in parallel or series, and ensure
   there is a correct execution order for the system. However, we have chains that run in parallel
   that would need internal parallelisation. Thus, having some example chunked processors that can
   split the input data among a group of jobs is essential.


Things to remember:

 - Plane focus is dumb as it's a simple rotational dynamic X/Y positional sprite.
 - Our real game is more reliant on tiling, as well as psuedo-infinite spaces.
 - Inside is far more important than the outside, as it's technically more difficult.
 - We need detailed tilemaps for ship/station interiors, with per-tile animations, etc.
   This is much more easily realisable (word?) with the original not-ocarina demo.
