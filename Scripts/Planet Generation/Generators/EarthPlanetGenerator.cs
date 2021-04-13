using System.Collections.Generic;
using Godot;

public class EarthPlanetGenerator : PlanetGenerator {
    Grass grass;
    Line2D clouds;
    ShaderMaterial cloudsShaderMaterial;
    List<LiquidBody> liquidBodies;
    Control liquidBodiesRoot;

    public override void Configure() {
        base.Configure();

        terrain.Material = ResourceLoader.Load<ShaderMaterial>("res://Materials/Earth/Terrain.tres");

        grass = new Grass();
        clouds = new Line2D();

        liquidBodies = new List<LiquidBody>();
        liquidBodiesRoot = new Control();

        grass.planet = planet;
        grass.resolution = terrain.visualResolution;
        grass.height = 16f;
        grass.Material = ResourceLoader.Load<ShaderMaterial>("res://Materials/Earth/Grass.tres");


        cloudsShaderMaterial = ResourceLoader.Load<ShaderMaterial>("res://Materials/Earth/Clouds.tres");
        clouds.Material = cloudsShaderMaterial;
        clouds.DefaultColor = Colors.White;
        clouds.Width = 256f;
        clouds.TextureMode = Line2D.LineTextureMode.Stretch;

        liquidBodiesRoot.RectSize = planet.size;

        AddChild(grass);
        AddChild(liquidBodiesRoot);

        terrain.Raise();
        platformPlacer.Raise();

        //AddChild(clouds);
    }

    public override void Generate()
    {
        base.Generate();

        grass.Create();

        clouds.AddPoint(new Vector2(0f, 256f));
        clouds.AddPoint(new Vector2(planet.size.x, 256f));

        cloudsShaderMaterial.SetShaderParam("lineSize", new Vector2(planet.size.x, clouds.Width));

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