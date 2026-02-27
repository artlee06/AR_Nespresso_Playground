using UnityEngine;

[System.Serializable]
public class PodData
{
    public string name;
    public float personalRating; // 0-5
    public string notes; // Optional: "My go-to morning pod"
}

public class PodDatabase : MonoBehaviour
{
    private PodData[] myPods = new PodData[]
    {
        new PodData { name = "Tokyo Lungo", personalRating = 3.0f, notes = "Good for mornings" },
        new PodData { name = "Kazaar", personalRating = 5.0f, notes = "Too intense for me" },
        new PodData { name = "Arpeggio", personalRating = 4.0f, notes = "Smooth and balanced" },
        new PodData { name = "Capriccio", personalRating = 3.0f, notes = "Not a fan" },
        new PodData { name = "India", personalRating = 4.0f, notes = "Not bad" },
        // Add more as you own them
    };
    
    public PodData GetPodRating(string podName)
    {
        foreach (var pod in myPods)
        {
            if (pod.name.Equals(podName, System.StringComparison.OrdinalIgnoreCase))
            {
                return pod;
            }
        }
        
        // Not in your collection
        return new PodData { name = podName, personalRating = 0f, notes = "Not rated yet" };
    }
}