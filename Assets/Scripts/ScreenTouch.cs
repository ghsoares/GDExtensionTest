using Godot;
using System;

public class ScreenTouch : Control
{
    private bool _holding;
    private ShaderMaterial _shaderMaterial;
    private int touchId;
    public bool holding
    {
        get
        {
            return _holding;
        }
        private set
        {
            if (_holding != value)
            {
                _holding = value;
                if (value)
                {
                    if (OS.GetName() == "Android" || OS.GetName() == "iOS") Input.VibrateHandheld(25);
                    if (invert) {
                        Input.ActionRelease(action);
                    } else {
                        Input.ActionPress(action);
                    }
                }
                else
                {
                    if (invert) {
                        Input.ActionPress(action);
                    } else {
                        Input.ActionRelease(action);
                    }
                }
            }
        }
    }
    public ShaderMaterial shaderMaterial
    {
        get
        {
            if (Material != null && _shaderMaterial == null) {
                _shaderMaterial = Material as ShaderMaterial;
            }
            return _shaderMaterial;
        }
    }

    [Export]
    public string action;
    [Export]
    public Color pressedColor = Colors.White;
    [Export]
    public Color releasedColor = new Color(1f, 1f, 1f, .5f);
    [Export]
    public bool invert;
    [Export]
    public float colorLerp = 4f;

    public override void _Process(float delta)
    {
        if (Input.IsActionPressed(action)) {
            Modulate = Modulate.LinearInterpolate(pressedColor, Mathf.Clamp(colorLerp * delta, 0, 1));
        } else {
            Modulate = Modulate.LinearInterpolate(releasedColor, Mathf.Clamp(colorLerp * delta, 0, 1));
        }

        if (shaderMaterial != null) {
            shaderMaterial.SetShaderParam("size", RectSize);
        }
    }

    public override void _Input(InputEvent ev)
    {
        if (!Visible)
        {
            holding = false;
            return;
        }

        if (!(ev is InputEventScreenTouch)) return;
        InputEventScreenTouch evTouch = (InputEventScreenTouch)ev;
        if (evTouch.Pressed)
        {
            if (GetRect().HasPoint(evTouch.Position))
            {
                holding = true;
                touchId = evTouch.Index;
            }
        }
        else
        {
            if (evTouch.Index == touchId)
            {
                touchId = -1;
                holding = false;
            }
        }
    }
}
