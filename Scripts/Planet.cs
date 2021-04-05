using Godot;
using System;

public class Planet : Control
{
    public static Planet instance;
    public bool generating {get; private set;}

    public PlanetGenerator generator {get; set;}
    public Terrain terrain {get; set;}
    public PlatformPlacer platformPlacer {get; set;}

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

    public override void _PhysicsProcess(float delta) {
        if (Input.IsActionJustPressed("ui_select")) {
            Generate();
        }
    }

    public void Generate() {
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

        generator = new PlanetGenerator();
        generator.planet = this;

        AddChild(generator);
        generator.Configure();

        generating = true;

        Hide();
        RemoveChild(player);

        generator.Generate();

        player.Position = new Vector2(2048, 64);
        player.Position = new Vector2(
            player.Position.x, terrain.GetTerrainY(player.Position.x) - 64f
        );

        player.RequestReady();
        AddChild(player);
        Show();

        generating = false;
    }
}
