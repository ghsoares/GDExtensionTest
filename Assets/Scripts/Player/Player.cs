using Godot;
using System;

public class Player : RigidBody2D
{
    public static Player main { get; private set; }

    private PlayerStateMachine stateMachine { get; set; }

    public Sprite spr;
    public ShaderMaterial speedShaderMaterial;
    public RectangleShape2D colShape;
    public ParticleSystem2D rocketParticleSystem;
    public ParticleSystem2D explosion1;
    public ParticleSystem2D explosion2;
    public ParticleSystemEmitRate rocketParticleSystemEmitRate;
    public Transform2D startTransform;


    public bool dead { get; set; }
    public bool landed { get; set; }
    public float currentFuel { get; set; }
    public int perfects = 0;
	public float angAcc = 0f;
    public float thrusterAdd = 0f;
    public float thrusterPower = 0f;

    public Vector2 currentSpeed
    {
        get
        {
            if (dead || landed) return Vector2.Zero;
            return LinearVelocity;
        }
    }

    [Export]
    public float maxAngularVelocity = 15f;
    [Export]
    public float maxVelocity = 100f;
    [Export]
    public float angularAcceleration = 8f;
    [Export]
    public float maxThrusterForce = 8f;
    [Export]
    public float maxFuel = 500f;
    [Export]
    public float maxFuelLoseRate = 10f;
    [Export]
    public float velocityDrag = 2f;
    [Export]
    public float angularVelocityDrag = 10f;
    [Export]
    public float explodeAtCollisionAngle = 15f;
    [Export]
    public float explodeAtSpeed = 20f;
    [Export]
    public float scoreMinDistance = 1f;
    [Export]
    public float scoreMinAngle = 1f;
    [Export]
    public float scoreMinSpeed = 2f;
    [Export]
    public Vector2 scoreAngleRange = new Vector2(10, 200);
    [Export]
    public Vector2 scoreDistanceRange = new Vector2(10, 300);
    [Export]
    public Vector2 scoreSpeedRange = new Vector2(10, 500);

    public Player()
    {
        main = this;
    }

    public override void _Ready()
    {
		stateMachine = new PlayerStateMachine(this);

        spr = GetNode<Sprite>("Spr");
        speedShaderMaterial = GetNode<Sprite>("Speed").Material as ShaderMaterial;

        colShape = GetNode<CollisionShape2D>("Col").Shape as RectangleShape2D;

        rocketParticleSystem = GetNode<ParticleSystem2D>("Particles/Rocket");
        explosion1 = GetNode<ParticleSystem2D>("Particles/Explosion/_1");
        explosion2 = GetNode<ParticleSystem2D>("Particles/Explosion/_2");

        rocketParticleSystemEmitRate = rocketParticleSystem.GetModule<ParticleSystemEmitRate>();

        Vector2 pos = GlobalPosition;
        pos.x = World.main.terrainSize.x / 2f;
        GlobalPosition = pos;

        startTransform = GlobalTransform;
        currentFuel = maxFuel;

        World.main.Connect("OnLevelStart", this, "Reset");
    }

    public override void _Process(float delta)
    {
		stateMachine.Update(delta);
		speedShaderMaterial.SetShaderParam("velocity", GlobalTransform.BasisXformInv(currentSpeed));
        speedShaderMaterial.SetShaderParam("transform", GlobalTransform);
        Update();
    }

    public override void _PhysicsProcess(float delta)
    {
		Game.main.targetPosition = GlobalPosition;
		LinearVelocity += Vector2.Down * World.main.gravity * delta;
		stateMachine.FixedUpdate(delta);

		currentFuel = Mathf.Clamp(currentFuel, 0f, maxFuel);
		thrusterPower = Mathf.Clamp(thrusterPower, 0, 1);

        LinearVelocity -= LinearVelocity * Mathf.Clamp(velocityDrag * delta, 0, 1);
        AngularVelocity -= AngularVelocity * Mathf.Clamp(angularVelocityDrag * delta, 0, 1);

		LinearVelocity = LinearVelocity.Clamped(maxVelocity);
        AngularVelocity = Mathf.Clamp(AngularVelocity, -maxAngularVelocity, maxAngularVelocity);

		rocketParticleSystemEmitRate.rate = 64f * thrusterPower;
    }

    public Platform CollisionCheck(float delta, out bool landedCorrectly, out bool landedGround)
    {
        Vector2 ext = colShape.Extents;

        Vector2[] colPositions = new Vector2[] {
            -ext,
            new Vector2(ext.x, -ext.y),
            ext,
            new Vector2(-ext.x, ext.y),
        };

        Platform p = World.main.GetPlatformOnX(Position.x);
        landedCorrectly = true;
        landedGround = false;

        foreach (Vector2 col in colPositions)
        {
            Vector2 gCol = GlobalTransform.Xform(col);

            float h = World.main.terrainSize.y - World.main.SampleHeight(gCol.x);
            float diff = h - gCol.y;
            if (diff <= 0f)
            {
				diff = Mathf.Abs(diff);
                landedGround = true;

                if (Mathf.Abs(GlobalRotationDegrees) >= explodeAtCollisionAngle || LinearVelocity.Length() >= explodeAtSpeed)
                {
                    landedCorrectly = false;
                    continue;
                }

                if (p == null)
                {
                    landedCorrectly = false;
                    continue;
                }

                if (!p.IsInside(gCol.x))
                {
                    landedCorrectly = false;
                    continue;
                }
            }
        }

		return p;
    }

    private void Reset()
    {
        spr.Show();
        rocketParticleSystem.emitting = true;
        GlobalTransform = startTransform;

        thrusterPower = 0f;
        thrusterAdd = 0f;
        angAcc = 0f;
        if (currentFuel == 0f) currentFuel = maxFuel;

        LinearVelocity = Vector2.Zero;
        AngularVelocity = 0f;

        stateMachine.ChangeState(stateMachine.states["Alive"]);
    }

    public override void _Draw()
    {
        /*DrawSetTransformMatrix(GetGlobalTransform().AffineInverse());

        float posX = GlobalPosition.x;
        float globalY = World.main.SamplePositionY(posX);

        Vector2 circlePos = new Vector2(posX, globalY);
        Vector2 normal = World.main.SampleNormal(posX);

        DrawCircle(circlePos, 4f, Colors.Red);
        DrawLine(circlePos, circlePos + normal * 16f, Colors.Green);*/
    }
}
