Shader "Unlit/WaterRippleEffectShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_NoiseTex("NoiseTex",2D) = ""{}
		_Distortion("Distortion",Range(-5,5))=1
		_Scale("Scale",float)=0.01
		_Frequency("Frequency",float) =60
		_RippleSpeed("RippleSpeed",float) = 10
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
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
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _NoiseTex;
			float _Size,_Distortion,_RippleWidth,_Scale,_Frequency,_RippleSpeed;
			float _CurRipples[1000];
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed2 aspect = fixed2(1,1);
				float2 uv = i.uv*_Size*aspect;
				float2 gv = frac(uv)-.5;
			    
				float2 id = floor(uv);
				int coordToInt = id.x+(id.x*(_Size-1)+id.y);
				float curRippleDis = _CurRipples[coordToInt];

				float x = 0;
				float y = 0;

				float2 ripplePos = (gv+float2(x,y))/aspect;
				float dis = length(ripplePos);
				float rippleOffs = _Scale*sin(dis*_Frequency+_Time.y*_RippleSpeed);
				float factor = clamp(_RippleWidth-abs(curRippleDis-dis),0,1);		

				fixed2 offs = ripplePos*rippleOffs*factor;

				fixed4 col=0;
				col += rippleOffs*100*factor;

				//if(gv.x>.48 || gv.y>.49) return fixed4(1,0,0,1);
				return tex2D(_MainTex,i.uv+offs*_Distortion);
			}
			ENDCG
		}
	}
}
