#pragma warning disable 4014

using Godot;
using System.Collections.Generic;
using ExtensionMethods.RandomMethods;

public class World : Control
{
    public struct HeightMapHit {
        public Vector2 point;
        public Vector2 normal;
        public float travel;
    }

    public static World main {get; private set;}
    public float highestPoint = 0f;
    public bool generating {get; private set;}
    public int level {get; set;}

    private Platform[] platforms;
    private System.Random random;
    private ColorRect terrainVisual;
    private Node2D platformsRoot;
    private Node2D popupsRoot;

    [Export]
    public int planetSeed = 1337;
    [Export]
    public float planetSurfaceLuminanceThreshold = .75f;
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
    public PackedScene platformScene;
    [Export]
    public PackedScene popupScene;
    [Export]
    public Color surfaceColor = Colors.White;

    [Signal]
    delegate void OnLevelStart();

    public World() {
        main = this;
    }

    public override void _ExitTree() {
        main = null;
    }

    public override void _Ready() {
        terrainVisual = GetNode<ColorRect>("Terrain");
        platformsRoot = GetNode<Node2D>("Platforms");
        popupsRoot = GetNode<Node2D>("Popups");
        level = 0;
        RandomNoises();
        RandomPlanet();
        GeneratePlatforms();
        Generate();
        EmitSignal("OnLevelStart");
    }

    public async void NextLevel() {
        if (generating) return;
        generating = true;
        await GameMain.main.TransitionIn();
        level++;
        RandomNoises();
        if (level % 5 == 0) {
            RandomPlanet();
        }
        GeneratePlatforms();
        Generate();
        EmitSignal("OnLevelStart");
        generating = false;
        GameMain.main.TransitionOut();
    }

    public async void ResetLevel() {
        if (generating) return;
        generating = true;
        await GameMain.main.TransitionIn();
        EmitSignal("OnLevelStart");
        generating = false;
        GameMain.main.TransitionOut();
    }

    public void Generate()
    {
        foreach (Node c in popupsRoot.GetChildren()) {
            c.QueueFree();
        }

        highestPoint = 0f;

        ShaderMaterial terrainMaterial = terrainVisual.Material as ShaderMaterial;

        int size = Mathf.FloorToInt(terrainSize.x * resolution);

        Image bufferImg = new Image();
        bufferImg.Create(size, 1, false, Image.Format.Rf);
        bufferImg.Lock();

        for (int i = 0; i < size; i++)
        {
            float x = i / resolution;
            float h = SampleHeight(x);

            if (h > highestPoint) highestPoint = h;

            float hFloat = h / terrainSize.y;
            
            bufferImg.SetPixel(i, 0, new Color(hFloat, 0, 0));
        }

        bufferImg.Unlock();

        ImageTexture tex = new ImageTexture();
        tex.CreateFromImage(bufferImg, (uint)Texture.FlagsEnum.Filter);

        terrainMaterial.SetShaderParam("terrainHeightMap", tex);
        terrainMaterial.SetShaderParam("terrainSize", terrainSize);
        RectSize = terrainSize;

        if (!Engine.EditorHint) {
            float playerPos = terrainSize.x / 2f;
            Player.main.GlobalPosition = new Vector2(
                playerPos, Player.main.GlobalPosition.y
            );
        }
    }

    private void GeneratePlatforms()
    {
        foreach (Node c in platformsRoot.GetChildren()) {
            c.QueueFree();
        }

        int numPlatforms = 5;
        platforms = new Platform[numPlatforms];
        List<int> platformScoreMultipliers = new List<int>();

        float totalSpacing = 0f;

        for (int i = 0; i < numPlatforms; i++) {
            platformScoreMultipliers.Add(2 + (i % 4));
        }

        for (int i = 0; i < numPlatforms; i++) {
            float spacing = Mathf.Lerp(32f, 64f, random.NextFloat());
            totalSpacing += spacing;

            Platform newPlatform = platformScene.Instance() as Platform;
            newPlatform.Position = new Vector2(totalSpacing, 0);
            
            int scoreMultiplier = 0;

            if (i == numPlatforms / 2) {
                scoreMultiplier = 1;
            } else {
                int scoreIdx = random.Next(0, platformScoreMultipliers.Count);
                scoreMultiplier = platformScoreMultipliers[scoreIdx];
                platformScoreMultipliers.RemoveAt(scoreIdx);
            }

            newPlatform.size = new Vector2(22f + (5 - scoreMultiplier) * 6f, 0f);
            newPlatform.scoreMultiplier = scoreMultiplier;

            platforms[i] = newPlatform;
        }

        totalSpacing += Mathf.Lerp(32f, 64f, random.NextFloat());

        for (int i = 0; i < numPlatforms; i++) {
            Platform p = platforms[i];
            Vector2 pos = p.Position;

            float t = p.Position.x / totalSpacing;
            pos.x = terrainSize.x * t;
            pos.x = Mathf.Floor(pos.x);

            p.Position = pos;
            platforms[i] = p;
        }

        foreach (Platform p in platforms) {
            float sizeX = p.size.x;
            float sizeY = 3f;

            float posX = p.Position.x;
            float posY = terrainSize.y - SampleHeight(posX);

            p.Position = new Vector2(posX, posY);
            p.size = new Vector2(sizeX, sizeY);

            platformsRoot.AddChild(p);
        }
    }

