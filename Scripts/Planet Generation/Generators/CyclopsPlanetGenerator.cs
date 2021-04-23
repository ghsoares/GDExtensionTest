using Godot;

public class CyclopsPlanetGenerator : PlanetGenerator {
    ShaderMaterial fogMaterial;
    ShaderMaterial sandMaterial;
    Grass sand;
    CyclopsBoss boss;

    public override void Configure() {
        base.Configure();

        ColorRect fog = new ColorRect();
        sand = new Grass();
        boss = ResourceLoader.Load<PackedScene>("res://Scenes/Bosses/CyclopsBoss.tscn").Instance() as CyclopsBoss;

        fogMaterial = ResourceLoader.Load<ShaderMaterial>("res://Materials/Cyclops/Fog.tres");
        sandMaterial = ResourceLoader.Load<ShaderMaterial>("res://Materials/Cyclops/Sand.tres");

        terrain.Material = ResourceLoader.Load<ShaderMaterial>("res://Materials/Cyclops/Terrain.tres");
        terrain.heightOffset = 256f;
        terrain.height = 100f;

        fog.Material = fogMaterial;
        fog.RectSize = planet.totalSize;

        sand.planet = planet;
        sand.Material = sandMaterial;
        sand.height = 4f;

        AddChild(boss);
        AddChild(sand);

        terrain.Raise();
        platformPlacer.Raise();

        platformPlacer.enabled = false;

        AddChild(fog);
    }

    public override void Generate()
    {
        base.Generate();
        planet.windSpeed = Vector2.Right * 16f;

        sand.Create();

        fogMaterial.SetShaderParam("windSpeed", planet.windSpeed.x);
    }

    public override void _PhysicsProcess(float delta)
    {
        base._PhysicsProcess(delta);

        fogMaterial.SetShaderParam("playerTransform", Player.instance.GlobalTransform);
    }
}