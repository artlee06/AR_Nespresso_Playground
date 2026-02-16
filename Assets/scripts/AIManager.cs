using UnityEngine;
using UnityEngine.Events;

public class AIManager : MonoBehaviour
{
    public UnityEvent onAButtonPressed;

    void Update()
    {
        if (OVRInput.GetDown(OVRInput.Button.One))
        {
            onAButtonPressed?.Invoke();
        }
    }
}
