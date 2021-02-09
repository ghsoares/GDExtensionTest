using Godot;
using System.Linq;
using ExtensionMethods.IEnumerableMethods;

public class Game : Control
{
    private int _totalScore;

    public static Game main { get; private set; }
    public Viewport view { get; private set; }
    public AnimationPlayer transitionAnim {get; private set;}
    public WorldCamera worldCamera { get; private set; }
    public Camera2D zoomCamera { get; private set; }
    public Vector2 targetPosition { get; set; }
    public int totalScore {
        get {
            return _totalScore;
        }
        set {
            _totalScore = Mathf.Max(value, 0);
        }
    }

    private float terrainOffset = 0f;
    private float highestPoint = 0f;
    private Platform[] platforms;

    [Export]
    public OpenSimplexNoise terrainNoise;
    [Export]
    public Vector2 terrainSize = new Vector2(640, 320);
    [Export]
    public float platformInterpolationSize = 16f;
    [Export(PropertyHint.ExpEasing)]
    public float platformInterpolationEasing = 1f;
    [Export]
    public float resolution = 1;
    [Export]
    public float height = 100f;
    [Export]
    public float heightOffset = 100f;
    [Export]
    public float gravity = 98f;
    [Export]
    public float cameraTransitionLen = 64f;
    [Export]
    public Curve cameraTransitionCurve;
    [Export]
    public Vector2 zoomRange = new Vector2(2f, 1f);
    [Export]
    public PackedScene platformScene;
    [Export]
    public PackedScene scoreScene;
    [Export]
    public float pixelSize = 2f;
    [Export]
    public Color surfaceColor = Colors.White;

    [Signal]
    public delegate void OnReset();

    public Game()
    {
        main = this;
    }

    public override void _Ready()
    {
        terrainNoise.Seed = new System.Random().Next();

        Engine.TimeScale = 1.25f;
        view = GetNode<Viewport>("View");
        worldCamera = GetNode<WorldCamera>("View/Cam");
        zoomCamera = GetNode<Camera2D>("Cam");

        transitionAnim = GetNode<AnimationPlayer>("UI/Transition/Anim");
        transitionAnim.Play("Out");
        Generate();
    }

    private void Generate()
    {
        if (terrainNoise == null) return;
        highestPoint = 0f;

        Control world = GetNode<Control>("View/World");
        Control terrainVisual = world.GetNode<Control>("Terrain");
        ShaderMaterial terrainMaterial = terrainVisual.Material as ShaderMaterial;

        GeneratePlatforms();

        int size = Mathf.FloorToInt(terrainSize.x * resolution);

        Image bufferImg = new Image();
        bufferImg.Create(size, 1, false, Image.Format.Rf);
        bufferImg.Lock();

        for (int i = 0; i < size; i++)
        {
            float x = i / resolution;
            float h = SampleHeight(x);

            if (h > highestPoint) highestPoint = h;

            bufferImg.SetPixel(i, 0, new Color(h / terrainSize.y, 0, 0, 1f));
        }

        bufferImg.Unlock();

        ImageTexture tex = new ImageTexture();
        tex.CreateFromImage(bufferImg, 0);

        terrainMaterial.SetShaderParam("terrainHeightMap", tex);
        terrainMaterial.SetShaderParam("terrainSize", terrainSize);
        world.RectSize = terrainSize;

        float playerPos = terrainSize.x / 2f;
        Player.main.GlobalPosition = new Vector2(
            playerPos, Player.main.GlobalPosition.y
        );
    }

    private void GeneratePlatforms()
    {
        Node2D platformsRoot = GetNode<Node2D>("View/World/Platforms");
        foreach (Node c in platformsRoot.GetChildren()) {
            c.QueueFree();
        }

        platforms = new Platform[5];

        float totalSpacing = 0f;

        for (int i = 0; i < 5; i++) {
            float spacing = Mathf.Lerp(16f, 64f, terrainNoise.GetNoise2d(i * 512f, terrainOffset) * .5f + .5f);
            totalSpacing += spacing;

            Platform newPlatform = platformScene.Instance() as Platform;
            newPlatform.Position = new Vector2(totalSpacing, 0);
            newPlatform.size = new Vector2(22f + i * 6f, 0f);
            newPlatform.scoreMultiplier = 5f - i;

            platforms[i] = newPlatform;
        }

        totalSpacing += Mathf.Lerp(16f, 64f, terrainNoise.GetNoise2d(5 * 512f, terrainOffset) * .5f + .5f);

        for (int i = 0; i < 5; i++) {
            Platform p = platforms[i];
            Vector2 pos = p.Position;

            float t = p.Position.x / totalSpacing;
            pos.x = terrainSize.x * t;
            pos.x = Mathf.Floor(pos.x);

            p.Position = pos;
            platforms[i] = p;
        }

        for (int i = 0; i < 5; i++) {
            int j = Mathf.FloorToInt(Mathf.Lerp(0, 5, terrainNoise.GetNoise2d(i * 512f, terrainOffset) * .5f + .5f));
            Vector2 posA = platforms[i].Position;
            Vector2 posB = platforms[j].Position;
            platforms[i].Position = posB;
            platforms[j].Position = posA;
        }

        foreach (Platform p in platforms) {
            float sizeX = p.size.x;
            float sizeY = 3f;

            float posX = p.Position.x;
            float posY = Mathf.Floor(terrainSize.y - SampleHeight(posX));

            p.Position = new Vector2(posX, posY);
            p.size = new Vector2(sizeX, sizeY);

            platformsRoot.AddChild(p);
        }
    }

