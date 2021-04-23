using System;
using System.Collections.Generic;
using Godot;

public class CyclopsBoss : Node2D, IDamageable
{
    private StaticBody2D head { get; set; }
    private CyclopsBossStateMachine stateMachine { get; set; }
    private bool dead { get; set; }

    public float health { get; private set; }
    public List<StaticBody2D> segments { get; set; }
    public SandParticleSystem sandParticles { get; set; }

    [Export] public float initialSpacing = 15f;
    [Export] public float spacing = 30f;
    [Export] public int numSegments = 8;
    [Export] public float maxHealth = 100f;
    [Export] public float animationTimeOffset = .1f;

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

    private void InitSegments()
    {
        head = GetNode<StaticBody2D>("Head");
        StaticBody2D segmentBase = GetNode<StaticBody2D>("Segment");
        segments = new List<StaticBody2D>();

        segments.Add(segmentBase);

        for (int i = 0; i < numSegments - 1; i++)
        {
            StaticBody2D clone = segmentBase.Duplicate() as StaticBody2D;
            segments.Add(clone);

            AddChild(clone);
            AnimationPlayer anim = clone.GetNode<AnimationPlayer>("Anim");

			Material mat = clone.Material;
			if (mat != null) clone.Material = mat.Duplicate() as Material;

            clone.Position = Vector2.Down * (i + 1);

            anim.Advance((i + 1) * animationTimeOffset / anim.PlaybackSpeed);
            //clone.Raise();
        }
		for (int i = numSegments - 1; i >= 0; i--) {
			segments[i].Raise();
		}

        head.Raise();
    }

    public void WarpSegments(Vector2 pos)
    {
        for (int i = 0; i < numSegments; i++)
        {
            segments[i].GlobalPosition = pos + Vector2.Down * (i + 1);
        }
        head.GlobalPosition = pos;
    }

    public void Move(Vector2 delta, float deltaTime)
    {
        float deltaLen = delta.Length();

        head.GlobalPosition += delta;
        head.GlobalRotation = delta.Angle();

		ShaderMaterial mat = head.Material as ShaderMaterial;
		if (mat != null) {
			mat.SetShaderParam("globalTransform", head.GlobalTransform);
		}

        Vector2 targetPos = head.GlobalPosition - head.GlobalTransform.x * initialSpacing * .5f;

        for (int i = 0; i < numSegments; i++)
        {
            StaticBody2D seg = segments[i];
            Vector2 off = (targetPos - seg.GlobalPosition);
            Vector2 dir = off.Normalized();
			off -= dir * spacing * .5f;
			float l = off.Length();

			seg.GlobalPosition -= dir * (spacing * .25f - l);
			seg.GlobalRotation = off.Angle();

			mat = seg.Material as ShaderMaterial;
			if (mat != null) {
				mat.SetShaderParam("globalTransform", seg.GlobalTransform);
			}

			targetPos = seg.GlobalPosition - seg.GlobalTransform.x * spacing * .5f;
        }

    }

    public void Damage(float dmg)
    {
        if (dead) return;
        health -= dmg;
        GD.Print(health);
        if (health <= 0f)
        {
            dead = true;
            health = 0f;
        }
    }
}
