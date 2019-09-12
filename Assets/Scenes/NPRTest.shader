Shader "Unlit/NPRTest"
{
	Properties
	{
		_MainTex ("Albedo", 2D) = "white" {}
		_MainTexSize("MainTexSize",Range(0,2048))=2048
		_Specular("Specular", 2D) = ""{}
		_Smoothness("Smoothness",Range(0,1)) =1
		_NormalMap("NormalMap",2D) = ""{}
		_OutLine("OutLine",float) = 0.5
		_DiffuseSegment("DiffuseSegment",Vector) = (0,0,0,0)
		_SpecularSegment("SpecularSegment",float) =0.5
		_Shininess("Shininess",float)=1.2
		_ColdColor("ColdColor",Range(0,1))=0.5
		_WarmColor("WarmColor",Range(0,1))=0.5
		_Alpha ("Alpha", Range(0, 1)) = 0.5
		_Beta ("Beta", Range(0, 1)) = 0.5
		_SobelG("SobelG",Range(0,255))=100
		_RimColor("RimColor",Color)=(1,1,1,1)
		_NoiseTex("NoiseTex",2D)=""{}
		_FadeOut("FadeOut",Range(0,1))=0
		_FadeOutColor("FadeOutColor",color)=(1,1,1,1)
		_ColorFactor("ColorFactor",Range(0,1))=0
		_MoveDir("MoveDir",vector) = (0,0,-1,0)
		_Scale("Scale",float) = 1
	}
	SubShader
	{
		Tags {"Queue" = "Geometry" "RenderType"="Opaque" }

		Pass
		{
			ZTest Greater
			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex:POSITION;
				float3 normal:NORMAL;	
			};

			struct v2f
			{
				float4 vertex:SV_POSITION;
				float3 worldNormal:TEXCOORD;
				float3 worldViewDir:TEXCOORD1;
			};

			fixed4 _RimColor;

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex=UnityObjectToClipPos(v.vertex);
				o.worldNormal=UnityObjectToWorldNormal(v.normal);
				o.worldViewDir = WorldSpaceViewDir(v.vertex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed3 worldViewDir = normalize(i.worldViewDir);
				fixed3 worldNormal = normalize(i.worldNormal);
				float rim = 1- saturate(dot(worldNormal,worldViewDir))*5;
				
				return _RimColor*rim;//*pow(rim,1);
			}
			ENDCG
		}
			
		Pass
		{
			ZTest LEqual
			Cull Back
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal:NORMAL;
				float3 tangent:TANGENT;
			};

			struct v2f
			{
				float4 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 tangent:TEXCOORD1;
				float3 binormal:TEXCOORD2;
				float3 normal:TEXCOORD3;
				float3 worldLightDir:TEXCOORD4;
				float3 worldViewDir:TEXCOORD5;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _Specular;
			float4 _Specular_ST;
			float _Smoothness;
			sampler2D _NormalMap;
			float4 _NormalMap_ST;
			float4 _DiffuseSegment;
			float _SpecularSegment;
			float _Shininess;
			float _ColdColor;
			float _WarmColor;
			float _Alpha;
			float _Beta;
			fixed _SobelG;
			fixed _MainTexSize;
			fixed4 _RimColor;
			float _FadeOut;
			sampler2D _NoiseTex;
			fixed4 _FadeOutColor;
			float _ColorFactor;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.uv,_NormalMap);
				
				float3 binormal = cross(v.normal,v.tangent);
				o.tangent= v.tangent;
				o.binormal=binormal;
				o.normal=v.normal;
		
				o.worldViewDir = WorldSpaceViewDir(v.vertex);
				o.worldLightDir = WorldSpaceLightDir(v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float fadeOutRand = tex2D(_NoiseTex,i.uv.xy).r;
				if(fadeOutRand<_FadeOut)
				{
					discard;
	
				}	
				fixed4 packedNormal=tex2D(_NormalMap,i.uv.zw);
				fixed3 tangentNormal=UnpackNormal(packedNormal);
				float3x3 rotation = float3x3(i.tangent.xyz,i.binormal,i.normal);
				float3 worldLightDir = normalize(i.worldLightDir);
				float3 worldViewDir=normalize(i.worldViewDir);
				float3 worldNorml = normalize(mul(tangentNormal,rotation));
				float3 worldReflect =normalize(reflect(-worldViewDir,worldNorml));		

				half4 texSpecular = tex2D(_Specular,i.uv.xy);
				half4 texColor=tex2D(_MainTex, i.uv.xy);

				half3 gray = half3(0.3,0.59,0.11);
				float g00 = dot(tex2D(_MainTex, i.uv.xy+fixed2(-1,-1)/_MainTexSize).rgb,gray);
				float g10 = dot(tex2D(_MainTex, i.uv.xy+fixed2(0,-1)/_MainTexSize).rgb,gray);
				float g20 = dot(tex2D(_MainTex, i.uv.xy+fixed2(1,-1)/_MainTexSize).rgb,gray);
				float g01 = dot(tex2D(_MainTex, i.uv.xy+fixed2(-1,0)/_MainTexSize).rgb,gray);
				float g11 = dot(tex2D(_MainTex, i.uv.xy+fixed2(0,0)/_MainTexSize).rgb,gray);
				float g21 = dot(tex2D(_MainTex, i.uv.xy+fixed2(1,0)/_MainTexSize).rgb,gray);
				float g02 = dot(tex2D(_MainTex, i.uv.xy+fixed2(-1,1)/_MainTexSize).rgb,gray);
				float g12 = dot(tex2D(_MainTex, i.uv.xy+fixed2(0,1)/_MainTexSize).rgb,gray);
				float g22 = dot(tex2D(_MainTex, i.uv.xy+fixed2(1,1)/_MainTexSize).rgb,gray);

				float Gx = -g00+g20-2*g01+2*g21-g02+g22;
				float Gy = g00+2*g10+g20-g02-2*g12-g22;
				float G = abs(Gx)+abs(Gy);
				float th = atan2(Gy,Gx);

				fixed3 k_blue=fixed3(0,0,_ColdColor);
				fixed3 k_yellow=fixed3(_WarmColor,_WarmColor,0);
				fixed3 k_cool = k_blue+_Alpha*texColor;
				fixed3 k_warm = k_yellow+_Beta*texColor;

				float diffuse = dot(worldLightDir,worldNorml)*0.5+0.5;
				if(diffuse<_DiffuseSegment.x){
				diffuse = _DiffuseSegment.x;
				}
				else if(diffuse<_DiffuseSegment.y){
				diffuse = _DiffuseSegment.y;
				}
				else if(diffuse<_DiffuseSegment.z){
				diffuse = _DiffuseSegment.z;
				}
				else{
				diffuse = _DiffuseSegment.w;
				}

				float specular =max(0,dot(normalize(worldViewDir+worldLightDir),worldNorml));
				specular= pow(specular,_Shininess);
				if(specular<_SpecularSegment){
				specular=0;
				}
				else{
				specular=1;
				}
				float h = (1+diffuse)*0.5;
				diffuse = h*k_cool + (1-h)*k_warm;
				fixed4 col = diffuse + specular*texSpecular;// + ambient;
				float lerpValue = _FadeOut/fadeOutRand;
				if(lerpValue > _ColorFactor){
				return _FadeOutColor;
				}
				return diffuse + specular*texSpecular;
			}
			ENDCG
		}

	Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal:NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float offs:TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _MoveDir;
			float _Scale;
			
			v2f vert (appdata v)
			{
				v2f o;		
				float n= dot(v.normal,_MoveDir);
				if(n>=0)
				{
				v.vertex.xyz += _MoveDir*_Scale;
				}		
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				col.xyz *=2;
				col.w=0.2;
				return col;
			}
			ENDCG
		}
	}
}
