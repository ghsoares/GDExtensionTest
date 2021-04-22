using Godot;
using System;
using System.Collections.Generic;
using System.Linq;

public struct IVector2 {
    public int x {get; set;}
    public int y {get; set;}

    public IVector2(Vector2 from) {
        x = Mathf.FloorToInt(from.x);
        y = Mathf.FloorToInt(from.y);
    }

    public IVector2(int x, int y) {
        this.x = x;
        this.y = y;
    }

    public override string ToString()
    {
        return "(" + x + ", " + y + ")";
    }
}

public class QuadTree<T> {
    private Dictionary<IVector2, List<T>> cells {get; set;}

    public Vector2 cellSize {get; set;}

    public QuadTree(Vector2 cellSize) {
        this.cellSize = cellSize;
        cells = new Dictionary<IVector2, List<T>>();
    }

    public void Clear() {
        cells.Clear();
    }

    public IVector2 GetCellIdx(Vector2 pos) {
        return new IVector2(Mathf.FloorToInt(pos.x / cellSize.x), Mathf.FloorToInt(pos.y / cellSize.y));
    }

    public void AddElement(Vector2 position, T obj) {
        IVector2 cellIdx = GetCellIdx(position);

        bool hasElements = cells.TryGetValue(cellIdx, out List<T> elements);
        if (!hasElements) {
            elements = new List<T>();
            cells[cellIdx] = elements;
        }

        elements.Add(obj);
    }

    public List<T> ScanArea(Vector2 fromPosition, Vector2 scanSize) {
        List<T> elements = new List<T>();

        Vector2 min = fromPosition - scanSize;
        Vector2 max = fromPosition + scanSize;

        IVector2 minCellIdx = GetCellIdx(min);
        IVector2 maxCellIdx = GetCellIdx(max);

        for (int x = minCellIdx.x; x <= maxCellIdx.x; x++) {
            for (int y = minCellIdx.y; y <= maxCellIdx.y; y++) {
                if (cells.TryGetValue(new IVector2(x, y), out List<T> cellElements)) {
                    elements.AddRange(cellElements);
                }
            }
        }

        return elements;
    }

    public IVector2[] GetCellIndexes() {
        return cells.Keys.ToArray();
    }

    public Rect2 GetCellRect(IVector2 cellIdx) {
        Vector2 pos = new Vector2(
            cellIdx.x * cellSize.x,
            cellIdx.y * cellSize.y
        );
        return new Rect2(pos, cellSize);
    }

    public int GetCellNumElements(IVector2 cellIdx) {
        if (cells.TryGetValue(cellIdx, out List<T> cellElements)) {
            return cellElements.Count;
        }
        return 0;
    }
}