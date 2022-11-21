Shader "Shield/Forcefield"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [HDR] _ColorFront ("Color Front", Color) = (1,1,1,1)
        [HDR] _ColorBack ("Color Back", Color) = (1,1,1,1)

        _FresnelPower ("Fresnel Power", Float) = 1
        [HDR] _FresnelColor ("Fresnel Color", Color) = (1,1,1,1)

        _DisplacementAmount ("Displacement Amount", Float) = 1.0
        _AnimationSpeed ("Animation Speed", Float) = 1.0
    }

    SubShader
    {
        Tags {
            "RenderType" = "Transparent"
            "Queue" = "Transparent"
            "RenderPipeline" = "UniversalRenderPipeline"
        }

        Cull Off
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha // Additive

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // The Core.hlsl file contains definitions of frequently used HLSL
            // macros and functions, and also contains #include references to other
            // HLSL files (for example, Common.hlsl, SpaceTransforms.hlsl, etc.).
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD;
                float4 normal       : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD;
                float3 viewDir      : TEXCOORD1;
                float3 worldNormal  : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _ColorFront;
            float4 _ColorBack;

            float _FresnelPower;
            float4 _FresnelColor;

            float _AnimationSpeed;
            float _DisplacementAmount;

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                // displace faces along the normals
                float displacementAmount =  ((sin(_Time.y * _AnimationSpeed) + 1) / 2) * _DisplacementAmount;
                float3 displacedPostitionOS =  IN.positionOS.xyz + (IN.normal.xyz * displacementAmount);
                OUT.positionHCS = TransformObjectToHClip(displacedPostitionOS);

                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

                float3 positionW = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.viewDir = normalize(_WorldSpaceCameraPos.xyz - positionW.xyz);

                OUT.worldNormal = TransformObjectToWorldNormal(IN.normal.xyz, true);

                return OUT;
            }

            half4 frag(Varyings IN, half facing : VFACE) : SV_Target
            {
                // VFACE input positive for frontbaces,
                // negative for backfaces. Output one
                // of the two colors depending on that.
                half4 color = tex2D(_MainTex, IN.uv) * (facing > 0 ? _ColorFront : _ColorBack);

                // fresnelDot is zero when normal is 90 deg angle from view dir
                float fresnelDot = dot(IN.worldNormal, IN.viewDir);

                fresnelDot = saturate(fresnelDot); // clamp to 0,1
                float fresnelPow = pow(1.0f - fresnelDot, _FresnelPower);

                half4 fresnel = fresnelPow * _FresnelColor;

                return color;
            }
            ENDHLSL
        }
    }
}