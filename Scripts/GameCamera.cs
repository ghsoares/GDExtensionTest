using System;
using Godot;

public class GameCamera : Camera2D
{
    public static GameCamera instance;

    private float currentShakeElapsed {get; set;}

    private float currentShakeDuration {get; set;}
    private float currentShakeTime { get; set; }
    private float currentShakeFrequency { get; set; }
    private float currentShakeMagnitude { get; set; }
    private OpenSimplexNoise shakeNoise { get; set; }

    public float desiredZoom = 1f;
    public Vector2 desiredPosition;
    public Vector2 currentPosition;
    public float currentZoom;

    [Export]
    public float lerpSpeed = 4f;

    public GameCamera()
    {
        instance = this;
        Current = true;
        ProcessMode = Camera2DProcessMode.Physics;

        shakeNoise = new OpenSimplexNoise() {Octaves = 1};
    }

    public void Warp(Vector2 toPosition, float zoom)
    {
        desiredPosition = toPosition;
        desiredZoom = zoom;
        currentPosition = toPosition;
        currentZoom = zoom;
    }

    public override void _Ready()
    {
        desiredPosition = GlobalPosition;
        desiredZoom = Zoom.x;
        currentPosition = GlobalPosition;
        currentZoom = desiredZoom;

        LimitSmoothed = true;
    }

    public void SetLimits()
    {
        LimitLeft = Mathf.FloorToInt(Planet.instance.margin * .5f);
        LimitTop = Mathf.FloorToInt(Planet.instance.margin * .5f);
        LimitRight = Mathf.FloorToInt(Planet.instance.totalSize.x);
        LimitBottom = Mathf.FloorToInt(Planet.instance.totalSize.y);
    }

    public void Shake(float duration, float frequency, float magnitude) {
        this.currentShakeDuration = Mathf.Max(this.currentShakeDuration, duration);
        this.currentShakeTime = Mathf.Max(this.currentShakeTime, duration);
        this.currentShakeFrequency = Mathf.Max(this.currentShakeFrequency, frequency);
        this.currentShakeMagnitude = Mathf.Max(this.currentShakeMagnitude, magnitude);
    }

    public override void _PhysicsProcess(float delta)
    {
        desiredPosition.x = Mathf.Clamp(desiredPosition.x, LimitLeft, LimitRight);
        desiredPosition.y = Mathf.Clamp(desiredPosition.y, LimitTop, LimitBottom);
        desiredZoom = Mathf.Clamp(desiredZoom, 0.001f, 1f);

        currentPosition = currentPosition.LinearInterpolate(desiredPosition, Mathf.Min(1f, delta * lerpSpeed));
        currentZoom = Mathf.Lerp(currentZoom, desiredZoom, Mathf.Min(1f, delta * lerpSpeed));

        GlobalPosition = currentPosition;

        ShakeProcess(delta);

        ForceUpdateScroll();
    }

    private void ShakeProcess(float delta)
    {
        currentShakeElapsed += delta;

        if (currentShakeTime > 0f)
        {
            float shakeT = currentShakeTime / currentShakeDuration;
            float elapsed = currentShakeDuration - currentShakeTime;
            float x = currentShakeElapsed * currentShakeFrequency;

            shakeT = Mathf.Clamp(shakeT, 0f, 1f);

            Vector2 off = new Vector2(
                shakeNoise.GetNoise2d(x, 0f),
                shakeNoise.GetNoise2d(0f, x)
            ) * currentShakeMagnitude * shakeT;
            Offset = off;
            Debug.instance.AddOutput("Shake Offset", $"Current Shake Offset: {off}");
            Debug.instance.AddOutput("Shake Offset", $"Current Shake Offset: {off}");

            currentShakeTime -= delta;
            if (currentShakeTime <= 0f) {
                currentShakeDuration = 0f;
                currentShakeFrequency = 0f;
                currentShakeMagnitude = 0f;
            }
        } else {
            Offset = Vector2.Zero;
        }

        Debug.instance.AddOutput("Shake Time", $"Current Shake Time: {currentShakeTime}");
        Debug.instance.AddOutput("Shake Magnitude", $"Current Shake Magnitude: {currentShakeMagnitude}");
        Debug.instance.AddOutput("Shake Frequency", $"Current Shake Frequency: {currentShakeFrequency}");
    }
}
