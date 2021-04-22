using Godot;
using System;

public class Player : RigidBody2D
{
    public static Player instance;

    public LiquidAgent waterAgent {get; set;}
    public Node2D body {get; set;}
    public Sprite sprite {get; set;}
    public Transform2D startTransform {get; set;}
    public Transform2D transform {
        get {
            if (dead) {
                return Transform2D.Identity.Translated(Vector2.One * -256f);
            } else {
                return GlobalTransform;
            }
        }
    }
    public bool dead {get; set;}

    public PlayerRocketParticleSystem rocketParticleSystem {get; set;}
    public PlayerRocketParticleSystem kickOffParticleSystem {get; set;}
    public ParticleSystemGroup explosionParticleSystem {get; set;}
    public PlayerGroundParticleSystem groundParticleSystem {get; set;}
    public PlayerStateMachine stateMachine {get; set;}
    public Physics2DDirectSpaceState spaceState {get; set;}

    [Export] public Vector2 platformZoomDistanceRange = new Vector2(32f, 100f);
    [Export] public Vector2 platformZoomRange = new Vector2(.5f, 1f);
    [Export] public float maxSafeVelocity = 32f;
    [Export] public float maxSafeAngle = 5f;

    public Player() {
        instance = this;
    }

    public override void _Ready()
    {
        waterAgent = GetNode<LiquidAgent>("WaterAgent");
        body = GetNode<Node2D>("Body");
        sprite = GetNode<Sprite>("Body/Sprite");

        rocketParticleSystem = GetNode<PlayerRocketParticleSystem>("Particles/Rocket");
        kickOffParticleSystem = GetNode<PlayerRocketParticleSystem>("Particles/KickOff");
        explosionParticleSystem = GetNode<ParticleSystemGroup>("Particles/Explosion");
        groundParticleSystem = GetNode<PlayerGroundParticleSystem>("Particles/Ground");
        stateMachine = GetNode<PlayerStateMachine>("StateMachine");

        stateMachine.root = this;
        stateMachine.Start();

        startTransform = GlobalTransform;
        groundParticleSystem.AddIgnoreObject(this);

        if (!waterAgent.IsConnected("OnLiquidBodyEnter", this, "OnLiquidBodyEnter")) {
            waterAgent.Connect("OnLiquidBodyEnter", this, "OnLiquidBodyEnter");
        }
        if (!waterAgent.IsConnected("OnLiquidBodyExit", this, "OnLiquidBodyExit")) {
            waterAgent.Connect("OnLiquidBodyExit", this, "OnLiquidBodyExit");
        }
    }

    public override void _PhysicsProcess(float delta)
    {
        spaceState = GetWorld2d().DirectSpaceState;
        if (Mode != RigidBody2D.ModeEnum.Static) {
            LinearVelocity += Planet.instance.gravity * delta;
        }
    }

    public float CalculatePlatformZoom() {
        Platform nearestPlatform = Planet.instance.platformPlacer.GetNearestPlatform(GlobalPosition.x);

        if (nearestPlatform == null) {
            return platformZoomRange.y;
        }

        float distance = (nearestPlatform.GlobalPosition - GlobalPosition).Length();
        float t = Mathf.InverseLerp(platformZoomDistanceRange.x, platformZoomDistanceRange.y, distance);

        return Mathf.Lerp(platformZoomRange.x, platformZoomRange.y, Mathf.Clamp(t, 0f, 1f));
    }

    public Rect2 GetBounds() {
        Rect2 bounds = new Rect2(GlobalPosition, Vector2.Zero);

        Vector2 extents = Vector2.One * 16f;

        Vector2[] corners = new Vector2[] {
            new Vector2( extents.x,  extents.y)/2f,
            new Vector2(-extents.x,  extents.y)/2f,
            new Vector2( extents.x, -extents.y)/2f,
            new Vector2(-extents.x, -extents.y)/2f
        };

        foreach (Vector2 corner in corners) {
            bounds = bounds.Expand(ToGlobal(corner));
        }

        return bounds;
    }

    public void CollisionToggle(bool enabled = true) {
        foreach (Node c in GetChildren()) {
            if (c is CollisionShape2D) {
                (c as CollisionShape2D).Disabled = !enabled;
            }
        }
    }

    public void OnLiquidBodyEnter(LiquidBody liquid) {
        //GD.Print("Enter: " + liquid);
    }

    public void OnLiquidBodyExit(LiquidBody liquid) {
        //GD.Print("Exit: " + liquid);
    }
}
