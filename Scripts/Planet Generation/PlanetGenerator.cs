using Godot;
using System;
using System.Collections.Generic;

public class PlanetGenerator : Control {
    public Planet planet;
    Grass grass;

    public virtual void Configure() {
        Terrain terrain = new Terrain();
        PlatformPlacer platformPlacer = new PlatformPlacer();
        grass = new Grass();

        planet.terrain = terrain;
        planet.platformPlacer = platformPlacer;

        terrain.noise = new OpenSimplexNoise {Period = 200f, Octaves = 1};
        terrain.Material = ResourceLoader.Load<ShaderMaterial>("res://Materials/Terrain.tres");
        terrain.planet = planet;

        platformPlacer.planet = planet;

        grass.planet = planet;
        grass.resolution = terrain.visualResolution;
        grass.height = 16f;
        grass.Material = ResourceLoader.Load<ShaderMaterial>("res://Materials/Grass.tres");

        planet.gravity = Vector2.Down * 49f;
    }

    public virtual void Generate() {
        RectSize = planet.size;

        AddChild(grass);
        AddChild(planet.terrain);
        AddChild(planet.platformPlacer);
        planet.platformPlacer.Scatter();
        planet.terrain.Generate();
        grass.Create();

        List<Rect2> valleys = planet.terrain.valleys;

        Rect2 r = valleys[valleys.Count / 2];
        r = r.GrowIndividual(1f, -1f, 1f, 1f);

        r.Size = new Vector2(
            Mathf.Floor(r.Size.x),
            Mathf.Floor(r.Size.y)
        );

        ShaderMaterial liquidMaterial = ResourceLoader.Load<ShaderMaterial>("res://Materials/Liquid.tres");
        LiquidBody liquid = new LiquidBody();
        liquid.Material = liquidMaterial;
        liquid.RectPosition = r.Position;
        liquid.RectSize = r.Size;

        AddChild(liquid);
    }
}