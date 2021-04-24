using Godot;
using System;

public class Player : RigidBody2D
{
    public PlayerStateMachine stateMachine {get; set;}

    public override void _Ready()
    {
        stateMachine = GetNode<PlayerStateMachine>("StateMachine");

        stateMachine.root = this;
        stateMachine.Start();
    }

    public override void _PhysicsProcess(float delta)
    {
        GameCamera.instance.desiredPosition = GlobalPosition;
        if (Mode != RigidBody2D.ModeEnum.Static) {
            LinearVelocity += Planet.instance.gravity * delta;
        }
    }
}
