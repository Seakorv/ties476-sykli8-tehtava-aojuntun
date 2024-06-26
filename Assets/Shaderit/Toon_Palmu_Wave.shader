Shader "Unlit/Toon_Palmu_Wave"

{
    
    Properties
    {
        _Color("Color", Color) = (0, 0.65, 0, 1)
        _MainTex ("Texture", 2D) = "white" {}
        //Ambient valoa kaikkiin objektin pintoihin tällä
        [HDR]
        _AmbientColor("Ambient Color", Color) = (0.4, 0.4, 0.4, 1)
        [HDR]
        _SpecularColor("Specular Color", Color) = (0.9, 0.9, 0.9, 1)
        //heijastuksen kokoa säätävä
        _Glossiness("Glossiness", Float) = 32
        [HDR]
        _RimColor("Rim Color", Color) = (1, 1, 1, 1)
        _RimAmount("Rim Amount", Range(0, 1)) = 0.716
        //valoreunan smoothius
        _RimThreshold("Rim Threshold", Range(0, 1)) = 0.1
    }
    SubShader
    {
        Tags 
        { 
            "LightMode" = "ForwardBase"
            "PassFlags" = "OnlyDirectional"
        }
        LOD 100

        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            //Alla oleva rikkoo shaderin jostain syystä, tutorialin
            //mukaan pitäisi toimia juuri näin.
            #pragma multi_compile_fwdbase 

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 worldNormal : NORMAL;
                float3 viewDir : TEXCOORD1;
                SHADOW_COORDS(2)
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;
            float4 _AmbientColor;
            float _Glossiness;
            float4 _SpecularColor;
            float4 _RimColor;
            float _RimAmount;
            float _RimThreshold;

            v2f vert (appdata v)
            {
                v2f o;
                v.vertex.z += sin(v.vertex.z + _Time.y) * 0.1;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                
                //Muuttaa verteksin koordinaatit varjoksi maailmaan
                //automaagisesti. Autolight.cginc:istä napattu
                TRANSFER_SHADOW(o)
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 normal = normalize(i.worldNormal);
                float NdotL = dot(_WorldSpaceLightPos0, normal);

                float shadow = SHADOW_ATTENUATION(i);

                float lightIntensity = smoothstep(0, 0.01, NdotL * shadow);
                float4 light = lightIntensity * _LightColor0;
                
                float3 viewDir = normalize(i.viewDir);

                float3 halfVector = normalize(_WorldSpaceLightPos0 + viewDir);
                float NdotH = dot(normal, halfVector);

                float specularIntensity = pow(NdotH * lightIntensity, _Glossiness * _Glossiness);
                float specularIntensitySmooth = smoothstep(0.005, 0.01, specularIntensity);
                float4 specular = specularIntensitySmooth * _SpecularColor;
                
                float4 rimDot = 1 - dot(viewDir, normal);
                float rimIntensity = rimDot * pow(NdotL, _RimThreshold);
                rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimIntensity);
                float4 rim = rimIntensity * _RimColor;

                // sample the texture
                float4 sample = tex2D(_MainTex, i.uv);
                
                return _Color * sample * (_AmbientColor + light + specular + rim);
            }
            ENDCG
        }
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
