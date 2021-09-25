// Heat Distortion là hiệu ứng làm méo hình ảnh đằng sau

Shader "Custom/HeatDistortion"
{
    Properties
    {
        _Color("Tint Color", Color) = (1,1,1,1)
        _Noise("Noise Texture", 2D) = "white" {}
        _StrengthFilter("Strength Filter", 2D) = "white" {}
        _Strength("Distort Strength", float) = 1.0
        _Speed("Distort Speed", float) = 1.0
    }
    SubShader
    {
        Tags
        {
            "Queue" = "Transparent"
            "DisableBatching" = "True"
        }

        ZTest Always // luôn render đè lên mọi vật thể

        GrabPass
        {
            "_BackgroundTexture" // lấy hình ảnh phía sau của vật thể chứa Shader này
        }

        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 texCoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 grabPos : TEXCOORD0;
            };

            sampler2D _BackgroundTexture; // Data từ GrabPass "_BackgroundTexture"

            float4 _Color;
            sampler2D _Noise;
            sampler2D _StrengthFilter;
            float _Strength;
            float _Speed;

            v2f vert(appdata input)
            {
                v2f output;

                // Đoạn này để hiệu ứng Billboard (luôn xoay hướng nhìn về camera)
                // float4 pos = input.vertex;
                // float4 originInViewSpace = float4(UnityObjectToViewPos(float3(0, 0, 0)), 1);
                // float4 vertInViewSpace = originInViewSpace + float4(pos.x, pos.z, 0, 0);
                // pos = mul(UNITY_MATRIX_P, vertInViewSpace);
                // output.pos = pos;

                // Đoạn này là không có Billboard
                output.pos = UnityObjectToClipPos(input.vertex);

                // grab coordinates
                output.grabPos = ComputeGrabScreenPos(output.pos);
                float noise = tex2Dlod(_Noise, float4(input.texCoord, 0)).rgb;
                float filter = tex2Dlod(_StrengthFilter, float4(input.texCoord,0)).rgb;
                output.grabPos.x += cos(noise * _Time.y * _Speed) * filter * _Strength;
                output.grabPos.y += sin(noise * _Time.y * _Speed) * filter * _Strength;

                return output;
            }

            fixed4 frag(v2f input) : SV_Target
            {
                fixed4 result = tex2Dproj(_BackgroundTexture, input.grabPos); 
                return result * _Color;
            }
            ENDCG
        }
    }
}