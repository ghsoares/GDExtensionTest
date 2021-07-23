using ExtensionMethods.ColorMethods;
using Godot;
using System;
using System.Collections.Generic;

public class Terrain : Spatial
{
    public TerrainCollision collision {get; private set;}
    public MeshInstance view {get; private set;}
    public Mesh viewMesh {get; private set;}
    public Planet planet {get; set;}

    public OpenSimplexNoise noise {get; set;}
    public float height {get; set;}
    public float heightOffset {get; set;}
    public float visualResolution {get; set;}
    public float collisionResolution {get; set;}
    public Material material {get; set;}

    public Terrain() {
        noise = new OpenSimplexNoise {Period = 200f, Octaves = 1};

        height = 400f;
        heightOffset = 100f;
        visualResolution = 1f / 8f;
        collisionResolution = 1f / 8f;
    }

    public override void _Ready()
    {
        collision = GetNode<TerrainCollision>("Body");
        view = GetNode<MeshInstance>("View");
    }

    public float SampleNoise(float x) {
        float h = noise.GetNoise1d(x);
        h = h * .5f + .5f;
        h *= height;
        h += heightOffset;
        return Mathf.Clamp(h, 0f, planet.totalSize.y);
    }

    public float GetTerrainHeight(float x)
    {
        float h = SampleNoise(x);

        return h;
    }

    public float GetTerrainY(float x)
    {
        float h = GetTerrainHeight(x);
        return planet.totalSize.y - h;
    }

    public Vector2 GetTerrainNormal(float x)
    {
        float spacing = .1f;
        float tang = (GetTerrainHeight(x) - GetTerrainHeight(x + spacing)) / spacing;
        return new Vector2(tang, -1f).Normalized();
    }

    /*
    public ImageTexture GenerateTexture()
    {
        Image img = new Image();
        ImageTexture imgTexture = new ImageTexture();

        float resolution = visualResolution;
        int width = Mathf.CeilToInt(planet.totalSize.x * resolution);

        img.Create(width, 1, false, Image.Format.Rgba8);
        img.Lock();

        for (int i = 0; i < width; i++)
        {
            float x = i / resolution;
            x = Mathf.Min(x, planet.totalSize.x);
            float h = GetTerrainHeight(x) / planet.totalSize.y;
            img.SetPixel(i, 0, new Color(h, 0, 0));
        }

        img.Unlock();
        imgTexture.CreateFromImage(img, 0);

        return imgTexture;
    }
    */

    public void BuildMesh() {
        SurfaceTool st = new SurfaceTool();
        st.Begin(Mesh.PrimitiveType.Triangles);

        float pixelSize = ModelViewComponent.pixelSize;
        int width = Mathf.CeilToInt(planet.totalSize.x * visualResolution);

        for (int i = 0; i < width - 1; i++) {
            float currX = i / visualResolution;
            float nxtX = (i+1) / visualResolution;

            float currY = GetTerrainY(currX);
            float nxtY = GetTerrainY(nxtX);

            float currUvX = (float)i / (width - 1);
            float nxtUvX = (float)(i+1) / (width - 1);

            float currUvY = currY;
            float nxtUvY = nxtY;

            // First TRI
            st.AddUv(new Vector2(currUvX, currUvY));
            st.AddVertex(new Vector3(currX, -currY, 0f) * pixelSize);
            st.AddUv(new Vector2(nxtUvX, nxtUvY));
            st.AddVertex(new Vector3(nxtX, -planet.totalSize.y, 0f) * pixelSize);
            st.AddUv(new Vector2(currUvX, currUvY));
            st.AddVertex(new Vector3(currX, -planet.totalSize.y, 0f) * pixelSize);

            // Second TRI
            st.AddUv(new Vector2(nxtUvX, nxtUvY));
            st.AddVertex(new Vector3(nxtX, -nxtY, 0f) * pixelSize);
            st.AddUv(new Vector2(nxtUvX, nxtUvY));
            st.AddVertex(new Vector3(nxtX, -planet.totalSize.y, 0f) * pixelSize);
            st.AddUv(new Vector2(currUvX, currUvY));
            st.AddVertex(new Vector3(currX, -currY, 0f) * pixelSize);
        }

        viewMesh = st.Commit();
    }

    public void Generate() {
        collision.Generate();
        BuildMesh();

        view.Mesh = viewMesh;
        view.MaterialOverride = material;

        ResourceSaver.Save("res://Models/Terrain.res", viewMesh);

        ShaderMaterial mat = material as ShaderMaterial;
        if (mat != null) {
            mat.SetShaderParam("terrainSize", planet.totalSize);
            mat.SetShaderParam("terrainResolution", visualResolution);
            mat.SetShaderParam("pixelSize", ModelViewComponent.pixelSize);
        }

        collision.Generate();
    }
}
