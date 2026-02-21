Shader "Custom/LiquidGlass"
{
    Properties
    {
        [PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
        _TintColor ("Tint Color", Color) = (0.039, 0.039, 0.039, 0.85)
        _GlassColor ("Glass Tint", Color) = (0.85, 0.92, 1.0, 0.15)
        _NoiseScale ("Noise Scale", Range(1.0, 50.0)) = 15.0
        _NoiseStrength ("Noise Strength", Range(0.0, 0.3)) = 0.08
        _FrostIntensity ("Frost Intensity", Range(0.0, 1.0)) = 0.65
        _RimColor ("Rim Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _RimPower ("Rim Power", Range(0.5, 8.0)) = 3.5
        _RimIntensity ("Rim Intensity", Range(0.0, 2.0)) = 0.8
        _InnerGlow ("Inner Glow", Range(0.0, 1.0)) = 0.12
        _Brightness ("Brightness", Range(0.5, 2.0)) = 1.0
        
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
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
            "IgnoreProjector" = "True"
        }
        
        Stencil
        {
            Ref [_Stencil]
            Comp [_StencilComp]
            Pass [_StencilOp]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
        }
        
        Pass
        {
            Name "LiquidGlass"
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Off
            ColorMask [_ColorMask]
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _TintColor;
                float4 _GlassColor;
                float _NoiseScale;
                float _NoiseStrength;
                float _FrostIntensity;
                float4 _RimColor;
                float _RimPower;
                float _RimIntensity;
                float _InnerGlow;
                float _Brightness;
            CBUFFER_END
            
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
                float4 color : COLOR;
            };
            
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD2;
                float3 positionWS : TEXCOORD3;
                float4 color : COLOR;
            };
            
            // Simplex 2D noise
            float2 hash2(float2 p)
            {
                p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
                return frac(sin(p) * 43758.5453123);
            }
            
            float noise(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);
                f = f * f * (3.0 - 2.0 * f);
                
                float2 a = hash2(i);
                float2 b = hash2(i + float2(1.0, 0.0));
                float2 c = hash2(i + float2(0.0, 1.0));
                float2 d = hash2(i + float2(1.0, 1.0));
                
                return lerp(lerp(a.x, b.x, f.x), lerp(c.x, d.x, f.x), f.y);
            }
            
            float fbm(float2 p)
            {
                float value = 0.0;
                float amplitude = 0.5;
                for (int i = 0; i < 4; i++)
                {
                    value += amplitude * noise(p);
                    p *= 2.0;
                    amplitude *= 0.5;
                }
                return value;
            }
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.viewDirWS = GetWorldSpaceViewDir(OUT.positionWS);
                OUT.color = IN.color;
                return OUT;
            }
            
            half4 frag(Varyings IN) : SV_Target
            {
                half4 spriteColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                
                // Procedural frosted glass texture
                float2 noiseUV = IN.uv * _NoiseScale + IN.positionWS.xy * 0.5;
                float noiseValue = fbm(noiseUV);
                float frost = noiseValue * _NoiseStrength;
                
                // Base glass color with frost variation
                float3 glassBase = lerp(_TintColor.rgb, _GlassColor.rgb, frost * _FrostIntensity);
                
                // Rim lighting
                float3 normalWS = normalize(IN.normalWS);
                float3 viewDir = normalize(IN.viewDirWS);
                float fresnel = 1.0 - saturate(dot(normalWS, viewDir));
                float rimFactor = pow(fresnel, _RimPower);
                float3 rimContrib = _RimColor.rgb * rimFactor * _RimIntensity;
                
                // Inner glow (inverted fresnel for subtle internal lighting)
                float innerGlowFactor = saturate(dot(normalWS, viewDir));
                innerGlowFactor = pow(innerGlowFactor, 2.0) * _InnerGlow;
                float3 innerGlowContrib = _GlassColor.rgb * innerGlowFactor;
                
                // Combine all effects
                float3 finalColor = glassBase + rimContrib + innerGlowContrib;
                finalColor *= _Brightness;
                finalColor *= IN.color.rgb;
                
                // Alpha with rim contribution
                float alpha = _TintColor.a + rimFactor * _RimIntensity * 0.3;
                alpha *= IN.color.a * spriteColor.a;
                
                return half4(finalColor, saturate(alpha));
            }
            ENDHLSL
        }
    }
    
    Fallback "UI/Default"
}
