using Godot;
using System;

[Tool]
public class TextLabel : Control
{
    private string _text = "New Text";
    private DynamicFont _font;
    private float _fitHeight = 16f;
    private Label.AlignEnum _hAlign = Label.AlignEnum.Left;
    private Label.VAlign _vAlign = Label.VAlign.Top;
    private Color _color = Colors.Black;

    [Export(PropertyHint.MultilineText, "")]
    public string text
    {
        get
        {
            return _text;
        }
        set
        {
            _text = value;
            Update();
        }
    }
    [Export]
    public DynamicFont font
    {
        get
        {
            return _font;
        }
        set
        {
            _font = value;
            Update();
        }
    }
    [Export]
    public float fitHeight
    {
        get
        {
            return _fitHeight;
        }
        set
        {
            _fitHeight = value;
            Update();
        }
    }
    [Export]
    public Label.AlignEnum hAlign {
        get {
            return _hAlign;
        }
        set {
            _hAlign = value;
            Update();
        }
    }
    [Export]
    public Label.VAlign vAlign {
        get {
            return _vAlign;
        }
        set {
            _vAlign = value;
            Update();
        }
    }
    [Export]
    public Color color
    {
        get
        {
            return _color;
        }
        set
        {
            _color = value;
            Update();
        }
    }

    public override void _Draw()
    {
        if (font == null) return;
        float fontSize = font.Size - font.GetDescent();

        float s = fitHeight / fontSize;
        Transform2D t = Transform2D.Identity;
        t.Scale = Vector2.One * s;
        t.origin = Vector2.Up * 4;

        Vector2 textSize = font.GetStringSize(text);

        switch (vAlign) {
            case Label.VAlign.Top: {
                t.origin += Vector2.Down * textSize * s;
                break;
            }
            case Label.VAlign.Center: {
                t.origin = Vector2.Down * textSize.y * s * .5f;
                t.origin += Vector2.Down * RectSize.y * .5f;
                break;
            }
            case Label.VAlign.Bottom: {
                t.origin += Vector2.Down * RectSize.y;
                break;
            }
        }
        switch (hAlign) {
            case Label.AlignEnum.Center: {
                t.origin -= Vector2.Right * textSize.x * s * .5f;
                t.origin += Vector2.Right * RectSize.x * .5f;
                break;
            }
            case Label.AlignEnum.Right: {
                t.origin -= Vector2.Right * textSize.x * s;
                t.origin += Vector2.Right * RectSize.x;
                break;
            }
        }

        DrawSetTransformMatrix(t);

        DrawString(font, Vector2.Zero, text, color);
    }
}
