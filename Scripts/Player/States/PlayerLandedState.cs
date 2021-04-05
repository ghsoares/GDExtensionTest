using Godot;

public class PlayerLandedState : State<Player> {
    public Platform platform {get; set;}

    [Export] public float minPerfectVelocity = 4f;
    [Export] public float minPerfectAngle = 1f;
    [Export] public float angleScoreAmount = 250f;
    [Export] public float speedScoreAmount = 500f;
    [Export] public float scoreRound = 50f;

    public override void Enter()
    {
        CalculateScore();
    }

    private void CalculateScore() {
        float perfectScore = Mathf.Stepify((angleScoreAmount + speedScoreAmount) * platform.scoreMultiplier, scoreRound);
        
        float angleScore = 1f - Mathf.InverseLerp(
            minPerfectAngle, root.maxSafeAngle, Mathf.Abs(root.RotationDegrees)
        );
        float speedScore = 1f - Mathf.InverseLerp(
            minPerfectVelocity, root.maxSafeVelocity, root.LinearVelocity.Length()
        );

        angleScore = Mathf.Clamp(angleScore, 0f, 1f) * angleScoreAmount;
        speedScore = Mathf.Clamp(speedScore, 0f, 1f) * speedScoreAmount;

        float totalScore = Mathf.Stepify((angleScore + speedScore) * platform.scoreMultiplier, scoreRound);
        
        bool perfect = totalScore >= perfectScore;
        float scorePerc = totalScore / perfectScore;
    }

    public override void PhysicsProcess(float delta)
    {
        if (Input.IsActionJustPressed("next_level")) {
            QueryState("Hover");
        }
    }

    public override void Exit()
    {
        root.GlobalTransform = root.startTransform;
    }
}