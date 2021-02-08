using Godot;
using System;

public class ScreenTouch : Control
{
    private bool _holding;
    private ShaderMaterial _shaderMaterial;
    private Color desiredColor;
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
                    desiredColor = pressedColor;
                }
                else
                {
                    if (invert) {
                        Input.ActionPress(action);
                    } else {
                        Input.ActionRelease(action);
                    }
                    desiredColor = releasedColor;
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

    public override void _Ready()
    {
        desiredColor = releasedColor;
        Modulate = releasedColor;
    }

    public override void _Process(float delta)
    {
        Modulate = Modulate.LinearInterpolate(desiredColor, 4f * delta);

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
