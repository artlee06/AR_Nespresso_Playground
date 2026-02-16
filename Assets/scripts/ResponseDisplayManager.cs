using UnityEngine;
using TMPro;
using System;

[Serializable]
public class PodResponse
{
    public bool detected;
    public string pod_name;
    public string maker;
    public int intensity;
    public string description;
}

public class ResponseDisplayManager : MonoBehaviour
{
    [Header("UI References")]
    [SerializeField] private GameObject responsePanel;
    [SerializeField] private TMP_Text responseText;
    
    [Header("Database")]
    [SerializeField] private PodDatabase podDatabase;
    
    [Header("Settings")]
    [SerializeField] private float autoHideDuration = 10f;
    
    private float hideTimer = 0f;
    private bool isPanelVisible = false;
    
    void Start()
    {
        if (responsePanel != null)
        {
            responsePanel.SetActive(false);
        }
    }
    
    void Update()
    {
        // Auto-hide
        if (isPanelVisible)
        {
            hideTimer += Time.deltaTime;
            if (hideTimer >= autoHideDuration)
            {
                HidePanel();
            }
        }
    }
    
    public void ShowLoading()
    {
        Debug.Log("[ResponseDisplayManager] Showing loading...");
        ShowPanel("Analyzing pod...");
    }
    
    public void ShowResponse(string response)
    {
        Debug.Log($"[ResponseDisplayManager] Raw response: {response}");
        
        // Clean response
        string cleanedResponse = CleanJsonResponse(response);
        Debug.Log($"[ResponseDisplayManager] Cleaned: {cleanedResponse}");
        
        try
        {
            // Parse JSON
            PodResponse podData = JsonUtility.FromJson<PodResponse>(cleanedResponse);
            
            if (!podData.detected || string.IsNullOrEmpty(podData.pod_name))
            {
                ShowPanel("Unknown Pod\nTry Again");
                return;
            }
            
            // Lookup personal rating
            PodData myData = podDatabase?.GetPodRating(podData.pod_name);
            float rating = myData?.personalRating ?? 0f;
            
            // Format display
            string displayText = FormatPodDisplay(podData, rating);
            ShowPanel(displayText);
        }
        catch (Exception e)
        {
            Debug.LogError($"[ResponseDisplayManager] JSON parse error: {e.Message}");
            Debug.LogError($"[ResponseDisplayManager] Response was: {cleanedResponse}");
            // Show raw response for debugging
            ShowPanel(cleanedResponse);
        }
    }
    
    private string CleanJsonResponse(string response)
    {
        // Remove markdown code blocks
        if (response.Contains("```json"))
        {
            int start = response.IndexOf("```json") + 7;
            int end = response.IndexOf("```", start);
            if (end > start)
            {
                response = response.Substring(start, end - start).Trim();
            }
        }
        else if (response.Contains("```"))
        {
            int start = response.IndexOf("```") + 3;
            int end = response.IndexOf("```", start);
            if (end > start)
            {
                response = response.Substring(start, end - start).Trim();
            }
        }
        
        return response.Trim();
    }
    
    private string FormatPodDisplay(PodResponse pod, float rating)
    {
        string stars = GenerateStars(rating);
        
        return $"<b><size=54>{pod.pod_name} </size></b>" +
               $"<size=36>By {pod.maker}</size>\n" +
               $"<size=42>{stars}</size>\n" +
               $"<b><size=42>Intensity:</size></b> <size=42>{pod.intensity}/13</size>\n" +
               $"<size=38>{pod.description}</size>";
    }
    
    private string GenerateStars(float rating)
    {
        int fullStars = Mathf.FloorToInt(rating);
        bool hasHalfStar = (rating % 1) >= 0.5f;
        
        string result = "";
        
        // Filled stars
        for (int i = 0; i < fullStars; i++)
        {
            result += "*";
        }
        
        // Half star
        if (hasHalfStar)
        {
            result += "*";
        }
        
        // Empty stars
        int emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);
        for (int i = 0; i < emptyStars; i++)
        {
            result += "-";
        }
        
        return result;
    }
    
    public void HidePanel()
    {
        if (responsePanel != null)
        {
            responsePanel.SetActive(false);
            isPanelVisible = false;
        }
    }
    
    private void ShowPanel(string text)
    {
        if (responsePanel == null || responseText == null)
        {
            Debug.LogError("[ResponseDisplayManager] Missing references!");
            return;
        }
        
        responseText.text = text;
        responsePanel.SetActive(true);
        isPanelVisible = true;
        hideTimer = 0f;
    }
}