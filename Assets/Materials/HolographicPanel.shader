Shader "Custom/HolographicPanel"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (0.04, 0.04, 0.08, 0.88)
        _HueOffset ("Hue Offset", Range(0.0, 1.0)) = 0.0
        _IridescenceIntensity ("Iridescence Intensity", Range(0.0, 2.0)) = 1.2
        _IridescenceFrequency ("Iridescence Frequency", Range(0.5, 8.0)) = 3.0
        _FresnelPower ("Fresnel Power", Range(1.0, 6.0)) = 3.0
        _FresnelIntensity ("Fresnel Intensity", Range(0.0, 2.0)) = 1.0
        _ShimmerSpeed ("Shimmer Speed", Range(0.0, 1.0)) = 0.15
        _ShimmerScale ("Shimmer Scale", Range(1.0, 8.0)) = 4.0
        _ShimmerIntensity ("Shimmer Intensity", Range(0.0, 0.5)) = 0.12
        _ShineIntensity ("Shine Intensity", Range(0.0, 0.5)) = 0.1
        _ShinePosition ("Shine Y Position", Range(0.0, 1.0)) = 0.85
        _ShineWidth ("Shine Width", Range(0.01, 0.3)) = 0.06
        _BorderWidth ("Border Width", Range(0.05, 0.4)) = 0.15
        _BorderSoftness ("Border Softness", Range(0.01, 0.15)) = 0.05
        _CenterBrightness ("Center Brightness", Range(0.0, 0.3)) = 0.06
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Transparent"
            "Queue" = "Transparent+10"
            "RenderPipeline" = "UniversalPipeline"
        }

        Pass
        {
            Name "HolographicPanel"
            ZWrite Off
            ZTest LEqual
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float _HueOffset;
                float _IridescenceIntensity;
                float _IridescenceFrequency;
                float _FresnelPower;
                float _FresnelIntensity;
                float _ShimmerSpeed;
                float _ShimmerScale;
                float _ShimmerIntensity;
                float _ShineIntensity;
                float _ShinePosition;
                float _ShineWidth;
                float _BorderWidth;
                float _BorderSoftness;
                float _CenterBrightness;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float4 tangentOS  : TANGENT;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
                float3 normalWS    : TEXCOORD1;
                float3 viewDirWS   : TEXCOORD2;
                float3 posWS       : TEXCOORD3;
            };

            float3 HSVtoRGB(float h, float s, float v)
            {
                float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                float3 p = abs(frac(h + K.xyz) * 6.0 - K.www);
                return v * lerp(K.xxx, saturate(p - K.xxx), s);
            }

            float smoothNoise(float2 uv)
            {
                float2 i = floor(uv);
                float2 f = frac(uv);
                float2 u = f * f * (3.0 - 2.0 * f);
                float a = frac(sin(dot(i,               float2(127.1, 311.7))) * 43758.5);
                float b = frac(sin(dot(i + float2(1,0), float2(127.1, 311.7))) * 43758.5);
                float c = frac(sin(dot(i + float2(0,1), float2(127.1, 311.7))) * 43758.5);
                float d = frac(sin(dot(i + float2(1,1), float2(127.1, 311.7))) * 43758.5);
                return lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y);
            }

            float distanceFromEdge(float2 uv)
            {
                float left   = uv.x;
                float right  = 1.0 - uv.x;
                float bottom = uv.y;
                float top    = 1.0 - uv.y;
                return min(min(left, right), min(top, bottom));
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.posWS       = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.positionHCS = TransformWorldToHClip(OUT.posWS);
                OUT.normalWS    = TransformObjectToWorldNormal(IN.normalOS);
                OUT.viewDirWS   = GetWorldSpaceViewDir(OUT.posWS);
                OUT.uv          = IN.uv;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float3 normalWS = normalize(IN.normalWS);
                float3 viewDir  = normalize(IN.viewDirWS);
                float ndotv     = saturate(dot(normalWS, viewDir));

                // Border mask
                float edgeDist   = distanceFromEdge(IN.uv);
                float borderMask = 1.0 - smoothstep(
                    _BorderWidth - _BorderSoftness,
                    _BorderWidth + _BorderSoftness,
                    edgeDist
                );

                // Iridescence
                float hue = frac(ndotv * _IridescenceFrequency + _HueOffset);
                float3 iridescentColor = HSVtoRGB(hue, 0.9, 0.55);
                float fresnel = pow(1.0 - ndotv, _FresnelPower);
                float3 iridescenceMasked = iridescentColor * fresnel * _IridescenceIntensity * borderMask;

                // Shimmer
                float time = _Time.y;
                float2 shimUV1 = IN.uv * _ShimmerScale + float2(time * _ShimmerSpeed, time * _ShimmerSpeed * 0.6);
                float2 shimUV2 = IN.uv * _ShimmerScale * 0.7 + float2(-time * _ShimmerSpeed * 0.4, time * _ShimmerSpeed);
                float shimmer = smoothNoise(shimUV1) * smoothNoise(shimUV2);
                float3 shimmerContrib = iridescentColor * shimmer * _ShimmerIntensity * borderMask;

                // Top shine streak
                float shine = 1.0 - abs(IN.uv.y - _ShinePosition) / _ShineWidth;
                shine = saturate(pow(shine, 3.0));
                float edgeFade = sin(IN.uv.x * 3.14159);
                float3 shineContrib = float3(1,1,1) * shine * edgeFade * _ShineIntensity;

                // Center lift
                float centerMask = 1.0 - borderMask;
                float3 centerContrib = _BaseColor.rgb * centerMask * _CenterBrightness;

                // Compose
                float3 finalColor = _BaseColor.rgb
                                  + iridescenceMasked
                                  + shimmerContrib
                                  + shineContrib
                                  + centerContrib;

                float alpha = _BaseColor.a + fresnel * borderMask * 0.08;

                return half4(finalColor, saturate(alpha));
            }
            ENDHLSL
        }
    }
}