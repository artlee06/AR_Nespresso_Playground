Shader "Custom/LiquidGlassUI"
{
    Properties
    {
        _BlurredBackground ("Blurred Background", 2D) = "black" {}
        _TintColor ("Tint Color", Color) = (1.0, 1.0, 1.0, 0.15)
        _Opacity ("Glass Opacity", Range(0.0, 1.0)) = 0.55
        _EdgeBrightness ("Edge Brightness", Range(0.0, 1.0)) = 0.35
        _EdgeWidth ("Edge Width", Range(0.01, 0.2)) = 0.06
        _EdgeSoftness ("Edge Softness", Range(0.01, 0.1)) = 0.03
        _Distortion ("Distortion", Range(0.0, 0.03)) = 0.008

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

            TEXTURE2D(_BlurredBackground);
            SAMPLER(sampler_BlurredBackground);

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _TintColor;
                float _Opacity;
                float _EdgeBrightness;
                float _EdgeWidth;
                float _EdgeSoftness;
                float _Distortion;
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

            float distanceFromEdge(float2 uv)
            {
                return min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
            }

            float2 glassDistortion(float2 uv)
            {
                float2 i = floor(uv * 8.0);
                float nx = frac(sin(dot(i, float2(127.1, 311.7))) * 43758.5) - 0.5;
                float ny = frac(sin(dot(i, float2(269.5, 183.3))) * 43758.5) - 0.5;
                return float2(nx, ny) * _Distortion;
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
                float2 distortedUV = IN.uv + glassDistortion(IN.uv);

                float3 blurred = SAMPLE_TEXTURE2D(
                    _BlurredBackground,
                    sampler_BlurredBackground,
                    distortedUV
                ).rgb;

                blurred = lerp(blurred, blurred + _TintColor.rgb, _TintColor.a);

                float edgeDist = distanceFromEdge(IN.uv);
                float edgeMask = 1.0 - smoothstep(
                    _EdgeWidth - _EdgeSoftness,
                    _EdgeWidth + _EdgeSoftness,
                    edgeDist
                );
                float3 edgeContrib = float3(1, 1, 1) * edgeMask * _EdgeBrightness;

                float3 finalColor = blurred + edgeContrib;

                float spriteAlpha = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).a;
                float alpha = _Opacity * IN.color.a * spriteAlpha;

                return half4(finalColor, saturate(alpha));
            }
            ENDHLSL
        }
    }
}