using UnityEngine;
using Meta.XR;

public class PassthroughBlur : MonoBehaviour
{
    [SerializeField] private PassthroughCameraAccess passthroughCamera;
    [SerializeField] private Material panelMaterial;
    [SerializeField] private Material blurMaterial; // uses the blur shader below
    [SerializeField] private int blurIterations = 3;
    [SerializeField] private float blurSpread = 1.5f;

    private RenderTexture blurRT_A;
    private RenderTexture blurRT_B;

    void Start()
    {
        // Half resolution is fine for a blur — saves memory and looks the same
        blurRT_A = new RenderTexture(512, 512, 0, RenderTextureFormat.ARGB32);
        blurRT_B = new RenderTexture(512, 512, 0, RenderTextureFormat.ARGB32);
    }

    void Update()
    {
        Texture cameraTexture = passthroughCamera?.GetTexture();
        if (cameraTexture == null) return;

        // Blit camera feed into RT_A
        Graphics.Blit(cameraTexture, blurRT_A);

        // Ping-pong blur passes
        for (int i = 0; i < blurIterations; i++)
        {
            blurMaterial.SetFloat("_BlurSpread", blurSpread);

            // Horizontal pass
            blurMaterial.SetVector("_BlurDir", new Vector4(1, 0, 0, 0));
            Graphics.Blit(blurRT_A, blurRT_B, blurMaterial);

            // Vertical pass
            blurMaterial.SetVector("_BlurDir", new Vector4(0, 1, 0, 0));
            Graphics.Blit(blurRT_B, blurRT_A, blurMaterial);
        }

        // Feed the blurred result into the panel shader
        panelMaterial.SetTexture("_BlurredBackground", blurRT_A);
    }

    void OnDestroy()
    {
        blurRT_A?.Release();
        blurRT_B?.Release();
    }
}