    public float SampleHeight(float x)
    {
        float h = (terrainNoise.GetNoise2d(x, terrainOffset) + 1f) / 2f;
        h *= height;
        h += heightOffset;

        foreach (Platform p in platforms) {
            float rangeMin = p.Position.x - p.size.x / 2f;
            float rangeMax = p.Position.x + p.size.x / 2f;
            if (x < rangeMin - platformInterpolationSize || x > rangeMax + platformInterpolationSize) continue;
            float t = 1f;

            if (x < rangeMin) {
                t = Mathf.InverseLerp(rangeMin - platformInterpolationSize, rangeMin, x);
            }
            if (x > rangeMax) {
                t = Mathf.InverseLerp(rangeMax + platformInterpolationSize, rangeMax, x);
            }
            t = Mathf.Ease(t, platformInterpolationEasing);

            float pH1 = (terrainNoise.GetNoise2d(rangeMin, terrainOffset) + 1f) / 2f;
            float pH2 = (terrainNoise.GetNoise2d(rangeMax, terrainOffset) + 1f) / 2f;
            float pH = (pH1 + pH2) / 2f;
            pH *= height;
            pH += heightOffset;
            h = Mathf.Lerp(h, pH, t);
        }

        h = Mathf.Clamp(h, 1f, terrainSize.y);
        return h;
    }

    public Vector2 SampleNormal(float x)
    {
        float spacing = 1f;
        float hl = (SampleHeight(x - spacing));
        float hr = (SampleHeight(x + spacing));
        Vector2 n = new Vector2(hl - hr, -1f).Normalized();
        return n;
    }

    public Platform GetPlatformOnX(float x) {
        foreach (Platform p in platforms) {
            float rangeMin = p.Position.x - p.size.x / 2f;
            float rangeMax = p.Position.x + p.size.x / 2f;

            if (x >= rangeMin && x <= rangeMax) return p;
        }
        return null;
    }

    public override void _Process(float delta)
    {
        UpdateViewport();

        worldCamera.LimitLeft = 0;
        worldCamera.LimitTop = 0;
        worldCamera.LimitRight = Mathf.FloorToInt(terrainSize.x);
        worldCamera.LimitBottom = Mathf.FloorToInt(terrainSize.y);

        zoomCamera.LimitLeft = 0;
        zoomCamera.LimitTop = 0;
        zoomCamera.LimitRight = Mathf.FloorToInt(RectSize.x);
        zoomCamera.LimitBottom = Mathf.FloorToInt(RectSize.y);
    }

    private void UpdateViewport()
    {
        view.Size = RectSize / pixelSize;
        view.SetSizeOverride(true, RectSize);
        view.SizeOverrideStretch = true;
    }

    public override void _PhysicsProcess(float delta)
    {
        float targetH = terrainSize.y - highestPoint;
        float dist = targetH - targetPosition.y;
        float t = dist / cameraTransitionLen;
        t = 1f - Mathf.Clamp(t, 0, 1);

        t = cameraTransitionCurve.Interpolate(t);

        float z = Mathf.Lerp(zoomRange.x, zoomRange.y, t);
        Vector2 zoom = Vector2.One * z;

        Vector2 pos = worldCamera.GlobalPosition;
        pos = pos.LinearInterpolate(targetPosition, 4f * delta);

        worldCamera.position = pos;

        zoomCamera.Zoom = zoomCamera.Zoom.LinearInterpolate(zoom, 4f * delta);

        Vector2 onViewPos = TransformBetweenViewports(worldCamera.position, worldCamera.GetViewport(), GetViewport());
        
        onViewPos.x = Mathf.Stepify(onViewPos.x, z);
        onViewPos.y = Mathf.Stepify(onViewPos.y, z);

        zoomCamera.Position = onViewPos;
    }

    public PopupText PopupText() {
        Node2D popupRoot = GetNode<Node2D>("View/World/Popups");

        PopupText newPopup = scoreScene.Instance() as PopupText;
        popupRoot.AddChild(newPopup);
        
        return newPopup;
    }

    public void ResetLevel() {
        transitionAnim.Play("In");
        transitionAnim.Connect(
            "animation_finished", this, "OnTransitionAnimationFinished",
            new Godot.Collections.Array(new object[] {
                0
            })
        );
    }

    public void NextLevel() {
        transitionAnim.Play("In");
        transitionAnim.Connect(
            "animation_finished", this, "OnTransitionAnimationFinished",
            new Godot.Collections.Array(new object[] {
                1
            })
        );
    }

    private Vector2 TransformBetweenViewports(Vector2 pos, Viewport fromViewport, Viewport toViewport)
    {
        Transform2D fromT = fromViewport.GetFinalTransform() * fromViewport.CanvasTransform;
        Transform2D toT = toViewport.GetFinalTransform() * toViewport.CanvasTransform;
        pos = fromT.Xform(pos) / fromViewport.Size;
        pos *= RectSize;
        return pos;
    }

    public void OnTransitionAnimationFinished(string animName, int transitionType) {
        switch (transitionType) {
            case 0: {
                EmitSignal("OnReset");
                transitionAnim.Play("Out");
                break;
            }
            case 1: {
                terrainOffset += 64f;
                Generate();
                EmitSignal("OnReset");
                transitionAnim.Play("Out");
                break;
            }
        }
        transitionAnim.Disconnect("animation_finished", this, "OnTransitionAnimationFinished");
    }
}
