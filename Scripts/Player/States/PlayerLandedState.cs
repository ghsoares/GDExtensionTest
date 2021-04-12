using Godot;

public class PlayerLandedState : State<Player> {
    public Platform platform {get; set;}

    [Export] public float minPerfectVelocity = 4f;
    [Export] public float minPerfectAngle = 1f;
    [Export] public float angleScoreAmount = 250f;
    [Export] public float speedScoreAmount = 500f;
    [Export] public int scoreRound = 50;

    public override void Enter()
    {
        CalculateScore();
    }

    private void CalculateScore() {
        int perfectScore = (int)Mathf.Stepify((angleScoreAmount + speedScoreAmount) * platform.scoreMultiplier, scoreRound);
        
        float angleScore = 1f - Mathf.InverseLerp(
            minPerfectAngle, root.maxSafeAngle, Mathf.Abs(root.RotationDegrees)
        );
        float speedScore = 1f - Mathf.InverseLerp(
            minPerfectVelocity, root.maxSafeVelocity, root.LinearVelocity.Length()
        );

        angleScore = Mathf.Clamp(angleScore, 0f, 1f) * angleScoreAmount;
        speedScore = Mathf.Clamp(speedScore, 0f, 1f) * speedScoreAmount;

        int totalScore = (int)Mathf.Stepify((angleScore + speedScore) * platform.scoreMultiplier, scoreRound);
        
        bool perfect = totalScore >= perfectScore;
        float scorePerc = (float)totalScore / perfectScore;

        PlayerData.sessionScore += totalScore;
    }

    public override void PhysicsProcess(float delta)
    {
        if (Input.IsActionJustPressed("next_level")) {
            QueryState("NextLevel");
        }
    }
}