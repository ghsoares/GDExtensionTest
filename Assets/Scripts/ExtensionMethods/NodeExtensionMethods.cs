using Godot;
using System.Collections.Generic;
using System.Linq;

namespace ExtensionMethods {
    namespace NodeMethods {
        public static class NodeExtensionMethods {
            public static Godot.Collections.Array GetChildrenRecursive(this Node thisNode) {
                var nodes = thisNode.GetChildren();
                foreach (Node node in nodes) {
                    if (node.GetChildCount() > 0) {
                        foreach (Node childNode in node.GetChildrenRecursive()) {
                            nodes.Add(childNode);
                        }
                    }
                }
                return nodes;
            }

            public static IEnumerable<T> GetChildren<T>(this Node thisNode, bool recursive = true) {
                Godot.Collections.Array children = null;
                if (recursive) {
                    children = thisNode.GetChildrenRecursive();
                } else {
                    children = thisNode.GetChildren();
                }
                return children.OfType<T>();
            }

            public static T GetChild<T>(this Node thisNode, bool recursive = true) {
                return thisNode.GetChildren<T>(recursive).FirstOrDefault();
            }

            public static int GetChildCount<T>(this Node thisNode, bool recursive = true) {
                return thisNode.GetChildren<T>(recursive).Count();
            }
        }
    }
}