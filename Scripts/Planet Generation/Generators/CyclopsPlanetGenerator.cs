using Godot;

public class CyclopsPlanetGenerator : PlanetGenerator {
    ShaderMaterial fogMaterial;
    ShaderMaterial sandMaterial;
    Line2D sand;
    CyclopsBoss boss;

    public override void Configure() {
        base.Configure();

        ColorRect fog = new ColorRect();
        sand = new Line2D();
        boss = ResourceLoader.Load<PackedScene>("res://Scenes/Bosses/CyclopsBoss.tscn").Instance() as CyclopsBoss;

        fogMaterial = ResourceLoader.Load<ShaderMaterial>("res://Materials/Cyclops/Fog.tres");
        sandMaterial = ResourceLoader.Load<ShaderMaterial>("res://Materials/Cyclops/Sand.tres");

        terrain.Material = ResourceLoader.Load<ShaderMaterial>("res://Materials/Cyclops/Terrain.tres");
        terrain.heightOffset = 256f;
        terrain.height = 100f;

        fog.Material = fogMaterial;
        fog.RectSize = planet.totalSize;

        sand.Material = sandMaterial;

        AddChild(boss);
        AddChild(sand);

        terrain.Raise();
        platformPlacer.Raise();

        AddChild(fog);
    }

    public override void Generate()
    {
        base.Generate();
        planet.windSpeed = Vector2.Right * 16f;

        GenerateSand();

        fogMaterial.SetShaderParam("windSpeed", planet.windSpeed.x);
    }

    private void GenerateSand() {
        int numPoints = Mathf.CeilToInt(planet.totalSize.x * .25f);

        sand.ClearPoints();
        float totalSize = 0f;
        Vector2 prevP = new Vector2(0f, terrain.GetTerrainY(0f));

        for (int i = numPoints-1; i >= 0; i--) {
            float x = i / .25f;
            float y = terrain.GetTerrainY(x);
            Vector2 p = new Vector2(x, y);
            sand.AddPoint(p);

            float l = (p - prevP).Length();
            totalSize += l;
            prevP = p;
        }

        sand.Width = 4f * 2f;
        sand.DefaultColor = Colors.White;
        sand.TextureMode = Line2D.LineTextureMode.Stretch;

        if (sandMaterial != null) {
            sandMaterial.SetShaderParam("size", new Vector2(totalSize, 4f));
        }
    }

    public override void _PhysicsProcess(float delta)
    {
        base._PhysicsProcess(delta);

        fogMaterial.SetShaderParam("playerTransform", Player.instance.GlobalTransform);
    }
}