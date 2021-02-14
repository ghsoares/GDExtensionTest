using Godot;
using System.Linq;
using ExtensionMethods.IEnumerableMethods;
using ExtensionMethods.RandomMethods;

public class Game : Control
{
	private int _totalScore;

	public static Game main { get; private set; }
	public Viewport view { get; private set; }
	public AnimationPlayer transitionAnim {get; private set;}
	public WorldCamera worldCamera { get; private set; }
	public Camera2D zoomCamera { get; private set; }
	public Vector2 targetPosition { get; set; }
	public int totalScore {
		get {
			return _totalScore;
		}
		set {
			_totalScore = Mathf.Max(value, 0);
		}
	}
	
	
	[Export]
	public float cameraTransitionLen = 64f;
	[Export]
	public Curve cameraTransitionCurve;
	[Export]
	public Vector2 zoomRange = new Vector2(2f, 1f);
	[Export]
	public float pixelSize = 2f;

	[Signal]
	public delegate void OnReset();

	public Game()
	{
		main = this;
	}

	public override void _Ready()
	{
		view = GetNode<Viewport>("View");
		worldCamera = GetNode<WorldCamera>("View/Cam");
		zoomCamera = GetNode<Camera2D>("Cam");

		transitionAnim = GetNode<AnimationPlayer>("UI/Transition/Anim");
		transitionAnim.Play("Out");
	}

	public override void _Process(float delta)
	{
		UpdateViewport();

		worldCamera.LimitLeft = 0;
		worldCamera.LimitTop = 0;
		worldCamera.LimitRight = Mathf.FloorToInt(World.main.terrainSize.x);
		worldCamera.LimitBottom = Mathf.FloorToInt(World.main.terrainSize.y);

		zoomCamera.LimitLeft = 0;
		zoomCamera.LimitTop = 0;
		zoomCamera.LimitRight = Mathf.FloorToInt(RectSize.x);
		zoomCamera.LimitBottom = Mathf.FloorToInt(RectSize.y);
	}

	private void UpdateViewport()
	{
		view.Size = RectSize / pixelSize;
		view.SetSizeOverride(true, RectSize);
		view.SizeOverrideStretch = true;
	}

	public override void _PhysicsProcess(float delta)
	{
		Platform minP;
		Platform maxP;
		World.main.GetBetweenPlatforms(targetPosition.x, out minP, out maxP);

		float tPos = Mathf.InverseLerp(minP.Position.x, maxP.Position.x, targetPosition.x);
		Vector2 platformPos = minP.Position.LinearInterpolate(maxP.Position, tPos);

		float targetH = World.main.terrainSize.y - World.main.highestPoint;
		float dist = platformPos.y - targetPosition.y;
		float t = dist / cameraTransitionLen;
		t = 1f - Mathf.Clamp(t, 0, 1);

		t = cameraTransitionCurve.Interpolate(t);

		float z = Mathf.Lerp(zoomRange.x, zoomRange.y, t);
		Vector2 zoom = Vector2.One * z;

		Vector2 pos = worldCamera.GlobalPosition;
		pos = pos.LinearInterpolate(targetPosition, 4f * delta);

		worldCamera.position = pos;

		zoomCamera.Zoom = zoomCamera.Zoom.LinearInterpolate(zoom, 4f * delta);

		Vector2 onViewPos = TransformBetweenViewports(worldCamera.position, worldCamera.GetViewport(), GetViewport());
		
		onViewPos.x = Mathf.Stepify(onViewPos.x, z);
		onViewPos.y = Mathf.Stepify(onViewPos.y, z);

		zoomCamera.Position = onViewPos;
	}

	public void ResetLevel() {
		transitionAnim.Play("In");
		transitionAnim.Connect(
			"animation_finished", this, "OnTransitionAnimationFinished",
			new Godot.Collections.Array(new object[] {
				0
			})
		);
	}

	public void NextLevel() {
		transitionAnim.Play("In");
		transitionAnim.Connect(
			"animation_finished", this, "OnTransitionAnimationFinished",
			new Godot.Collections.Array(new object[] {
				1
			})
		);
	}

	public void Reset() {
		transitionAnim.Play("In");
		transitionAnim.Connect(
			"animation_finished", this, "OnTransitionAnimationFinished",
			new Godot.Collections.Array(new object[] {
				2
			})
		);
	}

	private Vector2 TransformBetweenViewports(Vector2 pos, Viewport fromViewport, Viewport toViewport)
	{
		Transform2D fromT = fromViewport.GetFinalTransform() * fromViewport.CanvasTransform;
		Transform2D toT = toViewport.GetFinalTransform() * toViewport.CanvasTransform;
		pos = fromT.Xform(pos) / fromViewport.Size;
		pos *= RectSize;
		return pos;
	}

	public void OnTransitionAnimationFinished(string animName, int transitionType) {
		switch (transitionType) {
			case 0: {
				EmitSignal("OnReset");
				break;
			}
			case 1: {
				World.main.Generate();
				EmitSignal("OnReset");
				break;
			}
			case 2: {
				World.main.Generate();
				EmitSignal("OnReset");
				break;
			}
		}
		transitionAnim.Play("Out");
		transitionAnim.Disconnect("animation_finished", this, "OnTransitionAnimationFinished");
	}
}
