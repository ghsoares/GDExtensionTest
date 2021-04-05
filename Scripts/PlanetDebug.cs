using Godot;

public class PlanetDebug : Node {
    bool mouseDragging = false;
    float cameraZoom = 1f;
    Vector2 cameraPos;

    public override void _Input(InputEvent ev) {
        if (ev is InputEventMouseButton) {
            InputEventMouseButton evMB = (InputEventMouseButton)ev;
            if (evMB.ButtonIndex == (int)ButtonList.Left) {
                if (evMB.Pressed) {
                    mouseDragging = true;
                    cameraPos = GameCamera.instance.desiredPosition;
                } else {
                    mouseDragging = false;
                }
            }
            if (evMB.Pressed) {
                if (evMB.ButtonIndex == (int)ButtonList.WheelUp) {
                    cameraZoom -= .1f;
                } else if (evMB.ButtonIndex == (int)ButtonList.WheelDown) {
                    cameraZoom += .1f;
                }
            }
            cameraZoom = Mathf.Clamp(cameraZoom, .1f, 5f);
        }
        if (ev is InputEventMouseMotion) {
            InputEventMouseMotion evMB = (InputEventMouseMotion)ev;
            if (mouseDragging) {
                cameraPos -= evMB.Relative * cameraZoom;
            }
        }
    }

    public override void _PhysicsProcess(float delta) {
        if (mouseDragging) {
            GameCamera.instance.desiredPosition = cameraPos;
            GameCamera.instance.desiredZoom = cameraZoom;
        } else {
            cameraPos = GameCamera.instance.desiredPosition;
            cameraZoom = GameCamera.instance.desiredZoom;
        }
        this.Raise();
    }
}