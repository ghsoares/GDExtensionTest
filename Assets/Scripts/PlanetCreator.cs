using Godot;
using System;
using ExtensionMethods.ColorMethods;
using ExtensionMethods.RandomMethods;

public class PlanetCreator : Godot.Object
{
    public int planetSeed;
    public Color surfaceColor;
    public Gradient planetGradient;
    public GradientTexture planetGradientTexture;
    public NoiseTexture planetTexture;
    public OpenSimplexNoise planetNoise;

    public void Random() {
        RandomSeed();
        RandomGradient();
        RandomTexture();
        RandomNoise();
    }

    public void RandomSeed() {
        Random r = new Random();
        planetSeed = r.Next();
    }

    public void RandomGradient() {
        Random r = new Random(planetSeed);
        planetGradient = new Gradient();

        Color surfaceColor = Colors.White;
        Color bottomColor = Colors.White;

        float luminanceDiff = 0f;

        int tries = 32;

        while (true) {
            Color newSurfaceColor = Color.FromHsv(
                (float)r.NextDouble(),
                Mathf.Lerp(.5f, .6f, (float)r.NextDouble()),
                Mathf.Lerp(.9f, 1f, (float)r.NextDouble())
            );
            Color newBottomColor = newSurfaceColor;

            float dir = ( newBottomColor.h - (60f/360f) );
            dir -= Mathf.Floor(dir);
            dir = Mathf.Sign(.5f - dir);
            newBottomColor.h += dir * .3f;
            newBottomColor.s += .35f;
            newBottomColor.v -= .4f;

            float surfaceLuminance = newSurfaceColor.Luminance();
            float bottomLuminance = newBottomColor.Luminance();
            float diff = Mathf.Abs(surfaceLuminance - bottomLuminance);

            if (diff > .3f) {
                surfaceColor = newSurfaceColor;
                bottomColor = newBottomColor;
                break;
            } else {
                if (diff > luminanceDiff) {
                    surfaceColor = newSurfaceColor;
                    bottomColor = newBottomColor;
                    luminanceDiff = diff;
                }
            }
            
            tries--;
            if (tries <= 0) break;
        }

        planetGradient.Offsets = new float[] {0f, 1f};
        planetGradient.Colors = new Color[] {bottomColor, surfaceColor};

        planetGradientTexture = new GradientTexture();
        planetGradientTexture.Gradient = planetGradient;

        this.surfaceColor = surfaceColor;
    }

    public void RandomTexture() {
        /*OpenSimplexNoise texNoise = new OpenSimplexNoise();
        planetTexture = new NoiseTexture();
        planetTexture.Width = 128;
        planetTexture.Height = 128;
        planetTexture.Seamless = true;*/
    }

    public void RandomNoise() {
        planetNoise = new OpenSimplexNoise();
        planetNoise.Seed = planetSeed;

        Random r = new Random(planetSeed);

        planetNoise.Octaves = r.Next(1, 4);
        planetNoise.Period = r.NextFloat(200, 300);
        planetNoise.Persistence = r.NextFloat(.4f, .6f);
        planetNoise.Lacunarity = r.NextFloat(1.5f, 2.5f);
    }
}
