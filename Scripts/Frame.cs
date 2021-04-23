using Godot;

public class Frame : Control {
    public override void _Process(float delta) {
        Update();
    }

    public override void _Draw()
    {
        Transform2D viewTransform = GetViewport().CanvasTransform.AffineInverse();
        System.Console.WriteLine(viewTransform);

        DrawSetTransformMatrix(GetGlobalTransform().AffineInverse() * viewTransform);

        ShaderMaterial shaderMat = Material as ShaderMaterial;

        if (shaderMat != null) {
            shaderMat.SetShaderParam("globalTransform", viewTransform);
        }
    }
}