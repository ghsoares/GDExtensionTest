using Godot;
using System;
using ExtensionMethods.RandomMethods;

[Tool]
public class RandomHue : ParticleSystemModule
{
    [Export(PropertyHint.Range, "0,1")]
    public float randomHue = .2f;
    [Export(PropertyHint.Range, "0,1")]
    public float randomSaturation = .2f;
    [Export(PropertyHint.Range, "0,1")]
    public float randomValue = .2f;

    public override void InitParticle(ref ParticleSystem2D.Particle p, ParticleSystem2D.EmitParams emitParams) {
        FastNoiseLite r = particleSystem.noiseRandom;
        float rH = r.GetNoiseUnsigned(p.idx, 0) * randomHue;
        float rS = r.GetNoiseUnsigned(p.idx, 1) * randomSaturation;
        float rV = r.GetNoiseUnsigned(p.idx, 2) * randomValue;

        Color c = p.baseColor;
        c.h += rH;
        c.s += rS;
        c.v += rV;

        p.baseColor = c;
        p.color = c;
    }
}
