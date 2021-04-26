using System;
using Godot;
using ParticleSystem;

[Tool]
public class BurstParticleSystem : ParticleSystem3D
{
    protected float currentEmitTime { get; set; }

    [Export] public float amountPerc = .25f;
    [Export] public float rate = 1f;

    protected override void EmissionProcess(float delta)
    {
        currentEmitTime += rate * delta;
        while (currentEmitTime >= 1f)
        {
            currentEmitTime -= 1f;
            Emit();
        }
    }

    public virtual void Emit()
    {
        int amnt = Mathf.FloorToInt(amount * amountPerc);
        for (int i = 0; i < amnt; i++)
        {
            EmitParticle();
        }
    }
}
