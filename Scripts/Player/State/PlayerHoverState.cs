using System.Collections.Generic;
using Godot;

public class PlayerHoverState : State<Player>
{
    private bool thrusterHit { get; set; }

    public float currentThrusterForce { get; private set; }
    public bool kickOff { get; private set; }
    public float currKickOffTime { get; private set; }

    public float thrusterT
    {
        get
        {
            return currentThrusterForce / maxThrusterForce;
        }
    }

    [Export] public float maxAngularVelocity = 10f, maxVelocity = 200f, maxThrusterForce = 150f;
    [Export] public float thrusterAddRate = 40f;
    [Export] public float angularAcceleration = 5f;
    [Export] public float velocityDrag = .3f, angularVelocityDrag = 4f;
    [Export] public float thrusterLength = 64f;
    [Export] public float groundParticlesSpread = 8f;
    [Export] public float kickOffForceAdd = .5f;
    [Export] public float kickOffTime = .1f;

    public override void Enter()
    {
        currentThrusterForce = 0f;
        kickOff = false;
        currKickOffTime = 0f;

        GameCamera.instance.Warp(root.GlobalPosition, 1f);
    }

    public override void PhysicsProcess(float delta)
    {
        MotionProcess(delta);

        GameCamera.instance.desiredPosition = root.GlobalPosition;
        //GameCamera.instance.desiredZoom = root.CalculatePlatformZoom();
    }

    private void MotionProcess(float delta)
    {
        float forceMultiply = 1f;

        float thrusterAdd = Input.GetActionStrength("thruster_add") - Input.GetActionStrength("thruster_subtract");
        float angAdd = Input.GetActionStrength("turn_right") - Input.GetActionStrength("turn_left");

        if (Input.IsActionJustPressed("thruster_add") && currentThrusterForce == 0f)
        {
            kickOff = true;
            currKickOffTime = kickOffTime;
        }

        if (kickOff)
        {
            thrusterAdd *= 1f + kickOffForceAdd;
            forceMultiply *= 1.5f;
            currKickOffTime -= delta;
            if (currKickOffTime <= 0f || Input.IsActionJustReleased("thruster_add")) kickOff = false;
        }

        currentThrusterForce += thrusterAdd * thrusterAddRate * delta;
        currentThrusterForce = Mathf.Clamp(currentThrusterForce, 0, maxThrusterForce);

        /*if (PlayerData.sessionCurrentFuel <= 0f)
        {
            currentThrusterForce = 0f;
            kickOff = false;
        }*/

        root.LinearVelocity += -root.GlobalTransform.y * currentThrusterForce * forceMultiply * delta / (1f + root.Mass);
        root.AngularVelocity += angAdd * angularAcceleration * delta / (1f + root.Mass);

        root.LinearVelocity -= root.LinearVelocity * Mathf.Min(velocityDrag * delta, 1f);
        root.AngularVelocity -= root.AngularVelocity * Mathf.Min(angularVelocityDrag * delta, 1f);

        root.LinearVelocity = root.LinearVelocity.Clamped(maxVelocity);
        root.AngularVelocity = Mathf.Clamp(root.AngularVelocity, -maxAngularVelocity, maxAngularVelocity);

        //PlayerData.sessionCurrentFuel -= PlayerData.fuelLossRate * currentThrusterForce * delta;
    }

    public void OnBodyEntered(Node body)
    {
        /*bool explode = false;
        if (body is TerrainCollision)
        {
            float velocity = root.LinearVelocity.Length();
            float angle = Mathf.Abs(root.RotationDegrees);

            if (velocity > root.maxSafeVelocity || angle > root.maxSafeAngle)
            {
                explode = true;
            }
            else
            {
                Platform platform = Planet.instance.platformPlacer.GetNearestPlatform(root.GlobalPosition.x);
                Rect2 bounds = root.GetBounds();

                float distance = Mathf.Max(platform.GetDistanceX(bounds.Position.x), platform.GetDistanceX(bounds.End.x));

                if (distance > 0f)
                {
                    explode = true;
                }
                else
                {
                    PlayerLandedState landedState = QueryState<PlayerLandedState>("Landed");
                    landedState.platform = platform;
                }
            }
        }
        else
        {
            explode = true;
        }

        if (explode)
        {
            QueryState("Dead");
        }*/
    }

    public override void Exit()
    {
        root.Disconnect("body_entered", this, "OnBodyEntered");
    }
}