using Godot;
using System;
using System.Collections.Generic;

public class CyclopsBoss : Node2D
{
    private StaticBody2D head {get; set;}
    private CyclopsBossStateMachine stateMachine {get; set;}

    public List<StaticBody2D> segments {get; set;}
    public SandParticleSystem sandParticles {get; set;}

    [Export] public float spacing = 30f;
    [Export] public int numSegments = 8;

    public override void _Ready()
    {
        head = GetNode<StaticBody2D>("Head");
        InitSegments();

        stateMachine = GetNode<CyclopsBossStateMachine>("StateMachine");
        stateMachine.root = this;
        stateMachine.Start();

        sandParticles = GetNode<SandParticleSystem>("SandParticles");
        sandParticles.Raise();
    }

    private void InitSegments() {
        StaticBody2D segmentBase = GetNode<StaticBody2D>("Segment");
        segments = new List<StaticBody2D>();

        segments.Add(segmentBase);

        for (int i = 0; i < numSegments - 1; i++) {
            StaticBody2D clone = segmentBase.Duplicate() as StaticBody2D;
            segments.Add(clone);

            AddChild(clone);
        }

        head.Raise();
    }

    public void WarpSegments(Vector2 pos) {
        foreach (StaticBody2D segment in segments) {
            segment.GlobalPosition = pos;
        }
        head.GlobalPosition = pos;
    }

    public void Move(Vector2 delta, float deltaTime) {
        float deltaLen = delta.Length();
        for (int i = numSegments - 1; i >= 0; i--) {
            StaticBody2D curr = segments[i];
            StaticBody2D nxt = null;
            if (i > 0) {
                nxt = segments[i-1];
            } else {
                nxt = head;
            }

            Vector2 dir = (nxt.GlobalPosition - curr.GlobalPosition).Normalized();
            Vector2 prev = curr.GlobalPosition;

            float deltaT = Mathf.Clamp(deltaLen / spacing, 0f, 1f);
            curr.GlobalPosition = curr.GlobalPosition.LinearInterpolate(nxt.GlobalPosition, deltaT);

            curr.GlobalRotation = dir.Angle();

            curr.ConstantLinearVelocity = (curr.GlobalPosition - prev) / deltaTime;
        }

        head.GlobalPosition += delta;
        head.GlobalRotation = delta.Angle();
    }
}
