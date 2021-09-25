Shader "Roystan/Toon/Water"
{
    Properties
    {
        _DepthGradientShallow("Depth Gradient Shallow", Color) = (0.325, 0.807, 0.971, 0.725)
        _DepthGradientDeep("Depth Gradient Deep", Color) = (0.086, 0.407, 1, 0.749)
        _DepthMaxDistance("Depth Maximum Distance", Float) = 1

        _SurfaceNoise ("Surface Noise", 2D) = "white" {}
        _SurfaceNoiseCutoff("Surface Noise Cutoff", Range(0, 1)) = 0.777

        _FoamColor("Foam Color", Color) = (1,1,1,1)
        _FoamMaxDistance("Foam Maximum Distance", Float) = 0.4
        _FoamMinDistance("Foam Minimum Distance", Float) = 0.04

        _SurfaceNoiseScroll("Surface Noise Scroll Amount", Vector) = (0.03, 0.03, 0, 0)

        _SurfaceDistortion("Surface Distortion", 2D) = "white" {}
        _SurfaceDistortionAmount("Surface Distortion Amount", Range(0, 1)) = 0.27
    }
    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
        }

        Blend SrcAlpha OneMinusSrcAlpha
        //        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            #define SMOOTHSTEP_AA 0.03

            sampler2D _CameraDepthTexture;
            sampler2D _CameraNormalsTexture;

            fixed4 _DepthGradientShallow;
            fixed4 _DepthGradientDeep;
            float _DepthMaxDistance;

            sampler2D _SurfaceNoise;
            float4 _SurfaceNoise_ST;
            float _SurfaceNoiseCutoff;
            half3 _SurfaceNoiseScroll;

            fixed4 _FoamColor;
            float _FoamMaxDistance;
            float _FoamMinDistance;

            sampler2D _SurfaceDistortion;
            float4 _SurfaceDistortion_ST;
            float _SurfaceDistortionAmount;

            struct appdata
            {
                float4 vertex : POSITION;
                float4 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 screenPosition : TEXCOORD0;
                float2 noiseUv : TEXCOORD1;
                float2 distortionUv : TEXCOORD2;
                float3 viewNormal : NORMAL;
            };

            v2f vert(appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPosition = ComputeScreenPos(o.vertex);
                o.noiseUv = TRANSFORM_TEX(v.uv, _SurfaceNoise);
                o.distortionUv = TRANSFORM_TEX(v.uv, _SurfaceDistortion);
                o.viewNormal = COMPUTE_VIEW_NORMAL;

                return o;
            }

            float4 alphaBlend(float4 top, float4 bottom)
            {
                float3 color = (top.rgb * top.a) + (bottom.rgb * (1 - top.a));
                float alpha = top.a + bottom.a * (1 - top.a);

                return float4(color, alpha);
            }

            float4 frag(v2f i) : SV_Target
            {
                // Depth
                float existingDepth01 = tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screenPosition)).r;
                float existingDepthLinear = LinearEyeDepth(existingDepth01);
                float depthDifference = existingDepthLinear - i.screenPosition.w;
                float depthDifference01 = saturate(depthDifference / _DepthMaxDistance);

                fixed4 waterColor = lerp(_DepthGradientShallow, _DepthGradientDeep, depthDifference01);

                // Normal
                float3 existingNormal = tex2Dproj(_CameraNormalsTexture, UNITY_PROJ_COORD(i.screenPosition));
                float viewNormalDot = saturate(dot(existingNormal, i.viewNormal));
                // nếu cùng hướng với view thì trả về min, vuông góc hoặc ngược hướng thì trả về max
                float foamDistance = lerp(_FoamMaxDistance, _FoamMinDistance, viewNormalDot);

                // Foam
                float depthFoamDifference01 = saturate(depthDifference / foamDistance);

                // Noise
                float2 distortion = (tex2D(_SurfaceDistortion, i.distortionUv).xy * 2 - 1) * _SurfaceDistortionAmount;
                float2 noiseUv = float2((i.noiseUv.x + _Time.y * _SurfaceNoiseScroll.x) + distortion.x,
                                        (i.noiseUv.y + _Time.y * _SurfaceNoiseScroll.y) + distortion.y);
                float surfaceNoise = tex2D(_SurfaceNoise, noiseUv).r;
                float surfaceNoiseCutoff = _SurfaceNoiseCutoff * depthFoamDifference01;
                surfaceNoise = smoothstep(surfaceNoiseCutoff - SMOOTHSTEP_AA, surfaceNoiseCutoff + SMOOTHSTEP_AA, surfaceNoise);

                return alphaBlend(_FoamColor * surfaceNoise, waterColor);
            }
            ENDCG
        }
    }
}