using System.Collections.Generic;
using Godot;

public class SubParticleSystemEmitter : Node2D
{
    public List<ParticleSystem> systems { get; private set; }

    public override void _Ready()
    {
        systems = new List<ParticleSystem>();

        foreach (Node n in GetChildren())
        {
            if (n is ParticleSystem)
            {
                systems.Add(n as ParticleSystem);
            }
        }
    }

    public void EmitParticle(Dictionary<string, object> overrideParams = null, bool update = true)
    {
        foreach (ParticleSystem system in systems)
        {
            system.EmitParticle(overrideParams, update);
        }
    }
}