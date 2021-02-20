using Godot;

public class PlayerState : State<Player> {}

public class PlayerAliveState : PlayerState {
    PlayerDeadState playerDeadState;
    PlayerLandedState playerLandedState;

    public override void Init() {
        playerDeadState = GetStateByName<PlayerDeadState>("Dead");
        playerLandedState = GetStateByName<PlayerLandedState>("Landed");
    }

    public override void UpdateState() {
        root.angAcc = Input.GetActionStrength("rot_right") - Input.GetActionStrength("rot_left");
        root.thrusterAdd = 0f;
        if (Input.IsActionPressed("accelerate")) root.thrusterAdd += 1f;
        if (Input.IsActionPressed("deccelerate")) root.thrusterAdd -= 1f;
    }

    public override void FixedUpdateState() {        
        if (root.currentFuel <= 0f) {
            root.thrusterPower = 0f;
            root.thrusterAdd = 0f;
            root.angAcc = 0f;
        }

        root.thrusterPower += root.thrusterAdd * fixedDeltaTime;
        root.currentFuel -= root.maxFuelLoseRate * root.thrusterPower * fixedDeltaTime;
        
        root.LinearVelocity += -root.GlobalTransform.y * root.maxThrusterForce * root.thrusterPower * fixedDeltaTime;
        root.AngularVelocity += root.angAcc * root.angularAcceleration * fixedDeltaTime;

        bool landedGround = false;
        bool landedCorrectly = false;
        Platform p = root.CollisionCheck(fixedDeltaTime, out landedCorrectly, out landedGround);

        if (landedGround && !landedCorrectly) {
            stateMachine.QueryState(playerDeadState);
        } else if (landedGround && landedCorrectly) {
            playerLandedState.platform = p;
            stateMachine.QueryState(playerLandedState);
        }
    }
}

public class PlayerDeadState : PlayerState {
    public override void Enter() {
        root.dead = true;

        if (OS.GetName() == "Android" || OS.GetName() == "iOS") Input.VibrateHandheld(250);

        Game.main.totalScore -= 250;
        root.currentFuel -= 50;
        root.perfects = 0;

        PopupText popup = World.main.PopupText();
        popup.GlobalPosition = root.GlobalPosition;
        popup.ConfigureText("-250");
        popup.ConfigureMotion(Vector2.Up * 32f, 1.5f);
        popup.ConfigureColorCicle(new Color[] { Colors.White, new Color(1, .4f, .5f) }, 4f);
        popup.ConfigureSize(1f);
        popup.Start();

        popup = World.main.PopupText();
        popup.GlobalPosition = root.GlobalPosition + Vector2.Down * 16f + Vector2.Left * 32f;
        popup.ConfigureText("-50 Fuel");
        popup.ConfigureMotion(Vector2.Up * 32f, 1.5f);
        popup.ConfigureColorCicle(new Color[] { Colors.White, new Color(1, .4f, .5f) }, 4f);
        popup.ConfigureSize(1f);
        popup.Start(.25f);

        root.GlobalRotation = 0f;
        root.LinearVelocity = Vector2.Zero;
        root.AngularVelocity = 0f;

        root.spr.Hide();
        root.Mode = RigidBody2D.ModeEnum.Static;

        root.rocketParticleSystem.emitting = false;
        root.explosion1.Emit();
        root.explosion2.Emit();
    }

    public override void UpdateState() {
        if (Input.IsActionJustPressed("reset"))
        {
            World.main.ResetLevel();
        }
    }

    public override void Exit() {
        root.Mode = RigidBody2D.ModeEnum.Rigid;
        root.dead = false;
    }
}

public class PlayerLandedState : PlayerState {
    public Platform platform;

