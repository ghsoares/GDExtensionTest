using System;
using Godot;

[Tool]
public class ModelViewComponent : Node
{
    private Node _modelNode { get; set; }
    private Node _viewNode { get; set; }

    public const float pixelSize = 0.01f;
    public enum TransformUpdateMode
    {
        Process,
        PhysicsProcess
    }

    public Node modelNode
    {
        get
        {
            if (_modelNode == null)
            {
                _modelNode = GetParent();
            } else {
                if (!_modelNode.IsInsideTree()) _modelNode = null;
            }
            return _modelNode;
        }
        private set
        {
            _modelNode = value;
        }
    }
    public Node viewNode
    {
        get
        {
            if (_viewNode == null)
            {
                if (GetChildCount() > 0)
                {
                    _viewNode = GetChild(0);
                }
            } else {
                if (!_viewNode.IsInsideTree()) _viewNode = null;
            }
            return _viewNode;
        }
        private set
        {
            _viewNode = value;
        }
    }

    [Export] public TransformUpdateMode transformUpdate = TransformUpdateMode.Process;

    public override void _Process(float delta)
    {
        if (transformUpdate == TransformUpdateMode.Process) UpdateTransform();
    }

    public override void _PhysicsProcess(float delta)
    {
        if (transformUpdate == TransformUpdateMode.PhysicsProcess) UpdateTransform();
    }

    protected virtual void UpdateTransform()
    {
        if (modelNode == null || viewNode == null) return;
        if (modelNode is Spatial && viewNode is CanvasItem)
        {
            Spatial model = modelNode as Spatial;
            CanvasItem view = viewNode as CanvasItem;
            Transform2D t = Update3DTo2D(
                model.GlobalTransform, view.GetGlobalTransform()
            );
            view.Visible = model.Visible;
            if (!Engine.EditorHint) VisualServer.CanvasItemSetTransform(view.GetCanvasItem(), t);
        }
        else if (modelNode is CanvasItem && viewNode is Spatial)
        {
            CanvasItem model = modelNode as CanvasItem;
            Spatial view = viewNode as Spatial;
            Transform t = view.GlobalTransform = Update2DTo3D(
                model.GetGlobalTransform(), view.GlobalTransform
            );
            view.Visible = model.Visible;
            view.GlobalTransform = t;
            if (!Engine.EditorHint) VisualServer.CanvasItemSetVisible(model.GetCanvasItem(), false);
        }
    }

    protected virtual Transform2D Update3DTo2D(Transform modelTransform, Transform2D viewTransform)
    {
        viewTransform.origin = new Vector2(
            modelTransform.origin.x / pixelSize, -modelTransform.origin.y / pixelSize
        );

        viewTransform.x = new Vector2(modelTransform.basis.x.x, modelTransform.basis.x.y);
        viewTransform.y = new Vector2(modelTransform.basis.y.x, modelTransform.basis.y.y);

        return viewTransform;
    }

    protected virtual Transform Update2DTo3D(Transform2D modelTransform, Transform viewTransform)
    {
        viewTransform.origin = new Vector3(
            modelTransform.origin.x * pixelSize, -modelTransform.origin.y * pixelSize,
            viewTransform.origin.z
        );

        Basis basis = viewTransform.basis;
        Quat q = basis.Quat().Normalized();

        if (q.IsNormalized()) {
            Vector3 euler = q.GetEuler();
            euler.z = modelTransform.Rotation;

            basis = new Basis(new Quat(euler));
        }

        viewTransform.basis = basis;

        return viewTransform;
    }
}
