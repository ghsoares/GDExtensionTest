using Godot;
using System;

public class PlanetGenerator : Control {
    public Planet planet;

    public virtual void Configure() {
        Terrain terrain = new Terrain();
        PlatformPlacer platformPlacer = new PlatformPlacer();

        planet.terrain = terrain;
        planet.platformPlacer = platformPlacer;

        terrain.noise = new OpenSimplexNoise {Period = 200f, Octaves = 1};
        terrain.Material = ResourceLoader.Load<ShaderMaterial>("res://Materials/Terrain.tres");
        terrain.planet = planet;

        platformPlacer.planet = planet;

        planet.gravity = Vector2.Down * 49f;
    }

    public virtual void Generate() {
        RectSize = planet.size;

        AddChild(planet.terrain);
        AddChild(planet.platformPlacer);
        planet.platformPlacer.Scatter();
        planet.terrain.Generate();
    }
}