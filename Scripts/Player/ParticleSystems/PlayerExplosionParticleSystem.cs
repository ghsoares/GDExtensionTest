using System.Collections.Generic;
using Godot;

public class PlayerExplosionParticleSystem : BurstParticleSystem {
    [Export] public OpenSimplexNoise spreadNoise;
    [Export] public Vector2 velocityMultiplyRange = new Vector2(.25f, 1f);
    [Export(PropertyHint.ExpEasing)] public float noiseEaseCurve = -2f;

    protected override void InitParticle(Particle particle, Dictionary<string, object> overrideParams)
    {
        base.InitParticle(particle, overrideParams);
        float angle = Mathf.Rad2Deg(particle.velocity.Angle());
        float n = spreadNoise.GetNoise1d(angle) * .5f + .5f;

        n = Mathf.Ease(n, noiseEaseCurve);

        particle.velocity *= Mathf.Lerp(velocityMultiplyRange.x, velocityMultiplyRange.y, n);
    }
}