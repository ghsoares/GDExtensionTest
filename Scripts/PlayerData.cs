using Godot;

public static class PlayerData {
    private static float _sessionCurrentFuel {get; set;}

    public static float maxFuel {get; set;}
    public static float fuelLossRate {get; set;}
    public static int sessionScore {get; set;}
    public static float sessionCurrentFuel {
        get {
            return _sessionCurrentFuel;
        }
        set {
            _sessionCurrentFuel = Mathf.Clamp(value, 0f, maxFuel);
        }
    }
    
    static PlayerData() {
        maxFuel = 500f;
        fuelLossRate = .1f;   
    }

    public static void ResetSession() {
        sessionCurrentFuel = maxFuel;
    }
}