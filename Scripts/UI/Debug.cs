using System.Collections.Generic;
using Godot;

public class Debug : RichTextLabel
{
    public static Debug instance;

    float currentFps { get; set; }
    Dictionary<string, string> outputLines = new Dictionary<string, string>();

    [Export] public Gradient fpsGradient;

    public Debug()
    {
        instance = this;
    }

    public void AddOutput(string key, string output)
    {
        outputLines[key] = output;
    }

    public override void _Process(float delta)
    {
        float thisFrameFps = 1f / delta;
        currentFps = Mathf.Lerp(currentFps, thisFrameFps, .1f);

        float t = currentFps / Engine.TargetFps;
        Color c = fpsGradient.Interpolate(t);

        BbcodeText = System.String.Join("\n", outputLines.Values);

        outputLines.Clear();

        AddOutput("FPS",
            "FPS: [color=#" + c.ToHtml() + "]" + Mathf.CeilToInt(currentFps) + "[/color]"
        );

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
        }
    }
}
