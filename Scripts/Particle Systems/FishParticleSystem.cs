using System.Collections.Generic;
using Godot;

public class FishParticleSystem : ParticleSystem
{
    Transform2D canvasTransform;
    Transform2D globalCanvasTransform;
    Rect2 viewportRect;

    [Export] public float fishSpeed = 64f;
    [Export] public float fishSize = 22f;
    [Export] public float steerSpeed = 8f;
    [Export] public int numGroups = 3;
    [Export] public float scanRadius = 128f;
    [Export] public float topForce = 8f;
    [Export] public float terrainForce = 16f;
    [Export] public float playerCollisionForce = 32f;
    [Export] public OpenSimplexNoise flowNoise;
    [Export] public float flowForce = 4f;

    public void Start()
    {
        for (int i = 0; i < numParticles; i++)
        {
            EmitParticle(null, false);
        }
    }

    protected override void UpdateSystem(float delta)
    {
        canvasTransform = GetCanvasTransform();
        globalCanvasTransform = canvasTransform.AffineInverse();
        viewportRect = GetViewportRect();

        base.UpdateSystem(delta);
    }

    protected override void InitParticle(Particle particle, Dictionary<string, object> overrideParams)
    {
        base.InitParticle(particle, overrideParams);

        Vector2 pos = new Vector2(GD.Randf(), 0f) * Planet.instance.totalSize;
        pos.y = GetY(pos.x);

        particle.persistent = true;
        particle.position = pos;

        while (particle.velocity == Vector2.Up || particle.velocity == Vector2.Down || particle.velocity == Vector2.Zero) {
            particle.velocity = Vector2.Right.Rotated(GD.Randf() * Mathf.Pi * 4f) * fishSpeed;
        }
        particle.size = Vector2.One * fishSize;

    }

    protected override void UpdateParticle(Particle particle, float delta)
    {
        base.UpdateParticle(particle, delta);
        OffsetOffScreen(particle);
        BoidBehaviour(particle, delta);

        Vector2 desiredSize = particle.startSize;
        if (particle.velocity.x > 0f) {
            desiredSize.y = Mathf.Abs(particle.startSize.y) * -1;
        }

        particle.size = particle.size.LinearInterpolate(desiredSize, Mathf.Clamp(delta * 2f, 0f, 1f));

        particle.rotation = particle.velocity.Angle();
        Color data = particle.customDataVertex;
        data.b = particle.idx;
        particle.customDataVertex = data;
    }

    private void BoidBehaviour(Particle particle, float delta) {
        Player player = Player.instance;

        Vector2 desiredDirection = particle.velocity.Normalized();
        Vector2 currDirection = desiredDirection;
        float terrainY = Planet.instance.terrain.GetTerrainY(particle.position.x);

        Vector2 playerOffset = (player.GlobalPosition - particle.position);

        /* Top and bottom collision avoidance */
        float topDistance = particle.position.y - GlobalPosition.y;
        float bottomDistance = terrainY - particle.position.y;

        float topT = Mathf.Max(1f - topDistance / scanRadius, 0f);
        float bottomT = Mathf.Max(1f - bottomDistance / scanRadius, 0f);

        desiredDirection += Vector2.Down * topT * topForce;
        desiredDirection += Vector2.Up * bottomT * terrainForce;
        /* ------------------------------ */

        if (flowNoise != null && topDistance > 0f) {
            float spacing = .1f;
            float noiseX = flowNoise.GetNoise2dv(particle.position + Vector2.Right * spacing) - flowNoise.GetNoise2dv(particle.position);
            float noiseY = flowNoise.GetNoise2dv(particle.position + Vector2.Up * spacing) - flowNoise.GetNoise2dv(particle.position);
            Vector2 n = new Vector2(noiseX, noiseY) / spacing;

            desiredDirection += n * flowForce;
        }

        /* Player collision avoidance only under water */
        if (topDistance > 0f) {
            float playerDistance = playerOffset.Length();
            Vector2 playerDirection = playerOffset / playerDistance;

            float playerT = Mathf.Max(1f - playerDistance / scanRadius, 0f);
            desiredDirection -= playerDirection * playerT * playerCollisionForce;
        }
        /* ------------------------------ */
        
        currDirection = currDirection.LinearInterpolate(
            desiredDirection.Normalized(), Mathf.Clamp(steerSpeed * delta, 0f, 1f)
        ).Normalized();
        particle.velocity = currDirection * fishSpeed;
    }

    private float GetY(float x)
    {
        return (float)GD.RandRange(GlobalPosition.y, Planet.instance.terrain.GetTerrainY(x));
    }

    private void OffsetOffScreen(Particle particle)
    {
        if (viewportRect.Size.x <= 1f) return;

        Vector2 pos = particle.position;
        Vector2 scCoord = canvasTransform.Xform(pos);

        bool offseted = false;
        bool offsetLeft = particle.velocity.x <= 0f;
        bool offsetRight = particle.velocity.x >= 0f;

        if (offsetLeft)
        {
            if (scCoord.x < -fishSize)
            {
                offseted = true;
                pos.x = globalCanvasTransform.origin.x + viewportRect.Size.x + fishSize;
            }
        }
        if (offsetRight)
        {
            if (scCoord.x > viewportRect.Size.x + fishSize)
            {
                offseted = true;
                pos.x = globalCanvasTransform.origin.x - fishSize;
            }
        }

        if (offseted) pos.y = GetY(pos.x);

        particle.position = pos;
    }

    /*protected override void DrawParticles()
    {
        base.DrawParticles();

        foreach (Particle particle in particles) {
            float spacing = .1f;
            float noiseX = flowNoise.GetNoise2dv(particle.position + Vector2.Right * spacing) - flowNoise.GetNoise2dv(particle.position);
            float noiseY = flowNoise.GetNoise2dv(particle.position + Vector2.Up * spacing) - flowNoise.GetNoise2dv(particle.position);
            Vector2 n = new Vector2(noiseX, noiseY) / spacing;

            DrawLine(particle.position, particle.position + n * flowForce * 4f, Colors.Green, 2f);
        }
    }*/
}