// Diffuse nhưng có sử dụng _Color làm Tint
// Dùng alpha của _Color để pha màu với _MainTex

Shader "Custom/DiffuseWithTint"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
        _Color ("Tint", Color) = (1,1,1,1)
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
            output.r = (_Color.r * alpha) + (1 - alpha) * tex.r;
            output.g = (_Color.g * alpha) + (1 - alpha) * tex.g;
            output.b = (_Color.b * alpha) + (1 - alpha) * tex.b;

            o.Albedo = output;
            o.Alpha = tex.a;
        }
        ENDCG
    }

    Fallback "Mobile/VertexLit"
}