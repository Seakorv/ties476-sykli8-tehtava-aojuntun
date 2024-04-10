Shader "Esimerkki/EsimerkkiUnlit"
{
    /*
    Tama on esimerkki shaderi, jossa ollaan asetettu "Unlit" shaderille yksinkertaiset varjot.

    Mika on "Unlit"? -> https://discussions.unity.com/t/what-are-shader-types/248348

    Voit kayttaa tata apuna saamaan omiin shadereihisi varjot, mutta yrita parantaa varjojen luontia jotenkin!
    Esimerkiksi tama shaderi ei ota huomioon ollenkaan ympariston valoa huomioon. Sellainen vois olla ihan kiva toteuttaa :)
    Noh, tutoriaaleista saa paljon irti! 
    
    Ps. Muista etta kun shader tiedosto on tehty, siita pitaa tehda myos materiaali. Sama patee Shader Graphille.
    */


    Properties //Tähän listataan kaikki muuttujat. Muuttujia voi vaihtaa editorin kautta.
    {
        _Color("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { // Unity docs: https://docs.unity3d.com/Manual/SL-SubShaderTags.html
            "LightMode" = "ForwardBase"
            "PassFlags" = "OnlyDirectional"
            "RenderType" = "Opaque"
        }
        LOD 100

        Pass
        {
            CGPROGRAM 

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : NORMAL;
                float2 uv : TEXCOORD0;
                float3 viewDir : TEXCOORD1;
                SHADOW_COORDS(2)
            };

            //Muuttujat pitaa olla myos tassa.
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Color;

            v2f vert (appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = WorldSpaceViewDir(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                //Varjot
                float shadow = SHADOW_ATTENUATION(i);
                // Lerp() on yleinen tapa "sekoittaa kaksi varia":
                // Unity.MathF : https://docs.unity3d.com/ScriptReference/Mathf.Lerp.html
                // Nvidia CG kieli : https://developer.download.nvidia.com/cg/lerp.html
                float shadowResult = lerp(shadow,_Color, 0.5);

                //Textuuri
                fixed4 tex = (1,1,1,1);

                return tex * _Color * (shadowResult);
            }
            ENDCG
        } UsePass "Legacy Shaders/VertexLit/SHADOWCASTER"
    }
}
