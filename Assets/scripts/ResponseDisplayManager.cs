using UnityEngine;
using UnityEngine.UI;
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
    [SerializeField] private CanvasGroup canvasGroup;
    [SerializeField] private Image backgroundImage;
    
    [Header("Materials")]
    [SerializeField] private Material shimmerMaterial;
    [SerializeField] private Material responseMaterial;

    [Header("Database")]
    [SerializeField] private PodDatabase podDatabase;
    
    [Header("Settings")]
    [SerializeField] private float autoHideDuration = 10f;
    [SerializeField] private float animDuration = 0.4f;
    [SerializeField] private float riseDistance = 0.06f;
    
    private float hideTimer = 0f;
    private bool isPanelVisible = false;
    private Vector3 targetLocalPosition;
    
    void Start()
    {
        if (responsePanel != null)
        {
            targetLocalPosition = responsePanel.transform.localPosition;
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
        backgroundImage.material = shimmerMaterial;
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
                backgroundImage.material = responseMaterial;
                ShowPanel("Unknown Pod\nTry Again");
                return;
            }
            
            // Lookup personal rating
            PodData myData = podDatabase?.GetPodRating(podData.pod_name);
            float rating = myData?.personalRating ?? 0f;
            
            // Format display
            string displayText = FormatPodDisplay(podData, rating);
            backgroundImage.material = responseMaterial;
            ShowPanel(displayText);
        }
        catch (Exception e)
        {
            Debug.LogError($"[ResponseDisplayManager] JSON parse error: {e.Message}");
            Debug.LogError($"[ResponseDisplayManager] Response was: {cleanedResponse}");
            backgroundImage.material = responseMaterial;
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
        
        // Title: 73pt (Bold)
    // By-line/Labels: 45pt (Regular)
    // Intensity Value: 45pt (Bold)
    // Body: 28pt (Regular)
    
    return $"<size=73>{pod.pod_name}</size><size=45> by {pod.maker}</size>\n" +
           $"<size=0>\u200B</size>\n" + // gap: group 1 → 2
           $"<line-height=85%>" +
           $"<size=45>Intensity: <b>{pod.intensity}/13</b></size>\n" +
           $"<size=45>Your Rating: </size><space=0.5em><size=45>{stars}</size>\n" +
        //    $"<size=0>\u200B</size>\n" + // gap: group 2 → 3
           $"<line-height=32px><size=28>{pod.description}</size>";
    }
    
    private string GenerateStars(float rating)
    {
        int fullStars = Mathf.FloorToInt(rating);
        bool hasHalfStar = (rating % 1) >= 0.5f;
        
        string result = "";
        
        for (int i = 0; i < fullStars; i++)
        {
            result += "<sprite name=\"star-fill\">";
        }
        
        if (hasHalfStar)
        {
            result += "<sprite name=\"star-half-fill\">";
        }
        
        int emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);
        for (int i = 0; i < emptyStars; i++)
        {
            result += "<sprite name=\"star-line\">";
        }
        
        return result;
    }
    
    public void HidePanel()
    {
        if (responsePanel != null && canvasGroup != null)
        {
            // Cancel any existing tweens
            LeanTween.cancel(responsePanel);
            
            isPanelVisible = false;
            LeanTween.alphaCanvas(canvasGroup, 0f, 0.2f).setOnComplete(() =>
            {
                responsePanel.SetActive(false);
            });
        }
    }

    
    private void ShowPanel(string text)
    {
        if (responsePanel == null || responseText == null || canvasGroup == null)
        {
            Debug.LogError("[ResponseDisplayManager] Missing references!");
            return;
        }
        
        // Cancel any existing tweens on this panel
        LeanTween.cancel(responsePanel);
        
        responseText.text = text;
        
        canvasGroup.alpha = 0f;
        Vector3 startLocalPosition = targetLocalPosition - new Vector3(0f, riseDistance, 0f);
        responsePanel.transform.localPosition = startLocalPosition;
        
        responsePanel.SetActive(true);
        isPanelVisible = true;
        hideTimer = 0f;
        
        LeanTween.alphaCanvas(canvasGroup, 1f, animDuration).setEase(LeanTweenType.easeOutCubic);
        LeanTween.moveLocal(responsePanel, targetLocalPosition, animDuration).setEase(LeanTweenType.easeOutCubic);
    }

}