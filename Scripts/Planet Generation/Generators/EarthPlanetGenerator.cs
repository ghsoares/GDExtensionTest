using System.Collections.Generic;
using Godot;

public class EarthPlanetGenerator : PlanetGenerator {
    List<LiquidBody> liquidBodies {get; set;}
    Grass grass;
    Control liquidBodiesRoot;

    public override void Configure() {
        base.Configure();

        terrain.Material = ResourceLoader.Load<ShaderMaterial>("res://Materials/Earth/Terrain.tres");

        grass = new Grass();
        liquidBodies = new List<LiquidBody>();
        liquidBodiesRoot = new Control();

        grass.planet = planet;
        grass.resolution = terrain.visualResolution;
        grass.height = 16f;
        grass.Material = ResourceLoader.Load<ShaderMaterial>("res://Materials/Earth/Grass.tres");

        liquidBodiesRoot.RectSize = planet.size;

        AddChild(grass);
        AddChild(liquidBodiesRoot);

        terrain.Raise();
        platformPlacer.Raise();
    }

    public override void Generate()
    {
        base.Generate();

        grass.Create();

        List<Rect2> valleys = terrain.valleys;

        foreach (Rect2 r in valleys) {
            if (GD.Randf() > .5f) continue;

            Rect2 extentedR = r.GrowIndividual(1f, -1f, 1f, 1f);

            extentedR.Size = new Vector2(
                Mathf.Floor(r.Size.x),
                Mathf.Floor(r.Size.y)
            );

            LiquidBody liquid = new LiquidBody();

            liquid.windStrength = Mathf.Abs(planet.windSpeed.x);
            liquid.Material = GD.Load<ShaderMaterial>("res://Materials/Earth/Liquid.tres");
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