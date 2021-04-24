using Godot;
using System;

public class PlanetGenerator : Node
{
    public Planet planet {get; set;}
    protected Terrain terrain {get; set;}

    public virtual void Configure() {
        terrain = ResourceLoader.Load<PackedScene>("res://Scenes/Planet/Terrain.tscn").Instance() as Terrain;

        planet.terrain = terrain;

        terrain.noise = new OpenSimplexNoise {Period = 200f, Octaves = 1};
        terrain.material = ResourceLoader.Load<ShaderMaterial>("res://Materials/Terrain.tres");
        terrain.planet = planet;

        planet.gravity = Vector2.Down * 49f;

        AddChild(terrain);
    }

    public virtual void Generate() {
        planet.windSpeed = Vector2.Right * 16f;

        terrain.Generate();
    }
}
