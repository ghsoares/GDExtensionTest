using Godot;
using System;

public class TerrainCollision : StaticBody2D {
    public Planet planet;
    public Terrain terrain;

    public void Generate() {
        CollisionPolygon2D col = new CollisionPolygon2D();
        AddChild(col);

        float resolution = terrain.collisionResolution;
        int numPoints = Mathf.CeilToInt(planet.size.x * resolution);

        Vector2[] points = new Vector2[numPoints + 2];

        for (int i = 0; i < numPoints; i++) {
            float x = i / resolution;
            x = Mathf.Min(x, planet.size.x);
            float y = terrain.GetTerrainY(x);

            points[i] = new Vector2(x, y);
        }

        points[numPoints + 0] = planet.size;
        points[numPoints + 1] = new Vector2(0f, planet.size.y);

        col.Polygon = points;
    }
}