    private void RandomPlanet() {
        ShaderMaterial terrainMaterial = terrainVisual.Material as ShaderMaterial;

        planetSeed = new System.Random().Next();
        System.Random r = new System.Random();

        surfaceColor = Color.FromHsv(
            r.NextFloat(),
            Mathf.Lerp(.5f, .6f, r.NextFloat()),
            Mathf.Lerp(.9f, 1f, r.NextFloat())
        );
        float lum = 0.2126f*surfaceColor.r + 0.7152f*surfaceColor.g + 0.0722f*surfaceColor.b;
        while (lum >= planetSurfaceLuminanceThreshold) {
            surfaceColor = Color.FromHsv(
                r.NextFloat(),
                Mathf.Lerp(.5f, .6f, r.NextFloat()),
                Mathf.Lerp(.9f, 1f, r.NextFloat())
            );
            lum = 0.2126f*surfaceColor.r + 0.7152f*surfaceColor.g + 0.0722f*surfaceColor.b;
        }
        Color complementary = surfaceColor;
        float diff = Mathf.Lerp(.15f, .3f, r.NextFloat());
        complementary.h += diff;
        complementary.s += diff;
        complementary.v -= diff;

        int numColors = 5;

        float[] offsets = new float[numColors];
        Color[] colors = new Color[numColors];

        for (int i = 0; i < numColors; i++) {
            float t = (float)i / (numColors - 1);
            offsets[i] = 1f - t;
            Color c = surfaceColor;

            float fromAngle = c.h * Mathf.Pi * 2f;
            float toAngle = complementary.h * Mathf.Pi * 2f;
            float hue = Mathf.LerpAngle(fromAngle, toAngle, t) / (Mathf.Pi * 2f);

            c.h = hue;
            c.s = Mathf.Lerp(c.s, complementary.s, t);
            c.v = Mathf.Lerp(c.v, complementary.v, t);
            colors[i] = c;
        }

        Gradient grad = new Gradient();
        grad.Offsets = offsets;
        grad.Colors = colors;

        GradientTexture tex = new GradientTexture();
        tex.Gradient = grad;

        terrainNoise.Octaves = r.Next(1, 4);
        terrainNoise.Period = r.NextFloat(200, 300);
        terrainNoise.Persistence = r.NextFloat(.4f, .6f);
        terrainNoise.Lacunarity = r.NextFloat(1.5f, 2.5f);
        
        terrainMaterial.SetShaderParam("terrainGradient", tex);
    }

    private void RandomNoises() {
        int seed = new System.Random().Next();
        terrainNoise.Seed = seed;
        random = new System.Random(seed);
    }

    public PopupText PopupText() {
        Node2D popupRoot = GetNode<Node2D>("Popups");

        PopupText newPopup = popupScene.Instance() as PopupText;
        popupRoot.AddChild(newPopup);
        
        return newPopup;
    }

    public float SampleHeight(float x)
    {
        float h = (terrainNoise.GetNoise1d(x) + 1f) / 2f;
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

            float pH1 = (terrainNoise.GetNoise1d(rangeMin) + 1f) / 2f;
            float pH2 = (terrainNoise.GetNoise1d(rangeMax) + 1f) / 2f;
            float pH = (pH1 + pH2) / 2f;
            pH *= height;
            pH += heightOffset;
            pH = Mathf.Floor(pH);
            h = Mathf.Lerp(h, pH, t);
        }

        h = Mathf.Clamp(h, 1f, terrainSize.y);
        return h;
    }

    public float SamplePositionY(float x) {
        return terrainSize.y - SampleHeight(x);
    }

    public Vector2 SampleNormal(float x)
    {
        float spacing = 1f;
        float hl = (SampleHeight(x - spacing));
        float hr = (SampleHeight(x + spacing));
        Vector2 n = new Vector2(hl - hr, -1f).Normalized();
        return n;
    }

    public HeightMapHit IntersectRay(Vector2 from, Vector2 direction, float maxDistance = -1f, float hitThreshold = 1f, int maxIterations = 32) {
        HeightMapHit hit = new HeightMapHit();
        hit.point = from;

        for (int i = 0; i < maxIterations; i++) {
            float posY = SamplePositionY(hit.point.x);
            float diff = posY - hit.point.y;

            if (Mathf.Abs(diff) > hitThreshold) {
                hit.point += direction * diff;
                hit.travel += diff;
            } else {
                break;
            }
        }

        hit.normal = SampleNormal(hit.point.x);

        return hit;
    }

    public Platform GetPlatformOnX(float x) {
        foreach (Platform p in platforms) {
            float rangeMin = p.Position.x - p.size.x / 2f;
            float rangeMax = p.Position.x + p.size.x / 2f;

            if (x >= rangeMin && x <= rangeMax) return p;
        }
        return null;
    }

    public void GetBetweenPlatforms(float x, out Platform min, out Platform max) {
        float minX = -1f;
        float maxX = terrainSize.x + 1f;
        int minIdx = 0;

        for (int i = 0; i < platforms.Length; i++) {
            Platform p = platforms[i];
            
            if (p.Position.x >= minX && p.Position.x <= x) minIdx = i;
        }

        if (minIdx == platforms.Length - 1) {
            minIdx--;
        }

        min = platforms[minIdx+0];
        max = platforms[minIdx+1];
    }

    public Platform GetNearestPlatform(float x) {
        Platform nearest = platforms[0];
        float dist = Mathf.Abs(nearest.Position.x - x);

        for (int i = 1; i < platforms.Length; i++) {
            Platform p = platforms[i];
            float thisDist = Mathf.Abs(p.Position.x - x);
            if (thisDist < dist) {
                nearest = p;
                dist = thisDist;
            }
        }

        return nearest;
    }
}
