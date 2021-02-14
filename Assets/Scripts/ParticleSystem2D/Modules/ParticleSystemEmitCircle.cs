using Godot;
using ExtensionMethods.RandomMethods;

[Tool]
public class ParticleSystemEmitCircle : ParticleSystemModule {
    [Export]
    public float radius = 5f;
    [Export(PropertyHint.Range, "0,1")]
    public float radiusThickness = 1f;

    public override void InitParticle(ref ParticleSystem2D.Particle p, ParticleSystem2D.EmitParams emitParams) {
        FastNoiseLite r = particleSystem.noiseRandom;

        float a = GD.Randf() * Mathf.Pi * 2f;
        float o = Mathf.Lerp(
            1f - radiusThickness, 1f, GD.Randf()
        ) * radius;

        Vector2 off = Vector2.Right.Rotated(a) * o;
        Vector2 dir = off.Normalized();

        p.position += off;
        p.velocity = dir * p.velocity.Length();
    }
}