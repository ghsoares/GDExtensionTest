using System.Collections.Generic;
using Godot;

public class RaycastEmissionParticleSystem : ParticleSystem {
    float currentRate = 0f;

    [Export] public float maxEmissionRate = 64f;
    [Export] public float maxLength = 256f;
    [Export] public bool excludeParent = true;
    [Export] public float collisionSpread = 16f;
    [Export] public bool terrainSpread = true;
    [Export] public float bounciness = 1f;

    protected override void UpdateSystem(float delta)
    {
        base.UpdateSystem(delta);

        var spaceState = GetWorld2d().DirectSpaceState;

        Vector2 start = GlobalPosition;
        Vector2 end = start + GlobalTransform.BasisXform(direction) * maxLength;
        var exclude = new Godot.Collections.Array();
        if (excludeParent && rigidbody != null) {
            exclude.Add(rigidbody);
        }
        var ray = spaceState.IntersectRay(start, end, exclude);
        if (ray.Count > 0) {
            Vector2 colPoint = (Vector2)ray["position"];
            Vector2 normal = (Vector2)ray["normal"];

            float len = (colPoint - start).Length();
            float t = 1f - len / maxLength;

            currentRate += maxEmissionRate * delta * t;

            while (currentRate >= 1f) {
                colPoint += normal.Rotated(Mathf.Pi * .5f) * (float)GD.RandRange(-collisionSpread, collisionSpread) / 2f;
                if (terrainSpread) {
                    Terrain terrain = Planet.instance.terrain;
                    colPoint.y = terrain.GetTerrainY(colPoint.x);
                    normal = terrain.GetTerrainNormal(colPoint.x);
                }

                Dictionary<string, object> p = new Dictionary<string, object>();
                p["position"] = colPoint;
                p["direction"] = direction.Slide(normal).LinearInterpolate(direction.Bounce(normal), bounciness);

                EmitParticle(p);

                currentRate -= 1f;
            }
        }
    }
}