using Godot;
using System;

public class Player : RigidBody2D
{
	public static Player main {get; private set;}

	private Sprite spr;
	private ShaderMaterial speedShaderMaterial;
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

	private int perfects = 0;

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
		speedShaderMaterial = GetNode<Sprite>("Speed").Material as ShaderMaterial;

		colShape = GetNode<CollisionShape2D>("Col").Shape as RectangleShape2D;

		rocketParticleSystem = GetNode<ParticleSystem2D>("Particles/Rocket");
		explosion1 = GetNode<ParticleSystem2D>("Particles/Explosion/_1");
		explosion2 = GetNode<ParticleSystem2D>("Particles/Explosion/_2");
		speedParticleSystem = GetNode<ParticleSystem2D>("Particles/Speed/Speed");
		speedParticleSystemPivot = GetNode<Node2D>("Particles/Speed");
		
		rocketParticleSystemEmitRate = rocketParticleSystem.GetModule<ParticleSystemEmitRate>();
		speedParticleSystemEmitRate = speedParticleSystem.GetModule<ParticleSystemEmitRate>();

		Vector2 pos = GlobalPosition;
		pos.x = World.main.terrainSize.x / 2f;
		GlobalPosition = pos;

		startTransform = GlobalTransform;
		currentFuel = maxFuel;

