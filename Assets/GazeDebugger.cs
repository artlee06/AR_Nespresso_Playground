using UnityEngine;

public class GazeDebugger : MonoBehaviour
{
    public void OnGazeEnter()
    {
        Debug.Log("[GAZE] Enter");
    }
    
    public void OnGazeActivated()
    {
        Debug.Log("[GAZE] ACTIVATED");
    }
    
    public void OnGazeExit()
    {
        Debug.Log("[GAZE] Exit");
    }
}