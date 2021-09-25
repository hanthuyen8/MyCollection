// Sinh ra outline bằng cách vẽ 2 lần mesh
// Pass 1 sẽ vẽ màu bình thường
// Pass 2 sẽ vẽ outline

Shader "Custom/InvertedHullOutline"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _OutlineColor ("Outline Color", Color) = (0,0,0,1)
        _OutlineWidth ("Outline Width", float) = 0.01
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 150

        CGPROGRAM
        // Mobile improvement: noforwardadd
        // http://answers.unity3d.com/questions/1200437/how-to-make-a-conditional-pragma-surface-noforward.html
        // http://gamedev.stackexchange.com/questions/123669/unity-surface-shader-conditinally-noforwardadd
        #pragma surface surf Lambert

        sampler2D _MainTex;
        fixed4 _Color;

        struct Input
        {
            float2 uv_MainTex;
        };

        void surf(Input IN, inout SurfaceOutput o)
        {
            fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
            fixed alpha = _Color.a;
            fixed3 output;

            o.Albedo = tex.rgb;
            o.Alpha = tex.a;
        }
        ENDCG
        
        Pass
        {
            Cull Front

            CGPROGRAM
            #pragma vertex vertexShader
            #pragma fragment fragmentShader

            half4 _OutlineColor;
            half _OutlineWidth;

            float4 vertexShader(float4 position : POSITION, float3 normal : NORMAL) : SV_POSITION
            {
                float4 clipPosition = UnityObjectToClipPos(position);
                float3 clipNormal = mul((float3x3)UNITY_MATRIX_VP, mul((float3x3)UNITY_MATRIX_M, normal));

                float2 offset = normalize(clipNormal.xy) * _OutlineWidth;
                clipPosition.xy += offset;

                return clipPosition;
            }

            half4 fragmentShader() : SV_Target
            {
                return _OutlineColor;
            }
            ENDCG
        }
    }

    Fallback "Mobile/VertexLit"
}