    public override void Enter() {
        root.landed = true;

        float platformScoreMultiplier = platform.scoreMultiplier;
        float platformPositionX = platform.GlobalPosition.x;

        if (OS.GetName() == "Android" || OS.GetName() == "iOS") Input.VibrateHandheld(50);

        int perfectScore = (int)Mathf.Stepify(
            (root.scoreDistanceRange.y + root.scoreAngleRange.y + root.scoreSpeedRange.y) * platformScoreMultiplier,
            50
        );

        float distCenter = Mathf.Abs(platformPositionX - root.GlobalPosition.x);
        float angle = Mathf.Abs(root.RotationDegrees);

        float scoreDistance = 1f - Mathf.InverseLerp(root.scoreMinDistance, platform.size.x / 2f - 8f, distCenter);
        float scoreAngle = 1f - Mathf.InverseLerp(root.scoreMinAngle, root.explodeAtCollisionAngle, angle);
        float scoreSpeed = 1f - Mathf.InverseLerp(root.scoreMinSpeed, root.explodeAtSpeed, root.currentSpeed.Length());

        scoreDistance = Mathf.Clamp(scoreDistance, 0, 1);
        scoreAngle = Mathf.Clamp(scoreAngle, 0, 1);
        scoreSpeed = Mathf.Clamp(scoreSpeed, 0, 1);

        scoreDistance = Mathf.Lerp(root.scoreDistanceRange.x, root.scoreDistanceRange.y, scoreDistance);
        scoreAngle = Mathf.Lerp(root.scoreAngleRange.x, root.scoreAngleRange.y, scoreAngle);
        scoreSpeed = Mathf.Lerp(root.scoreSpeedRange.x, root.scoreSpeedRange.y, scoreSpeed);

        int totalScore = (int)Mathf.Stepify(
            (scoreAngle + scoreDistance + scoreSpeed) * platformScoreMultiplier,
            50
        );

        bool perfect = totalScore == perfectScore;

        if (perfect)
        {
            root.perfects++;
        }
        else
        {
            root.perfects = 0;
        }

        float fuelAdd = platformScoreMultiplier * 40f * ((float)(totalScore) / perfectScore) + (root.perfects * 20f);

        totalScore += Mathf.FloorToInt(totalScore * root.perfects * .2f);
        totalScore = (int)Mathf.Stepify(totalScore, 50);

        Game.main.totalScore += totalScore;
        root.currentFuel += fuelAdd;

        float delay = 0f;

        PopupText popup;

        if (perfect)
        {
            popup = World.main.PopupText();
            popup.GlobalPosition = root.GlobalPosition + Vector2.Up * 16f;
            if (root.perfects == 1)
            {
                popup.ConfigureText("PERFECT!");
            }
            else
            {
                popup.ConfigureText("PERFECT x" + root.perfects + "!");
            }
            popup.ConfigureMotion(Vector2.Up * 64f);
            popup.ConfigureColorCicle(new Color[] { Colors.White, new Color(0, 1f, 1f) }, 4f);
            popup.ConfigureSize(1.25f);
            popup.Start();
            delay += .25f;
        }

        popup = World.main.PopupText();
        popup.GlobalPosition = root.GlobalPosition + Vector2.Right * 32f;
        popup.ConfigureText(totalScore.ToString());
        popup.ConfigureMotion(Vector2.Up * 64f);
        popup.ConfigureColorCicle(new Color[] { Colors.White, new Color(.4f, 1f, .4f) }, 4f);
        popup.ConfigureSize(1f);
        popup.Start(delay);

        delay += .25f;

        popup = World.main.PopupText();
        popup.GlobalPosition = root.GlobalPosition + Vector2.Down * 16f + Vector2.Left * 32f;
        popup.ConfigureText("+" + fuelAdd.ToString("F0") + " FUEL");
        popup.ConfigureMotion(Vector2.Up * 64f);
        popup.ConfigureColorCicle(new Color[] { Colors.White, new Color(1f, 1f, .4f) }, 4f);
        popup.ConfigureSize(1f);
        popup.Start(delay);

        root.rocketParticleSystem.emitting = false;
        platform.Land();
    }

    public override void FixedUpdateState() {
        bool landedGround = false;
        bool landedCorrectly = false;
        root.CollisionCheck(fixedDeltaTime, out landedCorrectly, out landedGround);
    }

    public override void UpdateState() {
        if (Input.IsActionJustPressed("next"))
        {
            World.main.NextLevel();
        }
    }

    public override void Exit() {
        root.landed = false;
    }
}

public class PlayerStateMachine : StateMachine<Player>
{
    public PlayerStateMachine(Player root) : base(root) {
        AddState<PlayerAliveState>("Alive");
        AddState<PlayerDeadState>("Dead");
        AddState<PlayerLandedState>("Landed");

        Init("Alive");
    }
}