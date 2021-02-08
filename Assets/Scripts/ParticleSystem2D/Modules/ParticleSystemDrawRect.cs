using Godot;
using ExtensionMethods.Transform2DMethods;

[Tool]
public class ParticleSystemDrawRect : ParticleSystemModule
{
    private Rect2 globalViewRect { get; set; }

    [Export]
    public Texture tex;
    [Export]
    public Texture normalMap;
    [Export]
    public bool culling = true;

    public override void UpdateModule(float delta)
    {
        if (culling)
        {
            Viewport v = GetViewport();
            Rect2 localViewRect = new Rect2(0, 0, v.Size);
            Transform2D gViewTransform = v.GlobalCanvasTransform.AffineInverse();
            if (Engine.EditorHint) {
                gViewTransform = v.GlobalCanvasTransform.AffineInverse();
            }

            globalViewRect = gViewTransform.Xform(new Rect2(0, 0, v.Size));
        }
    }

    public override void DrawModule()
    {
        if (particleSystem.debugMode) {
            particleSystem.DrawRect(globalViewRect, new Color(0, 0, 1f, .5f));
        }
    }

    public override void DrawParticle(ParticleSystem2D.Particle p)
    {
        Rect2 drawRect = p.drawRect;
        Rect2 globalRect = p.drawRect;
        bool render = true;

        if (particleSystem.spaceMode == ParticleSystem2D.SpaceMode.Local)
        {
            globalRect = particleSystem.GlobalTransform.Xform(globalRect);
        }

        if (culling)
        {
            if (!globalViewRect.Intersects(globalRect))
            {
                render = false;
            }
        }

        if (!particleSystem.debugMode)
        {
            if (render)
            {
                if (tex != null)
                {
                    particleSystem.DrawTextureRect(tex, drawRect, false, p.color, false, normalMap);
                }
                else
                {
                    particleSystem.DrawRect(drawRect, p.color, true);
                }
            }
        }

        if (particleSystem.debugMode)
        {
            particleSystem.DrawRect(
                globalRect, new Color(1f, 0, 0, .25f)
            );
        }
    }
}