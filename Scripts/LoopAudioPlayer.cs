using Godot;
using System;

public class LoopAudioPlayer : AudioStreamPlayer
{
    [Export] public AudioStream fadeIn;
    [Export] public AudioStream loop;

    public override void _Ready() {
        
    }
}
