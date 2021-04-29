using Godot;
using System;

public class LoopAudioPlayer : Node
{
    public AudioStreamPlayer fadeInPlayer {get; private set;}
    public AudioStreamPlayer loopPlayer {get; private set;}
    private uint fadeStartTime {get; set;}
    private float fadeLength {get; set;}

    [Export] public AudioStream fadeInStream;
    [Export] public AudioStream loopStream;
    [Export] public bool autoplay = false;

    public override void _Ready() {
        fadeInPlayer = new AudioStreamPlayer();
        loopPlayer = new AudioStreamPlayer();
        fadeInPlayer.Stream = fadeInStream;
        loopPlayer.Stream = loopStream;
        AddChild(fadeInPlayer);
        AddChild(loopPlayer);

        if (autoplay) Play();
    }

    public void Play() {
        fadeInPlayer.Play();
        fadeStartTime = OS.GetTicksMsec();
        fadeInPlayer.Connect("finished", this, "OnFadeFinished");
        fadeLength = fadeInStream.GetLength();
    }

    public void OnFadeFinished() {
        uint current = OS.GetTicksMsec();
        float passedSeconds = (current - fadeStartTime) / 1000f;
        float extrapolate = passedSeconds - fadeLength;
        loopPlayer.Play(extrapolate);
        fadeInPlayer.Disconnect("finished", this, "OnFadeFinished");
    }
}
