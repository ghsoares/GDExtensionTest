using Godot;
using System.Collections.Generic;

public class UI : CanvasLayer
{
    private Control nextLevelInput {get; set;}
    private Control resetLevelInput {get; set;}
    private TextLabel scoreLabel {get; set;}
    private TextLabel playerSpeedLabel {get; set;}
    private TextLabel playerFuelLabel {get; set;}
    private Control playerSpeedWarning {get; set;}
    private Control playerFuelWarning {get; set;}
    private RichTextLabel debugLabel {get; set;}
    private Control pauseText {get; set;}
    private bool pausing {get; set;}
    private bool unPausing {get; set;}

    [Export]
    public Gradient playerSpeedGradient;
    [Export]
    public Gradient playerFuelGradient;
    [Export(PropertyHint.Range, "0,1")]
    public float fuelWarningAtPercentage = .1f;

    public override void _Ready() {
        nextLevelInput = GetNode<Control>("Input/Next");
        resetLevelInput = GetNode<Control>("Input/Reset");
        debugLabel = GetNode<RichTextLabel>("Debug");
        pauseText = GetNode<Control>("Pause/Text");

        scoreLabel = GetNode<TextLabel>("GUI/Score/Value");
        playerSpeedLabel = GetNode<TextLabel>("GUI/Stats/Speed/Value");
        playerFuelLabel = GetNode<TextLabel>("GUI/Stats/Fuel/Value");

        playerSpeedWarning = playerSpeedLabel.GetNode<Control>("../Warning");
        playerFuelWarning = playerFuelLabel.GetNode<Control>("../Warning");
    }

    public override void _Process(float delta) {
        nextLevelInput.Visible = Player.main.landed;
        resetLevelInput.Visible = Player.main.dead;

        List<string> debugText = new List<string>();

        debugText.Add("FPS: " + Performance.GetMonitor(Performance.Monitor.TimeFps));
        if (OS.GetName() == "Windows") {
            debugText.Add("Window Size: " + OS.WindowSize);
        } else {
            debugText.Add("Screen Size: " + OS.GetScreenSize());
        }

        debugLabel.Text = string.Join("\n", debugText);

        if (Input.IsActionJustPressed("game_pause")) {
            GetTree().Paused = !GetTree().Paused;
            pauseText.Visible = GetTree().Paused;
        }

        PlayerGUIProcess(delta);
    }

    private void PlayerGUIProcess(float delta) {
        float currentPlayerSpeed = Player.main.currentSpeed.Length();
        float currentPlayerFuel = Player.main.currentFuel;

        scoreLabel.text = Game.main.totalScore.ToString();
        playerSpeedLabel.text = currentPlayerSpeed.ToString("F0");
        playerFuelLabel.text = currentPlayerFuel.ToString("F0") + "/" + Player.main.maxFuel.ToString("F0");

        float playerSpeedP = Mathf.InverseLerp(Player.main.scoreMinSpeed, Player.main.explodeAtSpeed, currentPlayerSpeed);
        float playerFuelP = Mathf.InverseLerp(Player.main.maxFuel * fuelWarningAtPercentage, Player.main.maxFuel, currentPlayerFuel);

        Color speedC = playerSpeedGradient.Interpolate(Mathf.Clamp(playerSpeedP, 0, 1));
        Color fuelC = playerFuelGradient.Interpolate(1f - Mathf.Clamp(playerFuelP, 0, 1));

        playerSpeedLabel.color = speedC;
        playerFuelLabel.color = fuelC;

        playerSpeedWarning.Visible = playerSpeedP >= 1f;
        playerFuelWarning.Visible = playerFuelP <= 0f;
    }
}
