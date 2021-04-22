using Godot;
using System;
using System.Collections.Generic;

public class PlayerGroundParticleSystem : ParticleSystem
{
    float currentRate = 0f;
    List<Node> ignoreObjects = new List<Node>();
    Vector2 currentHitPoint;

    public Godot.Collections.Dictionary currentRayHit {get; private set;}

    [Export] public float maxRate = 64f;
    [Export] public float maxRange = 24f;
    [Export] public float hitSpread = 16f;
    [Export] public Vector2 sizeRange = Vector2.One * 4f;
    [Export] public Vector2 lifeRange = Vector2.One * 1f;
    [Export] public Vector2 velocityRange = new Vector2(16f, 32f);

    public void AddIgnoreObject(Node node) {
        if (!ignoreObjects.Contains(node)) ignoreObjects.Add(node);
    }

    protected override void EmissionProcess(float delta)
    {
        base.EmissionProcess(delta);
        Vector2 from = GlobalPosition;
        Vector2 to = from + GlobalTransform.y * maxRange;

        currentRayHit = spaceState.IntersectRay(
            from, to, new Godot.Collections.Array(ignoreObjects)
        );
        if (currentRayHit.Count > 0) {
            currentHitPoint = (Vector2)currentRayHit["position"];
            float t = (currentHitPoint - from).Length() / maxRange;
            currentRate += (1f - t) * maxRate * delta;
        }

        while (currentRate >= 1f) {
            EmitParticle();
            currentRate -= 1f;
        }
    }

    protected override void InitParticle(Particle particle, Dictionary<string, object> overrideParams)
    {
        base.InitParticle(particle, overrideParams);
        Vector2 pos = currentHitPoint;
        pos += Vector2.Right * Mathf.Lerp(-hitSpread, hitSpread, GD.Randf()) * .5f;
        pos.y = Planet.instance.terrain.GetTerrainY(pos.x) + Mathf.Max(sizeRange.x, sizeRange.y) * .5f;
        Vector2 normal = Planet.instance.terrain.GetTerrainNormal(pos.x);

        particle.position = pos;
        particle.velocity += 
            GlobalTransform.y.Bounce(normal) * 
            Mathf.Lerp(velocityRange.x, velocityRange.y, GD.Randf());
        
        particle.size *= (float)GD.RandRange(sizeRange.x, sizeRange.y);
        particle.life *= (float)GD.RandRange(lifeRange.x, lifeRange.y);
    }
}
