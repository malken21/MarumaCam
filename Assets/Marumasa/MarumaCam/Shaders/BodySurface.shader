Shader "Marumasa/BodySurface"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="BodySurface" }
        LOD 100

        Cull Back

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

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
                float discardFlag : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                
                float cotFov = abs(UNITY_MATRIX_P._m11);
                float aspectDiff = abs(abs(UNITY_MATRIX_P._m00) - cotFov);
                float stereoOffset = abs(UNITY_MATRIX_P._m02);
                float isPerspective = UNITY_MATRIX_P._m33; 
                o.discardFlag = (abs(cotFov - 1.0) < 0.05 && aspectDiff < 0.01 && stereoOffset < 0.01 && isPerspective == 0) ? 1.0 : 0.0;
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                if (i.discardFlag > 0.5) discard;
                fixed4 c = tex2D(_MainTex, i.uv);
                return c;
            }
            ENDCG
        }
    }
    FallBack "Unlit/Texture"
}
