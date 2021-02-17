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
        float speed = Mathf.Lerp(
            minSpeed, maxSpeed, GD.Randf()
        );
        float lifetime = Mathf.Lerp(
            minLifetime, maxLifetime, GD.Randf()
        );
        float size = Mathf.Lerp(
            minSize, maxSize, GD.Randf()
        );
        float rotation = Mathf.Lerp(
            minRotation, maxRotation, GD.Randf()
        );

        Color color = startColor;

        if (randomColorGradient != null)
        {
            color = randomColorGradient.Interpolate(GD.Randf());
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