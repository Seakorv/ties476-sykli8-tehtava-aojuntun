Shader "Unlit/Toon_Meri"

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
            //"Queue" = "Transparent"
            //"RenderType" = "Transparent" 
            "LightMode" = "ForwardBase"
            "PassFlags" = "OnlyDirectional"
        }
        LOD 100

        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            //Alla oleva rikkoo shaderin jostain syystä, tutorialin
            //mukaan pitäisi toimia juuri näin.
            //#pragma multi_compile_fwdbase 

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
                float4 vertex : SV_POSITION;
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
                v.vertex.z += sin(v.vertex.y + _Time.y) * 0.1 * cos(2 * v.vertex.y + _Time.y);
                o.vertex = UnityObjectToClipPos(v.vertex);
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

                //float shadow = SHADOW_ATTENUATION(i);
                
                float3 viewDir = normalize(i.viewDir);

                float3 halfVector = normalize(_WorldSpaceLightPos0 + viewDir);
                float NdotH = dot(normal, halfVector);
                
                float4 rimDot = 1 - dot(viewDir, normal);
                float rimIntensity = rimDot * pow(NdotL, _RimThreshold);
                rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimIntensity);
                float4 rim = rimIntensity * _RimColor;

                // sample the texture
                float4 sample = tex2D(_MainTex, i.uv);

                float2 uv = i.uv - .5; //keskipiste
                float d = length(uv); //pituus keskelle
                float m = smoothstep(.18, .21, d); //keskialue smootheilla reunoilla

                //Tässä poistin vain valon alla olevasta, jottei meri mennyt mustaksi.
                return float4(0.09, 0, 0.2, m) * sample * (_AmbientColor + rim);
            }
            ENDCG
        }
        UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
