using System;
using System.Threading.Tasks;
using Godot;

public class LevelTransition : CanvasLayer
{
    public static LevelTransition instance;

    private ShaderMaterial transitionMaterial { get; set; }
    private Tween tw { get; set; }
    private bool isAnimating { get; set; }

    [Signal] delegate void AnimatedIn();
    [Signal] delegate void AnimatedOut();

    public LevelTransition()
    {
        instance = this;
    }

    public override void _Ready()
    {
        transitionMaterial = GetNode<ColorRect>("Color").Material as ShaderMaterial;
        tw = GetNode<Tween>("Tw");

    }

    public void AnimateIn() {
        tw.StopAll();
        tw.InterpolateProperty(
            transitionMaterial, "shader_param/transition", 0f, 1f, 1f
        );
        tw.Start();
    }

    public void AnimateOut() {
        tw.StopAll();
        tw.InterpolateProperty(
            transitionMaterial, "shader_param/transition", 1f, 0f, 1f
        );
        tw.Start();
    }

    public async Task AsyncAnimateIn()
    {
        if (isAnimating) return;
        isAnimating = true;
        
        AnimateIn();

        await ToSignal(tw, "tween_completed");

        EmitSignal("AnimatedIn");
        isAnimating = false;
    }

    public async Task AsyncAnimateOut()
    {
        if (isAnimating) return;
        isAnimating = true;
        
        AnimateOut();
        
        await ToSignal(tw, "tween_completed");
        
        EmitSignal("AnimatedOut");
        isAnimating = false;
    }
}
