using System.Collections.Generic;
using Godot;

public class CyclopsBossJumpState : State<CyclopsBoss>
{
    private Curve2D curve { get; set; }
    private float currentT { get; set; }
    private float curveLength { get; set; }
    private Vector2 prevPos { get; set; }

    [Export] public Vector2 distanceRange = new Vector2(128f, 256f);
    [Export] public float velocity = 64f;
    [Export] public float bezierHandleSize = 4f;
    [Export] public float segmentsSize = 50f;
    [Export] public float sandEmitRate = 16f;
    [Export] public float shakeDistance = 512f;
    [Export] public float shakeMagnitudePerSegment = .1f;

    public override void Enter()
    {
        Player player = Player.instance;
        float offX = (float)GD.RandRange(distanceRange.x, distanceRange.y);
        offX *= GD.Randf() < .5f ? -1f : 1f;

        Vector2 pos = root.GlobalPosition;

        pos.x = player.GlobalPosition.x + offX;
        float terrainY = Planet.instance.terrain.GetTerrainY(pos.x);
        pos.y = terrainY + root.spacing * 5f;

        root.GlobalPosition = pos;

        CalculateParabola(player.GlobalPosition);
    }

    private void CalculateParabola(Vector2 peakTarget)
    {
        Vector2 dir = (peakTarget - root.GlobalPosition).Normalized();
        root.WarpSegments(root.GlobalPosition);

        float offX = peakTarget.x - root.GlobalPosition.x;

        curve = new Curve2D();

        float margin = root.numSegments * root.spacing;

        curve.AddPoint(
            root.GlobalPosition + Vector2.Down * margin, Vector2.Zero, Vector2.Up * bezierHandleSize
        );
        curve.AddPoint(
            peakTarget, Vector2.Left * bezierHandleSize * Mathf.Sign(offX),
            Vector2.Right * bezierHandleSize * Mathf.Sign(offX)
        );
        curve.AddPoint(
            new Vector2(peakTarget.x + offX, root.GlobalPosition.y + margin),
            Vector2.Up * bezierHandleSize
        );

        currentT = margin;
        curveLength = curve.GetBakedLength();

        prevPos = root.GlobalPosition;
    }

    public override void PhysicsProcess(float delta)
    {
        currentT += delta * velocity;
        Vector2 point = curve.InterpolateBaked(currentT);

        Vector2 deltaPos = (point - prevPos);

        root.Move(deltaPos, delta);

        prevPos = point;

        VFXProcess(delta);

        if (currentT >= curveLength)
        {
            if (root.health > 0f) {
                QueryState("Hidden");
            } else {
                QueryState("Dead");
            }
        }
    }

    private void VFXProcess(float delta)
    {
        Terrain terrain = Planet.instance.terrain;
        Vector2 cameraPos = GameCamera.instance.GlobalPosition;
        float shake = 0f;
        foreach (StaticBody2D segment in root.segments)
        {
            float terrainY = terrain.GetTerrainY(segment.GlobalPosition.x);
            float diff = terrainY - segment.GlobalPosition.y;
            if (Mathf.Abs(diff) <= segmentsSize)
            {
                Dictionary<string, object> emitParams = new Dictionary<string, object>();

                Vector2 vel = segment.ConstantLinearVelocity;
                if (vel.y > 0f) {
                    vel = -vel;
                }

                emitParams["position"] = segment.GlobalPosition;
                emitParams["spread"] = segmentsSize;
                emitParams["velocity"] = vel * .4f;

                root.sandParticles.AddRate(delta * sandEmitRate, emitParams);

                float dist = (segment.GlobalPosition - cameraPos).Length();
                float shakeT = 1f - Mathf.Clamp(dist / shakeDistance, 0f, 1f);
                shake += shakeT * shakeMagnitudePerSegment;
            }
        }
        if (shake > 0f) GameCamera.instance.Shake(1f, 512f, shake);
    }
}