		World.main.Connect("OnLevelStart", this, "Reset");
	}

	public override void _Process(float delta) {
		angAcc = Input.GetActionStrength("rot_right") - Input.GetActionStrength("rot_left");
		thrusterAdd = 0f;
		if (Input.IsActionPressed("accelerate")) thrusterAdd += 1f;
		if (Input.IsActionPressed("deccelerate")) thrusterAdd -= 1f;
		if (dead) {
			if (Input.IsActionJustPressed("reset")) {
				World.main.ResetLevel();
				SetProcess(false);
			}
		}
		if (landed) {
			if (Input.IsActionJustPressed("next")) {
				World.main.NextLevel();
				SetProcess(false);
			}
		}

		speedShaderMaterial.SetShaderParam("velocity", GlobalTransform.BasisXformInv(LinearVelocity));
		speedShaderMaterial.SetShaderParam("transform", GlobalTransform);

		Update();
	}

	public override void _PhysicsProcess(float delta) {
		LinearVelocity += Vector2.Down * World.main.gravity * delta;

		if (Mathf.Abs(RotationDegrees) <= 1f) RotationDegrees = 0f;
		if (Mathf.Rad2Deg(Mathf.Abs(AngularVelocity)) <= 1f) AngularVelocity = 0f;
		if (LinearVelocity.Length() <= .1f) LinearVelocity = Vector2.Zero;

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

		Platform p = World.main.GetPlatformOnX(Position.x);
		bool landedPlatform = true;
		bool landedGround = false;

		foreach (Vector2 col in colPositions) {
			Vector2 gCol = GlobalTransform.Xform(col);

			float h = World.main.terrainSize.y - World.main.SampleHeight(gCol.x);
			float diff = h - gCol.y;
			if (diff <= 0f) {
				GlobalPosition -= Vector2.Up * diff;
				Vector2 normal = World.main.SampleNormal(gCol.x);
				ApplyImpulse(GlobalTransform.BasisXform(col), -normal * diff * delta * 100f);
				ApplyImpulse(GlobalTransform.BasisXform(col), -LinearVelocity * Mathf.Clamp(2f * delta, 0, 1));

				if (Mathf.Abs(GlobalRotationDegrees) >= explodeAtCollisionAngle || LinearVelocity.Length() >= explodeAtSpeed) {
					landedPlatform = false;
					Explode();
					continue;
				}

				landedGround = true;
				if (p == null) {
					landedPlatform = false;
					Explode();
					continue;
				}

				if (!p.IsInside(gCol.x)) {
					landedPlatform = false;
					Explode();
					continue;
				}
			}
		}
	
		if (landedGround && landedPlatform) {
			Land(p);
		}
	}

	private void Explode() {
		if (dead || landed) return;

		if (OS.GetName() == "Android" || OS.GetName() == "iOS") Input.VibrateHandheld(250);

		Game.main.totalScore -= 250;
		perfects = 0;

		PopupText popup = World.main.PopupText();
		popup.GlobalPosition = GlobalPosition;
		popup.ConfigureText("-250");
		popup.ConfigureMotion(Vector2.Up * 32f, 1.5f);
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

		float platformScoreMultiplier = p.scoreMultiplier;
		float platformPositionX = p.GlobalPosition.x;

		if (OS.GetName() == "Android" || OS.GetName() == "iOS") Input.VibrateHandheld(50);

		int perfectScore = (int)Mathf.Stepify(
			(scoreDistanceRange.y + scoreAngleRange.y + scoreSpeedRange.y) * platformScoreMultiplier,
			50
		);

		float distCenter = Mathf.Abs(platformPositionX - GlobalPosition.x);
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
			(scoreAngle + scoreDistance + scoreSpeed) * platformScoreMultiplier,
			50
		);

		bool perfect = totalScore == perfectScore;

		if (perfect) {
			perfects++;
		} else {
			perfects = 0;
		}

		float fuelAdd = platformScoreMultiplier * 40f * ((float)(totalScore) / perfectScore) + (perfects * 20f);

		totalScore += Mathf.FloorToInt(totalScore * perfects * .2f);
		totalScore = (int)Mathf.Stepify(totalScore, 50);

		Game.main.totalScore += totalScore;
		currentFuel += fuelAdd;

		float delay = 0f;

		PopupText popup;

		if (perfect) {
			popup = World.main.PopupText();
			popup.GlobalPosition = GlobalPosition + Vector2.Up * 16f;
			if (perfects == 1) {
				popup.ConfigureText("PERFECT!");
			} else {
				popup.ConfigureText("PERFECT x" + perfects + "!");
			}
			popup.ConfigureMotion(Vector2.Up * 64f);
			popup.ConfigureColorCicle(new Color[] {Colors.White, new Color(0, 1f, 1f)}, 4f);
			popup.ConfigureSize(1.25f);
			popup.Start();
			delay += .25f;
		}

		popup = World.main.PopupText();
		popup.GlobalPosition = GlobalPosition + Vector2.Right * 32f;
		popup.ConfigureText(totalScore.ToString());
		popup.ConfigureMotion(Vector2.Up * 64f);
		popup.ConfigureColorCicle(new Color[] {Colors.White, new Color(.4f, 1f, .4f)}, 4f);
		popup.ConfigureSize(1f);
		popup.Start(delay);

		delay += .25f;

		popup = World.main.PopupText();
		popup.GlobalPosition = GlobalPosition + Vector2.Down * 16f + Vector2.Left * 32f;
		popup.ConfigureText("+" + fuelAdd.ToString("F0") + " FUEL");
		popup.ConfigureMotion(Vector2.Up * 64f);
		popup.ConfigureColorCicle(new Color[] {Colors.White, new Color(1f, 1f, .4f)}, 4f);
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
		if (currentFuel == 0f) currentFuel = maxFuel;

		LinearVelocity = Vector2.Zero;
		AngularVelocity = 0f;

		dead = false;
		landed = false;
	}

	public override void _Draw() {
		//DrawSetTransformMatrix(GetGlobalTransform().AffineInverse());

		/*float posX = GlobalPosition.x;
		float h = Game.main.SampleHeight(posX);
		float globalY = Game.main.terrainSize.y - h;

		Vector2 circlePos = new Vector2(posX, globalY);
		Vector2 normal = Game.main.SampleNormal(posX);

		circlePos = GlobalTransform.XformInv(circlePos);
		normal = GlobalTransform.BasisXformInv(normal);

		DrawCircle(circlePos, 4f, Colors.Red);
		DrawLine(circlePos, circlePos + normal * 16f, Colors.Green);*/
	}
}
