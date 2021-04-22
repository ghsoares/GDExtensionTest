using System.Collections.Generic;
using Godot;

public class PlatformPlacer : Control
{
    public Planet planet;
    public Platform[] platforms { get; set; }
    public bool enabled {get; set;}

    public Vector2 spacingRange = new Vector2(32f, 64f);

    public PlatformPlacer() {
        enabled = true;
    }

    public override void _Ready()
    {
        RectSize = planet.totalSize;
    }

    public override void _PhysicsProcess(float delta)
    {
        Visible = enabled;
    }

    public void Scatter()
    {
        //PackedScene platformScene = GD.Load<PackedScene>("res://Scenes/Platform.tscn");
        PackedScene platformScene = ResourceLoader.Load<PackedScene>("res://Scenes/Platform.tscn");
        platforms = new Platform[5];

        float spacing = (float)GD.RandRange(spacingRange.x, spacingRange.y);

        for (int i = 0; i < 5; i++)
        {
            Platform platform = platformScene.Instance() as Platform;
            platform.Position = new Vector2(spacing, 0f);

            platforms[i] = platform;

            spacing += (float)GD.RandRange(spacingRange.x, spacingRange.y);

            AddChild(platform);
        }

        List<float> scoreMultipliers = new List<float>(new float[] { 1f, 2f, 3f, 4f, 5f });

        for (int i = 0; i < 5; i++)
        {
            Platform platform = platforms[i];
            Vector2 pos = platform.GlobalPosition;

            pos.x = (pos.x / spacing) * planet.totalSize.x;
            pos.x = Mathf.Floor(pos.x);

            platform.GlobalPosition = pos;

            pos.y = planet.terrain.GetTerrainY(pos.x);

            platform.GlobalPosition = pos;

            int idx = (int)(GD.Randi() % scoreMultipliers.Count);
            platform.scoreMultiplier = scoreMultipliers[idx];
            scoreMultipliers.Remove(platform.scoreMultiplier);

            platform.InitControl();
        }
    }

    public Platform GetNearestPlatform(float posX)
    {
        if (!enabled) return null;
        Platform nearest = platforms[0];
        float nearestDst = Mathf.Abs(nearest.GlobalPosition.x - posX);

        for (int i = 1; i < 5; i++)
        {
            Platform plat = platforms[i];
            float dst = Mathf.Abs(plat.GlobalPosition.x - posX);

            if (dst < nearestDst)
            {
                nearest = plat;
                nearestDst = dst;
            }
        }

        return nearest;
    }


}