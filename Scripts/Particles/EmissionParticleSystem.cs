using Godot;
using ParticleSystem;

[Tool]
public class EmissionParticleSystem : ParticleSystem3D
{
    protected float currentEmitTime { get; set; }

    [Export] public float rate = 16f;

    protected override void EmissionProcess(float delta)
    {
        currentEmitTime += rate * delta;
        while (currentEmitTime >= 1f)
        {
            currentEmitTime -= 1f;
            EmitParticle();
        }
    }
}
