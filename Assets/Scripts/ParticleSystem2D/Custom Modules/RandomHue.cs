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
        float rH = GD.Randf() * randomHue;
        float rS = GD.Randf() * randomSaturation;
        float rV = GD.Randf() * randomValue;

        Color c = p.baseColor;
        c.h += rH;
        c.s += rS;
        c.v += rV;

        p.baseColor = c;
        p.color = c;
    }
}
