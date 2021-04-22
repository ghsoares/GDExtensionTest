using Godot;
using System;

public class MarsPlanetGenerator : PlanetGenerator
{
    ShaderMaterial fogMaterial;

    public override void Configure() {
        base.Configure();
        ColorRect fog = new ColorRect();

        fogMaterial = ResourceLoader.Load<ShaderMaterial>("res://Materials/Mars/Fog.tres");

        terrain.noise.Octaves = 3;
        terrain.noise.Persistence = .5f;
        terrain.noise.Lacunarity = 2.5f;
        terrain.Material = ResourceLoader.Load<ShaderMaterial>("res://Materials/Mars/Terrain.tres");

        fog.Material = fogMaterial;
        fog.RectSize = planet.totalSize;

        AddChild(fog);
    }

    public override void Generate()
    {
        base.Generate();

        fogMaterial.SetShaderParam("windSpeed", planet.windSpeed.x);
    }

    public override void _PhysicsProcess(float delta)
    {
        base._PhysicsProcess(delta);

        fogMaterial.SetShaderParam("playerTransform", Player.instance.GlobalTransform);
    }
}
