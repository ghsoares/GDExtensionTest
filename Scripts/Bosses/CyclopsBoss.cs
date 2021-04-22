using Godot;
using System;
using System.Collections.Generic;

public class CyclopsBoss : Node2D, IDamageable
{
    private StaticBody2D head {get; set;}
    private CyclopsBossStateMachine stateMachine {get; set;}
    private bool dead {get; set;}

    public float health {get; private set;}
    public List<StaticBody2D> segments {get; set;}
    public SandParticleSystem sandParticles {get; set;}

    [Export] public float spacing = 30f;
    [Export] public int numSegments = 8;
    [Export] public float maxHealth = 100f;

    [Signal] delegate void Dead();

    public override void _Ready()
    {
        health = maxHealth;

        InitSegments();

        stateMachine = GetNode<CyclopsBossStateMachine>("StateMachine");
        stateMachine.root = this;
        stateMachine.Start();

        sandParticles = GetNode<SandParticleSystem>("SandParticles");
        sandParticles.Raise();
    }

    private void InitSegments() {
        head = GetNode<StaticBody2D>("Head");
        StaticBody2D segmentBase = GetNode<StaticBody2D>("Segment");
        StaticBody2D tail = GetNode<StaticBody2D>("Tail");
        segments = new List<StaticBody2D>();

        segments.Add(segmentBase);

        for (int i = 0; i < numSegments - 1; i++) {
            StaticBody2D clone = segmentBase.Duplicate() as StaticBody2D;
            segments.Add(clone);

            AddChild(clone);
        }

        segments.Add(tail);

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
        for (int i = 0; i < numSegments; i++) {
            StaticBody2D curr = segments[i];
            StaticBody2D nxt = null;
            if (i < numSegments - 1) {
                nxt = segments[i+1];
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

    public void Damage(float dmg)
    {
        if (dead) return;
        health -= dmg;
        if (health <= 0f) {
            dead = true;
            health = 0f;
        }
    }
}
