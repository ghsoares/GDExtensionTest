using Godot;
using System;
using System.Collections.Generic;

public class PlanetGenerator : Control {
    public Planet planet {get; set;}
    protected Terrain terrain {get; set;}
    protected PlatformPlacer platformPlacer {get; set;}

    public virtual void Configure() {
        terrain = new Terrain();
        platformPlacer = new PlatformPlacer();

        planet.terrain = terrain;
        planet.platformPlacer = platformPlacer;

        terrain.noise = new OpenSimplexNoise {Period = 200f, Octaves = 1};
        terrain.Material = ResourceLoader.Load<ShaderMaterial>("res://Materials/Terrain.tres");
        terrain.planet = planet;

        platformPlacer.planet = planet;

        planet.gravity = Vector2.Down * 49f;

        AddChild(planet.terrain);
        AddChild(planet.platformPlacer);
    }

    public virtual void Generate() {
        RectSize = planet.totalSize;

        planet.windSpeed = Vector2.Right * 16f;

        platformPlacer.Scatter();
        terrain.Generate();
    }
}