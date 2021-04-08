using System;
using Godot;

public class Terrain : ColorRect
{
    public Planet planet;

    public OpenSimplexNoise noise;
    public TerrainCollision collision;
    public float height = 128f;
    public float heightOffset = 128f;
    public float visualResolution = 1f / 4f;
    public float collisionResolution = 1f / 4f;
    public float platformHeightInterpolationSize = 64f;
    public float platformHeightInterpolationCurve = -2f;

    public float SampleNoise(float x)
    {
        float h = noise.GetNoise1d(x) * .5f + .5f;
        h *= height;
        h += heightOffset;
        return Mathf.Clamp(h, 0f, planet.size.y);
    }

    public float GetTerrainHeight(float x)
    {
        float h = SampleNoise(x);

        foreach (Platform platform in planet.platformPlacer.platforms)
        {
            float dist = platform.GetDistanceX(x);
            if (dist <= platformHeightInterpolationSize)
            {
                float t = 1f - dist / platformHeightInterpolationSize;
                t = Mathf.Ease(t, platformHeightInterpolationCurve);

                float platH = SampleNoise(platform.GlobalPosition.x);
                platH = Mathf.Floor(platH);

                if (dist > 0f)
                {
                    h = Mathf.Lerp(h, platH, t);
                }
                else
                {
                    h = platH;
                }
            }
        }

        return h;
    }

    public float GetTerrainY(float x)
    {
        float h = GetTerrainHeight(x);
        return planet.size.y - h;
    }

    public Vector2 GetTerrainNormal(float x)
    {
        float spacing = .1f;
        float tang = (GetTerrainHeight(x) - GetTerrainHeight(x + spacing)) / spacing;
        return new Vector2(tang, -1f).Normalized();
    }

    public ImageTexture GenerateTexture()
    {
        Image img = new Image();
        ImageTexture imgTexture = new ImageTexture();

        float resolution = visualResolution;
        int width = Mathf.CeilToInt(planet.size.x * resolution);

        img.Create(width, 1, false, Image.Format.Rf);
        img.Lock();

        for (int i = 0; i < width; i++)
        {
            float x = i / resolution;
            x = Mathf.Min(x, planet.size.x);
            float h = GetTerrainHeight(x) / planet.size.y;
            img.SetPixel(i, 0, new Color(h, 0, 0));
        }

        img.Unlock();
        imgTexture.CreateFromImage(img, 0);

        return imgTexture;
    }

    public void Generate()
    {
        RectSize = planet.size;

        ShaderMaterial mat = Material as ShaderMaterial;
        if (mat != null)
        {
            ImageTexture terrainTex = GenerateTexture();
            mat.SetShaderParam("terrainHeightMap", terrainTex);
            mat.SetShaderParam("terrainSize", planet.size);
            mat.SetShaderParam("terrainResolution", visualResolution);
        }

        if (collision == null)
        {
            collision = new TerrainCollision();
            collision.planet = planet;
            collision.terrain = this;
            AddChild(collision);
        }

        collision.Generate();
    }
}
