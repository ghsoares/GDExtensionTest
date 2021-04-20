using Godot;

public class AquantisPlanetGenerator : PlanetGenerator {
    Grass algae;
    FishParticleSystem fishes;
    LiquidBody liquid;
    Control liquidBodiesRoot;

    public override void Configure() {
        base.Configure();

        terrain.Material = ResourceLoader.Load<ShaderMaterial>("res://Materials/Aquantis/Terrain.tres");
        terrain.heightOffset = 50f;
        terrain.height = 256f;

        algae = new Grass();
        liquidBodiesRoot = new Control();

        fishes = ResourceLoader.Load<PackedScene>("res://Scenes/Fishes.tscn").Instance() as FishParticleSystem;

        algae.planet = planet;
        algae.resolution = terrain.visualResolution;
        algae.height = 32f;
        algae.Material = ResourceLoader.Load<ShaderMaterial>("res://Materials/Aquantis/Algae.tres");

        liquidBodiesRoot.RectSize = planet.totalSize;

        AddChild(algae);
        AddChild(fishes);
        AddChild(liquidBodiesRoot);

        terrain.Raise();
        platformPlacer.Raise();
    }

    public override void Generate()
    {
        base.Generate();
        planet.windSpeed = Vector2.Right * 16f;

        algae.Create();

        Vector2 floodMin = new Vector2(0f, terrain.minY);
        Vector2 floodMax = new Vector2(planet.totalSize.x, terrain.maxY);
        Rect2 floodRect = new Rect2(floodMin, floodMax - floodMin)
            .GrowIndividual(1f, 256f, 1f, 1f);
        
        fishes.GlobalPosition = new Vector2(0f, floodRect.Position.y);
        fishes.Start();

        liquid = new LiquidBody();

        liquid.windStrength = Mathf.Abs(planet.windSpeed.x);
        liquid.Material = ResourceLoader.Load<ShaderMaterial>("res://Materials/Aquantis/Liquid.tres");
        liquid.RectPosition = floodRect.Position;
        liquid.RectSize = floodRect.Size;

        liquidBodiesRoot.AddChild(liquid);

        liquidBodiesRoot.Hide();
        fishes.Hide();

        /*foreach (Rect2 r in valleys) {
            if (GD.Randf() > .5f) continue;

            Rect2 extentedR = r.GrowIndividual(1f, -1f, 1f, 1f);

            extentedR.Size = new Vector2(
                Mathf.Floor(r.Size.x),
                Mathf.Floor(r.Size.y)
            );

            LiquidBody liquid = new LiquidBody();

            liquid.windStrength = Mathf.Abs(planet.windSpeed.x);
            liquid.Material = GD.Load<ShaderMaterial>("res://Materials/Liquid.tres");
            liquid.RectPosition = extentedR.Position;
            liquid.RectSize = extentedR.Size;

            liquidBodiesRoot.AddChild(liquid);

            liquidBodies.Add(liquid);
        }*/
    }

    public override void _PhysicsProcess(float delta)
    {
        base._PhysicsProcess(delta);

        if (liquid != null) liquid.windOffset -= planet.windSpeed.x * delta * 8f;
    }
}