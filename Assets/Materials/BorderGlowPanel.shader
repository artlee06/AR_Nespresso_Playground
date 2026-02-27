Shader "Custom/BorderGlowPanel"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (0.04, 0.04, 0.08, 0.92)

        [Header(Glow)]
        _GlowColorA ("Glow Color A", Color) = (1.0, 0.78, 0.35, 1.0)
        _GlowColorB ("Glow Color B", Color) = (1.0, 0.45, 0.15, 1.0)
        _GlowIntensity ("Glow Intensity", Range(0.0, 2.0)) = 0.9
        _GlowWidth ("Glow Arc Width", Range(0.01, 0.5)) = 0.18
        _GlowSpeed ("Glow Speed", Range(0.0, 1.0)) = 0.18
        _BorderIntensity ("Border Intensity", Range(0.0, 2.0)) = 0.6
        _BorderInset ("Border Inset", Range(0.0, 0.1)) = 0.025
        _LineWidth ("Line Width", Range(0.001, 0.02)) = 0.004
        _AuraWidth ("Aura Width", Range(0.005, 0.1)) = 0.04
        _AuraIntensity ("Aura Intensity", Range(0.0, 2.0)) = 0.5
        [HideInInspector] _MainTex ("Sprite Texture", 2D) = "white" {}

        _StencilComp ("Stencil Comparison", Float) = 8
        _Stencil ("Stencil ID", Float) = 0
        _StencilOp ("Stencil Operation", Float) = 0
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255
        _ColorMask ("Color Mask", Float) = 15
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            "PreviewType" = "Plane"
            "RenderPipeline" = "UniversalPipeline"
        }

        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }

        ColorMask [_ColorMask]
        ZWrite Off
        ZTest [unity_GUIZTestMode]
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _GlowColorA;
                float4 _GlowColorB;
                float  _GlowIntensity;
                float  _GlowWidth;
                float  _GlowSpeed;
                float  _BorderIntensity;
                float  _BorderInset;
                float  _LineWidth;
                float  _AuraWidth;
                float  _AuraIntensity;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
                float4 color      : COLOR;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
                float4 color       : COLOR;
            };

            float perimeterCoord(float2 uv)
            {
                float2 d = min(uv, 1.0 - uv);
                float result;

                if (d.x < d.y)
                {
                    if (uv.x < 0.5)
                        result = (4.0 - uv.y) / 4.0;
                    else
                        result = (1.0 + uv.y) / 4.0;
                }
                else
                {
                    if (uv.y < 0.5)
                        result = uv.x / 4.0;
                    else
                        result = (3.0 - uv.x) / 4.0;
                }

                return result;
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv          = IN.uv;
                OUT.color       = IN.color;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float2 uv = IN.uv;

                // Distance from nearest edge
                float edgeDist = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));

                // Distance from the desired border line (centered at _BorderInset from edge)
                float distFromBorder = abs(edgeDist - _BorderInset);

                // Layer 1: crisp thin line centered on _BorderInset
                float borderLine = 1.0 - smoothstep(0.0, _LineWidth, distFromBorder);

                // Layer 2: soft glow bloom on both sides of the line
                float aura = exp(-distFromBorder / max(_AuraWidth, 0.001));
                aura = pow(aura, 1.5);

                // Static border: Color A with line + aura (always visible)
                float3 staticBorder = _GlowColorA.rgb * (borderLine * _BorderIntensity + aura * _AuraIntensity);

                // Travelling arc: Color B, masked to border region
                float animT    = frac(_Time.y * _GlowSpeed);
                float t        = perimeterCoord(uv);
                float diff     = abs(frac(t - animT + 0.5) - 0.5) * 2.0;
                float glowBand = pow(1.0 - smoothstep(0.0, _GlowWidth, diff), 2.0);
                float edgePresence    = saturate(borderLine + aura * 0.5);
                float3 travellingGlow = _GlowColorB.rgb * glowBand * edgePresence * _GlowIntensity;

                float3 finalColor = _BaseColor.rgb + staticBorder + travellingGlow;

                float spriteAlpha = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv).a;
                float alpha       = _BaseColor.a * IN.color.a * spriteAlpha;

                return half4(finalColor, saturate(alpha));
            }
            ENDHLSL
        }
    }
}
