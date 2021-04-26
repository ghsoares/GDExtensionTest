using System;
using Godot;

public class Player : RigidBody2D
{
    public PlayerStateMachine stateMachine { get; private set; }
    public Node2D bodyRoot { get; private set; }
    public Spatial particlesRoot { get; private set; }
    public ThrusterParticleSystem thrusterParticleSystem { get; private set; }
    public ExplosionParticleSystem explosionParticleSystem { get; private set; }
    public Transform2D startTransform { get; private set; }

    public override void _Ready()
    {
        stateMachine = GetNode<PlayerStateMachine>("StateMachine");
        bodyRoot = GetNode<Node2D>("Body");
        particlesRoot = GetNode<Spatial>("Particles/ParticlesView/Particles");

        thrusterParticleSystem = particlesRoot.GetNode<ThrusterParticleSystem>("Thruster");
        explosionParticleSystem = particlesRoot.GetNode<ExplosionParticleSystem>("Explosion");

        startTransform = GlobalTransform;

        stateMachine.root = this;
        stateMachine.Start();
    }

    public override void _PhysicsProcess(float delta)
    {
        GameCamera.instance.desiredPosition = GlobalPosition;
        if (Mode != RigidBody2D.ModeEnum.Static)
        {
            LinearVelocity += Planet.instance.gravity * delta;
        }
    }

    public void CollisionToggle(bool enabled = true) {
        foreach (Node c in GetChildren()) {
            if (c is CollisionShape2D) {
                (c as CollisionShape2D).Disabled = !enabled;
            }
        }
    }


}
