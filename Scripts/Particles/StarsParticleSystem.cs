using Godot;
using ParticleSystem;

[Tool]
public class StarsParticleSystem : EmissionParticleSystem
{
    private Viewport view {get; set;}
    private Camera cam {get; set;}
    private Vector2 viewSize {get; set;}

    [Export] public float parallaxLength = 5f;
    [Export] public Vector2 parallaxRange = new Vector2(.1f, 0f);
    [Export] public Vector2 sizeRange = new Vector2(1f, .5f);
    [Export] public Gradient colorRange;

    protected override void InitParticle(Particle particle)
    {
        base.InitParticle(particle);

        float z = GD.Randf();

        particle.position = new Vector3(GD.Randf() * 2f - 1f, GD.Randf() * 2f - 1f, z * -parallaxLength);
        particle.scale *= Vector3.One * Mathf.Lerp(sizeRange.x, sizeRange.y, z);
        if (colorRange != null) {
            particle.color *= colorRange.Interpolate(z);
        }
    }

    protected override void UpdateSystem(float delta)
    {
        view = GetViewport();
        cam = view.GetCamera();
        viewSize = view.Size;

        base.UpdateSystem(delta);
    }

    protected override void UpdateParticle(Particle particle, float delta)
    {
        base.UpdateParticle(particle, delta);

        Vector3 camPos = cam.GlobalTransform.origin;
        Vector3 off = camPos;

        float par = Mathf.Abs(particle.startPosition.z / parallaxLength);
        off.x -= off.x * Mathf.Lerp(parallaxRange.x, parallaxRange.y, par);
        off.y -= off.y * Mathf.Lerp(parallaxRange.x, parallaxRange.y, par);

        off.x += viewSize.x * particle.startPosition.x * 0.01f * .5f;
        off.y += viewSize.y * particle.startPosition.y * 0.01f * .5f;

        while (off.x > camPos.x + viewSize.x * 0.01f * .5f) {
            off.x -= viewSize.x * 0.01f;
        }
        while (off.x < camPos.x - viewSize.x * 0.01f * .5f) {
            off.x += viewSize.x * 0.01f;
        }
        while (off.y > camPos.y + viewSize.y * 0.01f * .5f) {
            off.y -= viewSize.y * 0.01f;
        }
        while (off.y < camPos.y - viewSize.y * 0.01f * .5f) {
            off.y += viewSize.y * 0.01f;
        }

        off.z = particle.startPosition.z;

        particle.position = off;
    }
}