Shader "Marumasa/VR180-Format"
{
	Properties
	{
		[NoScaleOffset][SingleLineTexture] _LeftEyeTex0( "LeftEye-0(R)", 2D ) = "black" {}
		[NoScaleOffset][SingleLineTexture] _LeftEyeTex1( "LeftEye-1(L)", 2D ) = "black" {}
		[NoScaleOffset][SingleLineTexture] _LeftEyeTex2( "LeftEye-2(UP)", 2D ) = "black" {}
		[NoScaleOffset][SingleLineTexture] _LeftEyeTex3( "LeftEye-3(DOWN)", 2D ) = "black" {}

		[NoScaleOffset][SingleLineTexture] _RightEyeTex0( "RightEye-0(R)", 2D ) = "black" {}
		[NoScaleOffset][SingleLineTexture] _RightEyeTex1( "RightEye-1(L)", 2D ) = "black" {}
		[NoScaleOffset][SingleLineTexture] _RightEyeTex2( "RightEye-2(UP)", 2D ) = "black" {}
		[NoScaleOffset][SingleLineTexture] _RightEyeTex3( "RightEye-3(DOWN)", 2D ) = "black" {}

		_ScreenWidth( "Screen Width", Float ) = 16
		_ScreenHeight( "Screen Height", Float ) = 9


		[Toggle] _IsLocal( "IsLocal", Float ) = 0
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags
		{
			"RenderType" = "Overlay"
			"Queue" = "Overlay+1001"
			"DisableBatching" = "True"
			"IsEmissive" = "true"
		}
		
		Cull Front
		ZWrite On
		ZTest Always
		
		CGPROGRAM
		#include "UnityShaderVariables.cginc"
		#pragma target 3.5
		#define ASE_VERSION 19900
		#pragma surface surf Unlit keepalpha addshadow fullforwardshadows noambient novertexlights nolightmap nodynlightmap nodirlightmap nofog nometa noforwardadd vertex:vertexDataFunc

		struct Input
		{
			float4 screenPos;
			float discardFlag;
		};

		uniform sampler2D _LeftEyeTex0;
		uniform sampler2D _LeftEyeTex1;
		uniform sampler2D _LeftEyeTex2;
		uniform sampler2D _LeftEyeTex3;
		
		uniform sampler2D _RightEyeTex0;
		uniform sampler2D _RightEyeTex1;
		uniform sampler2D _RightEyeTex2;
		uniform sampler2D _RightEyeTex3;

		uniform float4 _LeftEyeTex0_TexelSize;
		uniform float4 _RightEyeTex0_TexelSize;


		uniform bool _IsLocal;
		uniform float _ScreenWidth;
		uniform float _ScreenHeight;
		uniform int _VRChatCameraMode;


		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );

			v.vertex.xyz *= 64.0;
			v.vertex.w = 1;

			o.discardFlag = 0;
			if ( !_IsLocal )
			{
				float3 objectPos = float3( unity_ObjectToWorld[0].w, unity_ObjectToWorld[1].w, unity_ObjectToWorld[2].w );
				if ( distance( _WorldSpaceCameraPos, objectPos ) > 0.2 ) o.discardFlag = 1;
			}

			float asymmetric = abs( unity_CameraProjection[0][2] );
			bool isVR = asymmetric > 0.001;
			if ( _VRChatCameraMode == 0 && isVR ) o.discardFlag = 1;
		}

		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4( 0, 0, 0, s.Alpha );
		}



		void surf( Input i, inout SurfaceOutput o )
		{
			if ( i.discardFlag > 0.5 ) discard;

			// スクリーン座標の正規化
			float4 screenPosNorm = i.screenPos / (i.screenPos.w + 1e-7);
			screenPosNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? screenPosNorm.z : screenPosNorm.z * 0.5 + 0.5;

			// スクリーン座標を極座標（方位角・仰角）に変換
			// 定数計算を展開し最適化 (UNITY_PI * 2.0 = 6.2831853, radians(45.0) = 0.78539816)
			float azimuth = screenPosNorm.x * 6.2831853 - 2.35619449;
			float elevation = (screenPosNorm.y * 6.2831853 - 3.14159265) * 0.5;

			float cosElevation = cos( elevation );
			float sinElevation = sin( elevation );
			float sinAzimuth, cosAzimuth;
			sincos( azimuth, sinAzimuth, cosAzimuth );

			// 球面上のベクトルを計算
			float3 sphereVector = float3(
				cosElevation * sinAzimuth,
				sinElevation,
				cosElevation * cosAzimuth
			);

			// 右目かどうかを判定
			half isRightEye = step( 0.5, screenPosNorm.x );
			
			float2 finalUV = 0;
			half finalMask = 0;
			float4 finalColor = 0;

			// アトラス用オフセットロジックを廃止。
			// マッピング: 0: R, 1: L, 2: UP, 3: DOWN
			
			// ロジックの一貫性のため、全てのテクスチャサイズは同一と仮定し Tex0 のサイズを使用する
			float4 texelSize = isRightEye > 0.5 ? _RightEyeTex0_TexelSize : _LeftEyeTex0_TexelSize;
			
			// 個別のテクスチャに対してパディング(境界処理)を行う
			float2 padding = float2( texelSize.x * 0.5, texelSize.y * 0.5 );


			float3 absVec = abs( sphereVector );
			float maxComp = max( absVec.x, max( absVec.y, absVec.z ) );
			
			bool isValidFace = false;
			float2 rawUV = 0;
			int faceIndex = 0; // 0:R, 1:L, 2:UP, 3:DOWN
			bool swap = false;
			
			// 右目: > 0.5, 左目: <= 0.5
			// 最大成分のチェック（主軸の判定）

			if ( maxComp == absVec.y ) // UP or DOWN
			{
				float2 proj = sphereVector.xz / absVec.y;
				isValidFace = true;
				// 上面 (sphereVector.y > 0)
				if ( sphereVector.y > 0 )
				{
					if ( isRightEye > 0.5 )
						rawUV = float2( -0.5, 0.5 ) * proj + 0.5;
					else
						rawUV = float2( 0.5, -0.5 ) * proj + 0.5;
						
					faceIndex = 2; // UP
				}
				else // 下面 (sphereVector.y <= 0)
				{
					if ( isRightEye > 0.5 )
						rawUV = proj * -0.5 + 0.5;
					else
						rawUV = proj * 0.5 + 0.5;

					faceIndex = 3; // DOWN
				}
			}
			else if ( maxComp == absVec.x ) // Side X
			{
				bool isSide = false;
				
				// 右目: 左側面 (+X)
				if ( isRightEye > 0.5 )
				{
					if ( sphereVector.x > 0 )
					{
						float2 proj = sphereVector.yz / absVec.x;
						rawUV = float2( 0.5, -0.5 ) * proj + 0.5; 
						faceIndex = 1; // L
						swap = true;
						isValidFace = true;
					}
				}
				else // 左目: 左側面 (-X)
				{
					if ( sphereVector.x < 0 )
					{
						float2 proj = sphereVector.yz / absVec.x;
						rawUV = proj * 0.5 + 0.5;
						faceIndex = 1; // L
						swap = true;
						isValidFace = true;
					}
				}
			}
			else // Side Z
			{
				// 右目: 右側面 (-Z)
				if ( isRightEye > 0.5 )
				{
					if ( sphereVector.z < 0 )
					{
						float2 proj = sphereVector.xy / absVec.z;
						rawUV = float2( -0.5, 0.5 ) * proj + 0.5;
						faceIndex = 0; // R
						isValidFace = true;
					}
				}
				else // 左目: 右側面 (+Z)
				{
					if ( sphereVector.z > 0 )
					{
						float2 proj = sphereVector.xy / absVec.z;
						rawUV = proj * 0.5 + 0.5;
						faceIndex = 0; // R
						isValidFace = true;
					}
				}
			}

			if ( isValidFace )
			{
				float2 clampedUV = clamp( rawUV, padding, 1.0 - padding );
				
				finalMask = step( 0.0, rawUV.x ) * step( rawUV.x, 1.0 ) * step( 0.0, rawUV.y ) * step( rawUV.y, 1.0 );

				if ( swap )
				{
					clampedUV = clampedUV.yx;
				}

				// 最終的なUVは特定のテクスチャに対する0-1のUV
				finalUV = clampedUV;
				
				if( isRightEye > 0.5 )
				{
					if( faceIndex == 0 ) finalColor = tex2D( _RightEyeTex0, finalUV );
					else if( faceIndex == 1 ) finalColor = tex2D( _RightEyeTex1, finalUV );
					else if( faceIndex == 2 ) finalColor = tex2D( _RightEyeTex2, finalUV );
					else finalColor = tex2D( _RightEyeTex3, finalUV );
				}
				else
				{
					if( faceIndex == 0 ) finalColor = tex2D( _LeftEyeTex0, finalUV );
					else if( faceIndex == 1 ) finalColor = tex2D( _LeftEyeTex1, finalUV );
					else if( faceIndex == 2 ) finalColor = tex2D( _LeftEyeTex2, finalUV );
					else finalColor = tex2D( _LeftEyeTex3, finalUV );
				}

				finalColor *= finalMask;
			}

			o.Emission = finalColor.rgb;
			o.Alpha = 1;
			
			float squareScreenMask = abs( sign( _ScreenParams.x - _ScreenParams.y ) );
			clip( finalColor.a * squareScreenMask - 0.5 );
		}

		ENDCG
	}
	Fallback "Diffuse"
}