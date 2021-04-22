using System.Collections.Generic;
using Godot;

public class EarthPlanetGenerator : PlanetGenerator {
    Grass grass;
    Clouds clouds;
    ShaderMaterial cloudsNoiseMaterial;
    ShaderMaterial cloudsRenderMaterial;
    List<LiquidBody> liquidBodies;
    Control liquidBodiesRoot;

    public override void Configure() {
        base.Configure();

        terrain.Material = ResourceLoader.Load<ShaderMaterial>("res://Materials/Earth/Terrain.tres");

        grass = new Grass();
        clouds = new Clouds();

        liquidBodies = new List<LiquidBody>();
        liquidBodiesRoot = new Control();

        grass.planet = planet;
        grass.resolution = terrain.visualResolution;
        grass.height = 16f;
        grass.Material = ResourceLoader.Load<ShaderMaterial>("res://Materials/Earth/Grass.tres");

        cloudsNoiseMaterial = ResourceLoader.Load<ShaderMaterial>("res://Materials/Earth/CloudsNoise.tres");
        cloudsRenderMaterial = ResourceLoader.Load<ShaderMaterial>("res://Materials/Earth/CloudsRendering.tres");
        clouds.cloudsNoiseMaterial = cloudsNoiseMaterial;
        clouds.cloudsRenderingMaterial = cloudsRenderMaterial;
        clouds.RectPosition = Vector2.Down * 64f;

        liquidBodiesRoot.RectSize = planet.totalSize;

        AddChild(grass);
        AddChild(liquidBodiesRoot);

        terrain.Raise();
        platformPlacer.Raise();

        AddChild(clouds);
    }

    public override void Generate()
    {
        base.Generate();

        grass.Create();
        clouds.Setup();

        List<Rect2> valleys = terrain.valleys;

        ShaderMaterial mat = ResourceLoader.Load<ShaderMaterial>("res://Materials/Earth/Liquid.tres");

        foreach (Rect2 r in valleys) {
            if (GD.Randf() > .5f) continue;

            Rect2 extentedR = r.GrowIndividual(1f, -1f, 1f, 1f);

            extentedR.Size = new Vector2(
                Mathf.Floor(r.Size.x),
                Mathf.Floor(r.Size.y)
            );

            LiquidBody liquid = new LiquidBody();

            liquid.windStrength = Mathf.Abs(planet.windSpeed.x);
            liquid.Material = mat.Duplicate() as ShaderMaterial;
            liquid.RectPosition = extentedR.Position;
            liquid.RectSize = extentedR.Size;

            liquidBodiesRoot.AddChild(liquid);

            liquidBodies.Add(liquid);
        }
    }

    public override void _PhysicsProcess(float delta)
    {
        base._PhysicsProcess(delta);

        foreach (LiquidBody liquid in liquidBodies) {
            liquid.windOffset -= planet.windSpeed.x * delta * 8f;
        }
    }
}