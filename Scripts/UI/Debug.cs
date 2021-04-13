using Godot;
using System.Collections.Generic;

public class Debug : RichTextLabel
{
    float currentFps {get; set;}

    [Export] public Gradient fpsGradient;

    public override void _Process(float delta)
    {
        float thisFrameFps = 1f / delta;
        currentFps = Mathf.Lerp(currentFps, thisFrameFps, .1f);

        float t = currentFps / Engine.TargetFps;
        Color c = fpsGradient.Interpolate(t);

        List<string> outputLines = new List<string>();

        outputLines.Add(
            "FPS: [color=#" + c.ToHtml() + "]" + Mathf.CeilToInt(currentFps) + "[/color]"
        );

        outputLines.Add(
            "[color=#00f2ff]Player Fuel: [/color]" +
            Mathf.CeilToInt(PlayerData.sessionCurrentFuel) +
            " / " +
            Mathf.CeilToInt(PlayerData.maxFuel)
        );
        if (Player.instance != null && Player.instance.IsInsideTree()) {
            outputLines.Add(
                "[color=#00f2ff]Player Position: [/color]" +
                Player.instance.GlobalPosition
            );
        }

        BbcodeText = System.String.Join("\n", outputLines);
    }
}
