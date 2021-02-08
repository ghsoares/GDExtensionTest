using Godot;
using System;
using ExtensionMethods.RandomMethods;

[Tool]
public class EmitTexture : ParticleSystemModule
{
    private Texture _texture;
    private int imgSizeX;
    private int imgSizeY;
    private Color[] sampledPoints;

    [Export]
    public Texture texture {
        get {
            return _texture;
        }
        set {
            _texture = value;
            SamplePoints();
        }
    }
    [Export]
    public Vector2 scale = Vector2.One;

    private void SamplePoints() {
        if (texture == null) {
            sampledPoints = null;
            return;
        }
        Image img = texture.GetData();
        Vector2 imgSize = img.GetSize();
        imgSizeX = Mathf.FloorToInt(imgSize.x);
        imgSizeY = Mathf.FloorToInt(imgSize.x);
        sampledPoints = new Color[imgSizeX * imgSizeY];

        img.Lock();

        for (int y = 0; y < imgSizeY; y++) {
            for (int x = 0; x < imgSizeX; x++) {
                sampledPoints[x + y * imgSizeY] = img.GetPixel(x, y);
            }
        }

        img.Unlock();
    }

    public override void InitParticle(ref ParticleSystem2D.Particle p, ParticleSystem2D.EmitParams emitParams) {
        if (sampledPoints == null || imgSizeX == 0 || imgSizeY == 0) return;

        Random r = particleSystem.random;

        int x = r.Next(0, imgSizeX);
        int y = r.Next(0, imgSizeY);

        Color c = p.baseColor * sampledPoints[x + y * imgSizeY];

        p.baseColor = c;
        p.color = c;
        p.position += new Vector2(x - imgSizeX / 2f, y - imgSizeY / 2f) * scale;
    }
}
