using Godot;
using ExtensionMethods.RandomMethods;

[Tool]
public class ParticleSystemEmitOptions : ParticleSystemModule
{
    [Export]
    public float minLifetime = 1f, maxLifetime = 1f;
    [Export]
    public float minSpeed = 5f, maxSpeed = 5f;
    [Export]
    public float minSize = 1f, maxSize = 1f;
    [Export]
    public float minRotation = 0f, maxRotation = 0f;
    [Export]
    public Color startColor = Colors.White;
    [Export]
    public Gradient randomColorGradient;

    public override void InitParticle(ref ParticleSystem2D.Particle p, ParticleSystem2D.EmitParams emitParams)
    {
        FastNoiseLite r = particleSystem.noiseRandom;

        float speed = Mathf.Lerp(
            minSpeed, maxSpeed, r.GetNoiseUnsigned(p.idx, 0)
        );
        float lifetime = Mathf.Lerp(
            minLifetime, maxLifetime, r.GetNoiseUnsigned(p.idx, 1)
        );
        float size = Mathf.Lerp(
            minSize, maxSize, r.GetNoiseUnsigned(p.idx, 2)
        );
        float rotation = Mathf.Lerp(
            minRotation, maxRotation, r.GetNoiseUnsigned(p.idx, 3)
        );

        Color color = startColor;

        if (randomColorGradient != null)
        {
            color = randomColorGradient.Interpolate(r.GetNoiseUnsigned(p.idx, 4));
        }

        p.position = emitParams.position;

        p.velocity = Vector2.Right * speed;

        p.lifetime = lifetime;
        p.currentLife = lifetime;

        p.rotation = rotation;

        p.baseSize = size;
        p.size = size;

        p.baseColor = color;
        p.color = color;
    }
}