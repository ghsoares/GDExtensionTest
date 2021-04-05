using System.Collections.Generic;
using Godot;
using ExtensionMethods.DictionaryExtensions;

public class EmissionParticleSystem : ParticleSystem {
    protected float currentRate = 0f;

    [Export] public float emissionRate = 1f;

    protected override void UpdateSystem(float delta)
    {
        base.UpdateSystem(delta);

        EmissionProcess(delta);
    }

    protected virtual void EmissionProcess(float delta) {
        currentRate += delta * emissionRate;
        while (currentRate >= 1f) {
            EmitParticle();
            currentRate -= 1f;
        }
    }
}