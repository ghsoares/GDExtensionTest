using System.Collections.Generic;
using ExtensionMethods.NodeMethods;
using Godot;

public class ParticleSystemGroup : Node2D
{
    public List<ParticleSystem> systems { get; private set; }

    [Export] public bool recursive = false;

    public override void _Ready()
    {
        systems = this.GetChildNodes<ParticleSystem>(recursive);

        foreach (ParticleSystem system in systems)
        {
            GD.Print(system.Name);
        }
    }

    public void EmitParticle(Dictionary<string, object> overrideParams = null, bool update = true)
    {
        foreach (ParticleSystem system in systems)
        {
            system.EmitParticle(overrideParams, update);
        }
    }

    public void Emit() {
        foreach (ParticleSystem system in systems)
        {
            system.Emit();
        }
    }
}