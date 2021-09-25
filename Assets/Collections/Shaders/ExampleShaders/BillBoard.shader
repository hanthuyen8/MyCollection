// Bill board là hiệu ứng luôn xoay mặt Front của Mesh về phía Camera

Shader "Custom/Billboard"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque"
        }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert(appdata input)
            {
                v2f output;

                float4 pos = input.vertex;
                float4 originInViewSpace = float4(UnityObjectToViewPos(float3(0, 0, 0)), 1);
                float4 vertInViewSpace = originInViewSpace + float4(pos.x, pos.y, 0, 0);
                pos = mul(UNITY_MATRIX_P, vertInViewSpace);

                output.vertex = pos;
                output.uv = input.uv;

                return output;
            }

            fixed4 frag(v2f input) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, input.uv);
                return col;
            }
            ENDCG
        }
    }
}