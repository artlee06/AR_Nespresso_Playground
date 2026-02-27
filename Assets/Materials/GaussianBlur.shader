Shader "Custom/GaussianBlur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurSpread ("Blur Spread", Float) = 1.0
        _BlurDir ("Blur Direction", Vector) = (1,0,0,0)
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        ZTest Always ZWrite Off Cull Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_TexelSize;
                float _BlurSpread;
                float4 _BlurDir;
            CBUFFER_END

            struct Attributes { float4 pos : POSITION; float2 uv : TEXCOORD0; };
            struct Varyings   { float4 pos : SV_POSITION; float2 uv : TEXCOORD0; };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.pos = TransformObjectToHClip(IN.pos.xyz);
                OUT.uv  = IN.uv;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float2 texel = _MainTex_TexelSize.xy * _BlurSpread;
                float2 dir   = _BlurDir.xy;

                // 9-tap Gaussian weights
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv) * 0.227;
                col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + dir * texel * 1.385) * 0.316;
                col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv - dir * texel * 1.385) * 0.316;
                col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv + dir * texel * 3.231) * 0.070;
                col += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv - dir * texel * 3.231) * 0.070;

                return col;
            }
            ENDHLSL
        }
    }
}