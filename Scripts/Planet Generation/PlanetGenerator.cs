using Godot;
using System;

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
    }
}