using Godot;
using System;

public class Player : RigidBody2D
{
    public static Player main {get; private set;}

    private Sprite spr;
    private RectangleShape2D colShape;
    private ParticleSystem2D rocketParticleSystem;
    private ParticleSystem2D explosion1;
    private ParticleSystem2D explosion2;
    private ParticleSystem2D speedParticleSystem;
    private Node2D speedParticleSystemPivot;
    private ParticleSystemEmitRate rocketParticleSystemEmitRate;
    private ParticleSystemEmitRate speedParticleSystemEmitRate;
    private Transform2D startTransform;

    private float angAcc = 0f;
    private float thrusterAdd = 0f;
    private float thrusterPower = 0f;

    public bool dead {get; private set;}
    public bool landed {get; private set;}
    public float currentFuel {get; set;}

    public Vector2 currentSpeed {
        get {
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

    public Player() {
        main = this;
    }

    public override void _Ready() {
        spr = GetNode<Sprite>("Spr");

        colShape = GetNode<CollisionShape2D>("Col").Shape as RectangleShape2D;

        rocketParticleSystem = GetNode<ParticleSystem2D>("Particles/Rocket");
        explosion1 = GetNode<ParticleSystem2D>("Particles/Explosion/_1");
        explosion2 = GetNode<ParticleSystem2D>("Particles/Explosion/_2");
        speedParticleSystem = GetNode<ParticleSystem2D>("Particles/Speed/Speed");
        speedParticleSystemPivot = GetNode<Node2D>("Particles/Speed");
        
        rocketParticleSystemEmitRate = rocketParticleSystem.GetModule<ParticleSystemEmitRate>();
        speedParticleSystemEmitRate = speedParticleSystem.GetModule<ParticleSystemEmitRate>();

        rocketParticleSystem.GetModule<Collision>().excludeBodies.Add(this);
        explosion2.GetModule<Collision>().excludeBodies.Add(this);

        Vector2 pos = GlobalPosition;
        pos.x = Game.main.terrainSize.x / 2f;
        GlobalPosition = pos;

        startTransform = GlobalTransform;
        currentFuel = maxFuel;

        //Connect("body_entered", this, "OnBodyEnter");
        Game.main.Connect("OnReset", this, "Reset");
    }

    public override void _Process(float delta) {
        angAcc = Input.GetActionStrength("rot_right") - Input.GetActionStrength("rot_left");
        thrusterAdd = 0f;
        if (Input.IsActionPressed("accelerate")) thrusterAdd += 1f;
        if (Input.IsActionPressed("deccelerate")) thrusterAdd -= 1f;
        if (dead) {
            if (Input.IsActionJustPressed("reset")) {
                Game.main.ResetLevel();
                SetProcess(false);
            }
        }
        if (landed) {
            if (Input.IsActionJustPressed("next")) {
                Game.main.NextLevel();
                SetProcess(false);
            }
        }
    }

    public override void _PhysicsProcess(float delta) {
        LinearVelocity += Vector2.Down * Game.main.gravity * delta;

        if (currentFuel <= 0f || landed) {
            thrusterPower = 0f;
            thrusterAdd = 0f;
            angAcc = 0f;
        }

        MotionProcess(delta);

        Game.main.targetPosition = GlobalTransform.origin;

        CollisionCheck(delta);
    }

    private void MotionProcess(float delta) {
        thrusterPower += thrusterAdd * delta;
        thrusterPower = Mathf.Clamp(thrusterPower, 0, 1);

        currentFuel -= maxFuelLoseRate * thrusterPower * delta;
        currentFuel = Mathf.Clamp(currentFuel, 0f, maxFuel);

        LinearVelocity += -GlobalTransform.y * maxThrusterForce * thrusterPower * delta;
        AngularVelocity += angAcc * angularAcceleration * delta;

        float speedP = Mathf.InverseLerp(explodeAtSpeed, maxVelocity, currentSpeed.Length());

        speedParticleSystemPivot.LookAt(GlobalPosition + currentSpeed);

        rocketParticleSystemEmitRate.rate = 64f * thrusterPower;
        if (speedP > 0f) {
            speedParticleSystemEmitRate.rate = Mathf.Lerp(8f, 64f, Mathf.Clamp(speedP, 0, 1));
        } else {
            speedParticleSystemEmitRate.rate = 0f;
        }
        
        LinearVelocity -= LinearVelocity * Mathf.Clamp(velocityDrag * delta, 0, 1);
        AngularVelocity -= AngularVelocity * Mathf.Clamp(angularVelocityDrag * delta, 0, 1);

        LinearVelocity = LinearVelocity.Clamped(maxVelocity);
        AngularVelocity = Mathf.Clamp(AngularVelocity, -maxAngularVelocity, maxAngularVelocity);
    }

    private void CollisionCheck(float delta) {
        Vector2 ext = colShape.Extents;

        Vector2[] colPositions = new Vector2[] {
            -ext,
            new Vector2(ext.x, -ext.y),
            ext,
            new Vector2(-ext.x, ext.y),
        };

        Platform p = Game.main.GetPlatformOnX(Position.x);
        bool insidePlatform = true;
        bool landedGround = false;

        foreach (Vector2 col in colPositions) {
            Vector2 gCol = GlobalTransform.Xform(col);

            float h = Game.main.terrainSize.y - Game.main.SampleHeight(gCol.x);
            float diff = h - gCol.y;
            if (diff <= 0f) {
                GlobalPosition -= Vector2.Up * diff;
                Vector2 normal = Game.main.SampleNormal(gCol.x);
                ApplyImpulse(GlobalTransform.BasisXform(col), -normal * diff * delta * 100f);
                ApplyImpulse(GlobalTransform.BasisXform(col), -LinearVelocity * Mathf.Clamp(2f * delta, 0, 1));

                if (Mathf.Abs(GlobalRotationDegrees) >= explodeAtCollisionAngle || LinearVelocity.Length() >= explodeAtSpeed) {
                    Explode();
                    break;
                }

                landedGround = true;
                if (p == null) {
                    insidePlatform = false;
                    Explode();
                }

                if (!p.IsInside(gCol.x)) {
                    insidePlatform = false;
                    Explode();
                }
            }
        }
    
        if (landedGround && insidePlatform) {
            Land(p);
        }
    }

    private void Explode() {
        if (dead || landed) return;

        if (OS.GetName() == "Android" || OS.GetName() == "iOS") Input.VibrateHandheld(250);

        Game.main.totalScore -= 250;

        PopupText popup = Game.main.PopupText();
        popup.GlobalPosition = GlobalPosition;
        popup.ConfigureText("-250");
        popup.ConfigureMotion(GlobalPosition + Vector2.Up * 32f, 1.5f);
        popup.ConfigureColorCicle(new Color[] {Colors.White, new Color(1, .4f, .5f)}, 4f);
        popup.ConfigureSize(1f);
        popup.Start();

        GlobalRotation = 0f;

        LinearVelocity = Vector2.Zero;
        AngularVelocity = 0f;

        spr.Hide();
        SetPhysicsProcess(false);
        SetPhysicsProcessInternal(false);
        rocketParticleSystem.emitting = false;
        speedParticleSystem.emitting = false;
        explosion1.Emit();
        explosion2.Emit();

        dead = true;
    }

    private void Land(Platform p) {
        if (landed) return;

        if (OS.GetName() == "Android" || OS.GetName() == "iOS") Input.VibrateHandheld(50);

        float distCenter = Mathf.Abs(p.GlobalPosition.x - GlobalPosition.x);
        float angle = Mathf.Abs(RotationDegrees);

        float scoreDistance = 1f - Mathf.InverseLerp(scoreMinDistance, p.size.x / 2f - 8f, distCenter);
        float scoreAngle = 1f - Mathf.InverseLerp(scoreMinAngle, explodeAtCollisionAngle, angle);
        float scoreSpeed = 1f - Mathf.InverseLerp(scoreMinSpeed, explodeAtSpeed, currentSpeed.Length());

        scoreDistance = Mathf.Clamp(scoreDistance, 0, 1);
        scoreAngle = Mathf.Clamp(scoreAngle, 0, 1);
        scoreSpeed = Mathf.Clamp(scoreSpeed, 0, 1);

        scoreDistance = Mathf.Lerp(scoreDistanceRange.x, scoreDistanceRange.y, scoreDistance);
        scoreAngle = Mathf.Lerp(scoreAngleRange.x, scoreAngleRange.y, scoreAngle);
        scoreSpeed = Mathf.Lerp(scoreSpeedRange.x, scoreSpeedRange.y, scoreSpeed);

        int totalScore = (int)Mathf.Stepify(
            (scoreAngle + scoreDistance + scoreSpeed) * p.scoreMultiplier,
            50
        );

        bool perfect = totalScore == (int)Mathf.Stepify(
            (scoreDistanceRange.y + scoreAngleRange.y + scoreSpeedRange.y) * p.scoreMultiplier,
            50
        );

        Game.main.totalScore += totalScore;
        float delay = 0f;

        PopupText popup;

        if (perfect) {
            popup = Game.main.PopupText();
            popup.GlobalPosition = GlobalPosition + Vector2.Up * 16f;
            popup.ConfigureText("PERFECT!");
            popup.ConfigureMotion(GlobalPosition + Vector2.Up * 80f);
            popup.ConfigureColorCicle(new Color[] {Colors.White, new Color(0, 1, 1)}, 4f);
            popup.ConfigureSize(1.25f);
            popup.Start();
            delay = .25f;
        }

        popup = Game.main.PopupText();
        popup.GlobalPosition = GlobalPosition;
        popup.ConfigureText(totalScore.ToString());
        popup.ConfigureMotion(GlobalPosition + Vector2.Up * 64f);
        popup.ConfigureColorCicle(new Color[] {Colors.White, new Color(.4f, 1, .4f)}, 4f);
        popup.ConfigureSize(1f);
        popup.Start(delay);

        rocketParticleSystem.emitting = false;
        speedParticleSystem.emitting = false;
        
        landed = true;
        p.Land();
    }

    private void Reset() {
        spr.Show();
        SetProcess(true);
        SetPhysicsProcess(true);
        SetPhysicsProcessInternal(true);
        rocketParticleSystem.emitting = true;
        speedParticleSystem.emitting = true;
        GlobalTransform = startTransform;

        thrusterPower = 0f;
        thrusterAdd = 0f;
        angAcc = 0f;
        currentFuel = maxFuel;

        LinearVelocity = Vector2.Zero;
        AngularVelocity = 0f;

        dead = false;
        landed = false;
    }

    /*public void OnBodyEnter(Node2D body) {
        for (int i = 0; i < prevState.GetContactCount(); i++) {
            var obj = prevState.GetContactColliderObject(i);
            if (obj != body) continue;

            Vector2 n = prevState.GetContactLocalNormal(i);
            float a1 = Mathf.Abs(n.AngleTo(Vector2.Up));
            a1 = Mathf.Rad2Deg(a1);
            
            n = GlobalTransform.BasisXformInv(n);
            float a2 = Mathf.Abs(n.AngleTo(Vector2.Up));
            a2 = Mathf.Rad2Deg(a2);
            
            if (Mathf.Max(a1, a2) >= explodeAtCollisionAngle || prevVelocity.Length() >= explodeAtSpeed) {
                Explode();
                break;
            }

            Platform p = obj as Platform;
            bool inside = true;
            if (p != null) {
                Vector2 ext = colShape.Extents;
                Vector2[] colPositions = new Vector2[] {
                    ext,
                    new Vector2(-ext.x, ext.y),
                };
                foreach (Vector2 col in colPositions) {
                    Vector2 gCol = GlobalTransform.Xform(col);
                    if (!p.IsInside(gCol.x)) {
                        inside = false;
                        break;
                    }
                }
            }

            if (!inside) {
                Explode();
                break;
            }

            Land(p);
        }
    }*/
}
