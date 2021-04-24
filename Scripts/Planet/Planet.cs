using Godot;
using System;

public class Planet : Spatial
{
    public static Planet instance;
    public bool generating {get; private set;}

    public PlanetGenerator generator {get; set;}
    public Terrain terrain {get; set;}

    public Vector2 windSpeed {get; set;}
    public Vector2 gravity {get; set;}
    public Vector2 totalSize {get; set;}

    [Export] public Vector2 size = new Vector2(4096f, 2048f);
    [Export] public float margin = 256f;

    public Planet() {
        instance = this;
    }

    public override void _Ready() {
        Generate();
    }

    public void Generate() {
        totalSize = size + Vector2.One * margin;

        if (generator != null) {
            generator.QueueFree();
        }

        generator = new PlanetGenerator();
        generator.planet = this;

        AddChild(generator);
        generator.Configure();

        generating = true;

        Hide();

        generator.Generate();

        Show();

        generating = false;
    }
}
