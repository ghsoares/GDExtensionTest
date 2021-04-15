using Godot;
using System;
using System.Diagnostics;

public class Planet : Control
{
    public static Planet instance;
    public bool generating {get; private set;}

    public PlanetGenerator generator {get; set;}
    public Terrain terrain {get; set;}
    public PlatformPlacer platformPlacer {get; set;}

    public Vector2 windSpeed {get; set;}

    public Player player {get; set;}
    public GameCamera gameCamera {get; set;}

    public Vector2 gravity {get; set;}

    [Export] public Vector2 size;

    public Planet() {
        instance = this;
    }

    public override void _Ready() {
        Generate();
    }

    public void Generate() {
        Stopwatch stopwatch = new Stopwatch();
        stopwatch.Start();

        if (generator != null) {
            generator.QueueFree();
        }
        if (player == null) {
            player = GD.Load<PackedScene>("res://Scenes/Player.tscn").Instance() as Player;
            AddChild(player);
        }
        if (gameCamera == null) {
            gameCamera = new GameCamera();
            AddChild(gameCamera);
        }

        generator = new EarthPlanetGenerator();
        generator.planet = this;

        AddChild(generator);
        generator.Configure();

        generating = true;

        Hide();

        RemoveChild(player);

        generator.Generate();

        player.Position = new Vector2(2048, 32);
        player.Position = new Vector2(2048, 512f);
        /*player.Position = new Vector2(
            player.Position.x, terrain.GetTerrainY(player.Position.x) - 64f
        );*/

        player.RequestReady();
        AddChild(player);

        generator.Raise();

        Show();

        generating = false;

        stopwatch.Stop();
        TimeSpan elapsed = stopwatch.Elapsed;

        Console.WriteLine(
            $"Planet Generation Time: {elapsed.Milliseconds} Ms"
        );
    }
}
