Shader "Marumasa/VR180-Preview"
{
    Properties
    {
        // 右、前、上、下 の順に並んだ 4:1 のテクスチャ -> 個別のテクスチャに変更
        [NoScaleOffset][SingleLineTexture] _LeftEyeTex0( "LeftEye-0(R)", 2D ) = "black" {}
        [NoScaleOffset][SingleLineTexture] _LeftEyeTex1( "LeftEye-1(L)", 2D ) = "black" {}
        [NoScaleOffset][SingleLineTexture] _LeftEyeTex2( "LeftEye-2(UP)", 2D ) = "black" {}
        [NoScaleOffset][SingleLineTexture] _LeftEyeTex3( "LeftEye-3(DOWN)", 2D ) = "black" {}

        [NoScaleOffset][SingleLineTexture] _RightEyeTex0( "RightEye-0(R)", 2D ) = "black" {}
        [NoScaleOffset][SingleLineTexture] _RightEyeTex1( "RightEye-1(L)", 2D ) = "black" {}
        [NoScaleOffset][SingleLineTexture] _RightEyeTex2( "RightEye-2(UP)", 2D ) = "black" {}
        [NoScaleOffset][SingleLineTexture] _RightEyeTex3( "RightEye-3(DOWN)", 2D ) = "black" {}

    }
    SubShader
    {
	    Tags
		{
			"RenderType" = "Opaque"
			"Queue" = "Geometry"
			"DisableBatching" = "True"
			"IsEmissive" = "true"
		}
		
		Cull Front
		ZWrite On
		ZTest LEqual

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION; // 頂点座標
                UNITY_VERTEX_INPUT_INSTANCE_ID // インスタンスID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 viewDir : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _LeftEyeTex0;
            sampler2D _LeftEyeTex1;
            sampler2D _LeftEyeTex2;
            sampler2D _LeftEyeTex3;

            sampler2D _RightEyeTex0;
            sampler2D _RightEyeTex1;
            sampler2D _RightEyeTex2;
            sampler2D _RightEyeTex3;


            // 頂点シェーダーは視線ベクトルを計算
            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                // オブジェクトの回転に追従するため、カメラ相対のベクトルを使用
                float3 objSpaceCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1.0)).xyz;
                float3 viewDir = v.vertex.xyz - objSpaceCameraPos;

                // -45度回転 (左に90度ずれていたのを修正)
                float3 rotDir = viewDir;
                float k = 0.70710678;
                rotDir.x = (viewDir.x - viewDir.z) * k;
                rotDir.z = (viewDir.x + viewDir.z) * k;
                
                // 右目は映像が180度回転してしまっているため、視線ベクトルを180度(Y軸回り)回転させる
                if (unity_StereoEyeIndex == 1) {
                    rotDir.x = -rotDir.x;
                    rotDir.z = -rotDir.z;
                }
                o.viewDir = rotDir;

                return o;
            }

            // 視線ベクトルを元に、4つのテクスチャから適切なUVとインデックス、マスクを計算する関数
            // テクスチャマッピング (VR180-Format.shaderと整合):
            // 0: R (Side Z), 1: L (Side X), 2: UP (+Y), 3: DOWN (-Y)
            
            void CalculateCubeUV(float3 dir, float3 absDir, bool isRightEye, out float2 uv, out int texIndex, out float mask)
            {
                mask = 1.0;
                uv = float2(0,0);
                texIndex = -1;
                
                float u_local, v_local;

                // どの軸方向が支配的かによって分岐
                if (absDir.x >= absDir.y && absDir.x >= absDir.z)
                {
                    // X軸方向
                    if (isRightEye) {
                         // 右目 (+X) -> Index 1 (L)
                         if (dir.x > 0) {
                            texIndex = 1;
                            
                            // 投影計算
                            u_local = 0.5 * (-dir.z / absDir.x) + 0.5;
                            v_local = 0.5 * ( dir.y / absDir.x) + 0.5;
                            
                         } else {
                            // -X は描画しない
                            mask = 0.0;
                         }
                    } else {
                        // 左目 (-X) -> Index 1 (L)
                        if(dir.x < 0) {
                            texIndex = 1;
                            
                             u_local = 0.5 * ( dir.z / absDir.x) + 0.5;
                             v_local = 0.5 * ( dir.y / absDir.x) + 0.5;
                        } else {
                            mask = 0.0;
                        }
                    }
                }

                else if (absDir.y >= absDir.x && absDir.y >= absDir.z)
                {
                    // Y軸方向
                    if (dir.y > 0) {
                        // 上面 (+Y) -> Index 2 (UP)
                        texIndex = 2;
                        
                        // 投影計算
                        float u_orig = 0.5 * ( dir.x / absDir.y) + 0.5;
                        float v_orig = 0.5 * (-dir.z / absDir.y) + 0.5;
                        
                        if (isRightEye) {
                            u_local = 1.0 - u_orig;
                            v_local = 1.0 - v_orig;
                        } else {
                            u_local = u_orig;
                            v_local = v_orig;
                        }
                        
                    } else {
                        // 下面 (-Y) -> Index 3 (DOWN)
                        texIndex = 3;
                        
                        // 投影計算
                        float u_orig = 0.5 * ( dir.x / absDir.y) + 0.5;
                        float v_orig = 0.5 * ( dir.z / absDir.y) + 0.5;

                        if (isRightEye) {
                            u_local = 1.0 - u_orig;
                            v_local = 1.0 - v_orig;
                        } else {
                            u_local = u_orig;
                            v_local = v_orig;
                        }
                    }
                }
                else
                {
                    // Z軸方向
                    if (isRightEye) {
                        // 右目 (-Z) -> Index 0 (R)
                        if (dir.z < 0) {
                             texIndex = 0;
                             u_local = 0.5 * (-dir.x / absDir.z) + 0.5;
                             v_local = 0.5 * ( dir.y / absDir.z) + 0.5;
                        } else {
                             mask = 0.0;
                        }
                    } else {
                        // 左目 (+Z) -> Index 0 (R)
                        if (dir.z > 0) {
                            texIndex = 0;
                            u_local = 0.5 * ( dir.x / absDir.z) + 0.5;
                            v_local = 0.5 * ( dir.y / absDir.z) + 0.5;
                        } else {
                            mask = 0.0;
                        }
                    }
                }

                float margin = 0.001;
                u_local = clamp(u_local, margin, 1.0 - margin);
                v_local = clamp(v_local, margin, 1.0 - margin);

                uv.x = u_local;
                uv.y = v_local;
                
                if (texIndex == -1) mask = 0.0;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float3 rotDir = i.viewDir;
                
                float2 textureUV;
                float mask;
                int texIndex;
                bool isRightEye = (unity_StereoEyeIndex == 1); // 0: 左目, 1: 右目

                // 視線ベクトルと目の情報から、サンプリング座標とテクスチャインデックスを計算
                CalculateCubeUV(rotDir, abs(rotDir), isRightEye, textureUV, texIndex, mask);

                if (mask < 0.5)
                {
                    return fixed4(0,0,0,1);
                }

                fixed4 col = fixed4(0,0,0,1);
                
                if (isRightEye)
                {
                     if (texIndex == 0) col = tex2D(_RightEyeTex0, textureUV);
                     else if (texIndex == 1) col = tex2D(_RightEyeTex1, textureUV);
                     else if (texIndex == 2) col = tex2D(_RightEyeTex2, textureUV);
                     else if (texIndex == 3) col = tex2D(_RightEyeTex3, textureUV);
                }
                else
                {
                     if (texIndex == 0) col = tex2D(_LeftEyeTex0, textureUV);
                     else if (texIndex == 1) col = tex2D(_LeftEyeTex1, textureUV);
                     else if (texIndex == 2) col = tex2D(_LeftEyeTex2, textureUV);
                     else if (texIndex == 3) col = tex2D(_LeftEyeTex3, textureUV);
                }

                return col;
            }
            ENDCG
        }
    }
}