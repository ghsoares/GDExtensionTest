using Godot;
using System;

public class GameMain : Control
{
    public static GameMain main {get; private set;}
    public AnimationPlayer transitionAnim {get; private set;}

    private bool isChangingScene = false;
    private Node sceneRoot;
    private Node currentScene;

    [Export]
    public PackedScene startScene;

    public GameMain() {
        main = this;
    }

    public override void _Ready() {
        transitionAnim = GetNode<AnimationPlayer>("Top/Transition/Anim");
        sceneRoot = GetNode<Node>("Scene");

        GoToScene(startScene, true);
    }

    public async void GoToScene(PackedScene scene, bool animate = true) {
        if (isChangingScene) return;
        isChangingScene = true;

        if (animate) await TransitionIn();

        if (currentScene != null) currentScene.QueueFree();

        currentScene = scene.Instance();
        sceneRoot.AddChild(currentScene);

        if (animate) await TransitionOut();
        
        isChangingScene = false;
    }

    public SignalAwaiter TransitionIn() {
        transitionAnim.Play("In");
        return ToSignal(transitionAnim, "animation_finished");
    }

    public SignalAwaiter TransitionOut() {
        transitionAnim.Play("Out");
        return ToSignal(transitionAnim, "animation_finished");
    }
}
