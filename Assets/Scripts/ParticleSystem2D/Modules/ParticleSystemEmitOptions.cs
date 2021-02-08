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
    public Color startColor;
    [Export]
    public Gradient randomColorGradient;

    public override void InitParticle(ref ParticleSystem2D.Particle p, ParticleSystem2D.EmitParams emitParams)
    {
        float speed = particleSystem.random.NextFloat(minSpeed, maxSpeed);
        float lifetime = particleSystem.random.NextFloat(minLifetime, maxLifetime);
        float size = particleSystem.random.NextFloat(minSize, maxSize);
        float rotation = particleSystem.random.NextFloat(minRotation, maxRotation);

        Color color = startColor;

        if (randomColorGradient != null)
        {
            color = randomColorGradient.Interpolate(particleSystem.random.NextFloat());
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