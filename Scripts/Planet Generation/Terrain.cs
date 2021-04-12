using System;
using System.Collections.Generic;
using Godot;

public struct TerrainRayHit {
    public bool collided;
    public Vector2 point;
    public Vector2 normal;
    public float distance;
    public List<Vector2> steps;
}

public class Terrain : ColorRect
{
    public const int RAY_MAX_STEPS = 50;
    public const float RAY_SURFACE_DIST = 1f;

    public Planet planet;

    public OpenSimplexNoise noise;
    public TerrainCollision collision;
    public float height = 400f;
    public float heightOffset = 100f;
    public float visualResolution = 1f / 4f;
    public float collisionResolution = 1f / 4f;
    public float platformHeightInterpolationSize = 64f;
    public float platformHeightInterpolationCurve = -2f;

    public List<Rect2> mountains {get; private set;}
    public List<Rect2> valleys {get; private set;}
    public float maxY {get; private set;}
    public float minY {get; private set;}

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

    public TerrainRayHit IntersectRay(Vector2 from, Vector2 direction, float maxDistance = -1f, int maxSteps = RAY_MAX_STEPS) {
        TerrainRayHit hit = new TerrainRayHit();
        hit.steps = new List<Vector2>();

        float dO = 0f;

        for (int i = 0; i < maxSteps; i++) {
            Vector2 p = from + direction * dO;

            float tY = GetTerrainY(p.x);
            float diff = tY - p.y;

            if (Mathf.Abs(diff) > RAY_SURFACE_DIST) {
                if (diff > 0f) {
                    dO += diff;
                } else {
                    dO += diff * .25f;
                }
                hit.steps.Add(p);
            } else {
                hit.collided = true;
                hit.point = p;
                hit.distance = dO;
                hit.normal = GetTerrainNormal(p.x);
                break;
            }
            if (maxDistance >= 0f && dO >= maxDistance) break;
        }

        return hit;
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

    public void SampleMountainsAndValleys() {
        Vector2 size = planet.size;

        minY = size.y;
        maxY = 0f;

        var spaceState = GetWorld2d().DirectSpaceState;

        float spacing = 1f/visualResolution;
        float prevY = GetTerrainY(0f);
        int dir = Mathf.Sign(GetTerrainY(spacing) - prevY);
        int startDir = dir;

        Vector2 regionMin = new Vector2(0f, prevY);
        Vector2 regionMax = regionMin;

        List<Rect2> blocks = new List<Rect2>();

        for (float x = spacing; x <= size.x + spacing; x += spacing) {
            float y = GetTerrainY(x);
            int thisDir = Mathf.Sign(y - prevY);

            regionMin.y = Mathf.Min(regionMin.y, y);
            regionMax.y = Mathf.Max(regionMax.y, y);
            regionMax.x = x;

            minY = Mathf.Min(minY, y);
            maxY = Mathf.Max(maxY, y);

            if (thisDir != dir && thisDir != 0) {
                blocks.Add(new Rect2(regionMin, regionMax - regionMin));

                regionMin = new Vector2(x, y);
                regionMax = regionMin;
                dir = thisDir;
            }
            
            prevY = y;
        }

        blocks.Add(new Rect2(regionMin, regionMax - regionMin));

        mountains = new List<Rect2>();
        valleys = new List<Rect2>();

        dir = startDir;

        for (int i = 0; i < blocks.Count - 1; i++) {
            Rect2 block1 = blocks[i];
            Rect2 block2 = blocks[i+1];

            if (dir == 1) {
                float startY = Mathf.Max(block1.Position.y, block2.Position.y);
                float endY = Mathf.Max(block1.End.y, block2.End.y);
                float startX = block1.Position.x;
                float endX = block2.End.x;

                Vector2 center = new Vector2(block2.Position.x, startY);

                var ray = IntersectRay(center, Vector2.Left);
                if (ray.collided) {
                    startX = ray.point.x;
                }
                ray = IntersectRay(center, Vector2.Right);
                if (ray.collided) {
                    endX = ray.point.x;
                }

                Rect2 r = new Rect2(
                    startX,         startY,
                    endX - startX,  endY - startY
                );
                valleys.Add(r);
            }
            if (dir == -1) {
                float startY = Mathf.Min(block1.Position.y, block2.Position.y);
                float endY = Mathf.Max(block1.End.y, block2.End.y);
                float startX = block1.Position.x;
                float endX = block2.End.x;

                Rect2 r = new Rect2(
                    startX,         startY,
                    endX - startX,  endY - startY
                );
                mountains.Add(r);
            }

            dir *= -1;
        }
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
        SampleMountainsAndValleys();
    }
}
