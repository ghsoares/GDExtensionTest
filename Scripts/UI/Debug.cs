using Godot;
using System;

public class Debug : RichTextLabel
{
    public override void _Process(float delta)
    {
        BbcodeText = "";
        BbcodeText += "[color=#00f2ff]Player Fuel: [/color]" +
            Mathf.CeilToInt(PlayerData.sessionCurrentFuel) +
            " / " +
            Mathf.CeilToInt(PlayerData.maxFuel);
        if (Player.instance != null && Player.instance.IsInsideTree()) {
            BbcodeText += "\n";
            BbcodeText += "[color=#00f2ff]Player Position: [/color]" +
                Player.instance.GlobalPosition;
        }
    }
}
