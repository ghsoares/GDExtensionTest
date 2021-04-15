using System.Collections.Generic;
using Godot;

public class Debug : RichTextLabel
{
    public static Debug instance;
    private HSlider timeScaleSlider {get; set;}
    private Label timeScaleLabel {get; set;}

    float currentFps { get; set; }
    Dictionary<string, string> outputLines = new Dictionary<string, string>();

    [Export] public Gradient fpsGradient;

    public Debug()
    {
        instance = this;
    }

    public override void _Ready()
    {
        timeScaleSlider = GetNode<HSlider>("TimeScale");
        timeScaleLabel = GetNode<Label>("TimeScaleLabel");
        timeScaleSlider.Connect("value_changed", this, "TimeScaleValueChanged");
    }

    public void AddOutput(string key, string output)
    {
        outputLines[key] = output;
    }

    public override void _Process(float delta)
    {
        BbcodeText = System.String.Join("\n", outputLines.Values);
        outputLines.Clear();

        if (delta > 0f) {
            delta /= Engine.TimeScale;
            float thisFrameFps = 1f / delta;
            currentFps = Mathf.Lerp(currentFps, thisFrameFps, .1f);

            float t = currentFps / Engine.TargetFps;
            Color c = fpsGradient.Interpolate(t);

            AddOutput("FPS",
                "FPS: [color=#" + c.ToHtml() + "]" + Mathf.CeilToInt(currentFps) + "[/color]"
            );
        }

        AddOutput("Player Fuel",
            "[color=#00f2ff]Player Fuel: [/color]" +
            Mathf.CeilToInt(PlayerData.sessionCurrentFuel) +
            " / " +
            Mathf.CeilToInt(PlayerData.maxFuel)
        );
        if (Player.instance != null && Player.instance.IsInsideTree())
        {
            AddOutput("PlayerPosition",
                "[color=#00f2ff]Player Position: [/color]" +
                Player.instance.GlobalPosition
            );
            AddOutput("PlayerVelocity",
                "[color=#63ffa9]Player Velocity: [/color]" +
                Player.instance.LinearVelocity
            );
        }
    }
    
    public void TimeScaleValueChanged(float timeScale) {
        Engine.TimeScale = timeScale * .01f;
        timeScaleLabel.Text = (int)timeScale + "%";
    }
}
