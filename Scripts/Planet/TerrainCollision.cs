using Godot;
using System;

public class TerrainCollision : StaticBody2D
{
    private Terrain terrain {get; set;}

    public CollisionPolygon2D col {get; private set;}

    public override void _Ready()
    {
        terrain = GetParent<Terrain>();
        col = GetNode<CollisionPolygon2D>("Col");
    }

    public void Generate() {
        Planet planet = terrain.planet;

        float resolution = terrain.collisionResolution;
        int numPoints = Mathf.CeilToInt(planet.totalSize.x * resolution);

        Vector2[] points = new Vector2[numPoints + 2];

        for (int i = 0; i < numPoints; i++) {
            float x = i / resolution;
            x = Mathf.Min(x, planet.totalSize.x);
            float y = terrain.GetTerrainY(x);

            points[i] = new Vector2(x, y);
        }

        points[numPoints + 0] = planet.totalSize;
        points[numPoints + 1] = new Vector2(0f, planet.totalSize.y);

        col.Polygon = points;
    }
}
