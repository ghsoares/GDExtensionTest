using System.Collections.Generic;
using Godot;

public class PlayerHoverState : State<Player>
{
    float currentThrusterForce = 0f;
    bool startKickOff = false;
    bool kickOff = false;
    float currKickOffTime = 0f;

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
        startKickOff = false;
        kickOff = false;
        currKickOffTime = 0f;

        root.thrusterParticleSystem.emitting = true;
        root.groundThrusterParticleSystem.emitting = true;
        root.Connect("body_entered", this, "OnBodyEntered");
    }

    public override void PhysicsProcess(float delta)
    {
        MotionProcess(delta);
        ParticlesProcess(delta);

        startKickOff = false;
        GameCamera.instance.desiredZoom = root.CalculatePlatformZoom();
    }

    private void MotionProcess(float delta)
    {
        float forceMultiply = 1f;

        float thrusterAdd = Input.GetActionStrength("thruster_add") - Input.GetActionStrength("thruster_subtract");
        float angAdd = Input.GetActionStrength("turn_right") - Input.GetActionStrength("turn_left");

        if (Input.IsActionJustPressed("thruster_add") && currentThrusterForce == 0f)
        {
            kickOff = true;
            startKickOff = true;
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

        root.LinearVelocity += -root.GlobalTransform.y * currentThrusterForce * forceMultiply * delta / (1f + root.Mass);
        root.AngularVelocity += angAdd * angularAcceleration * delta / (1f + root.Mass);

        root.LinearVelocity -= root.LinearVelocity * Mathf.Min(velocityDrag * delta, 1f);
        root.AngularVelocity -= root.AngularVelocity * Mathf.Min(angularVelocityDrag * delta, 1f);

        root.LinearVelocity = root.LinearVelocity.Clamped(maxVelocity);
        root.AngularVelocity = Mathf.Clamp(root.AngularVelocity, -maxAngularVelocity, maxAngularVelocity);
    }

    private void ParticlesProcess(float delta)
    {
        float thrusterT = currentThrusterForce / maxThrusterForce;

        root.thrusterParticleSystem.emissionRate = 64f * thrusterT;
        root.thrusterParticleSystem.velocityMultiply = Mathf.Lerp(.25f, 1f, thrusterT);

        root.groundThrusterParticleSystem.maxEmissionRate = 64f * thrusterT;
        root.groundThrusterParticleSystem.velocityMultiply = Mathf.Lerp(.5f, 1f, thrusterT);

        if (startKickOff)
        {
            root.kickOffParticleSystem.EmitParticle();
        }
    }

    public void OnBodyEntered(Node body)
    {
        bool explode = false;
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
        }
    }

    public override void Exit()
    {
        root.thrusterParticleSystem.emitting = false;
        root.groundThrusterParticleSystem.emitting = false;
        root.Disconnect("body_entered", this, "OnBodyEntered");
    }
}