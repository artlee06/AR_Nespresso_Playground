Shader "Custom/ShimmerPanel"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (0.04, 0.04, 0.08, 0.92)
        _ShimmerColor ("Shimmer Color", Color) = (0.7, 0.85, 1.0, 1.0)
        _ShimmerWidth ("Shimmer Width", Range(0.02, 0.4)) = 0.12
        _ShimmerSpeed ("Shimmer Speed", Range(0.1, 1.0)) = 0.35
        _ShimmerIntensity ("Shimmer Intensity", Range(0.0, 1.0)) = 0.18
        _ShimmerAngle ("Shimmer Angle", Range(0.0, 1.0)) = 0.3

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
                float4 _ShimmerColor;
                float _ShimmerWidth;
                float _ShimmerSpeed;
                float _ShimmerIntensity;
                float _ShimmerAngle;
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
                float diagonal = lerp(IN.uv.x, IN.uv.y, _ShimmerAngle);
                float bandPos  = frac(_Time.y * _ShimmerSpeed) * 3.0 - 1.0;
                float dist     = abs(diagonal - bandPos);
                float band     = smoothstep(_ShimmerWidth, 0.0, dist);
                band           = pow(band, 1.5);

                float3 finalColor = _BaseColor.rgb
                                  + _ShimmerColor.rgb * band * _ShimmerIntensity;

                float spriteAlpha = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv).a;
                float alpha = _BaseColor.a * IN.color.a * spriteAlpha;

                return half4(finalColor, saturate(alpha));
            }
            ENDHLSL
        }
    }
}