// @Maintainer jwrl
// @Released 2018-06-22
// @Author jwrl
// @Created 2018-06-13
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_SplitSqueeze_640.png
// @see https://www.lwks.com/media/kunena/attachments/6375/Ax_SplitSqueeze.mp4
//-----------------------------------------------------------------------------------------//
// User effect Ax_SplitSqueeze.fx
//
// This is similar to the split squeeze effect, customised to suit its use with alpha
// channels.  It moves the separated alpha image halves apart and squeezes them to the
// edge of screen or expands the halves from the edges.  It operates either vertically
// or horizontally depending on the user setting.
//
// Alpha levels are boosted to support Lightworks titles, which is the default setting.
//
// This is a revision of an earlier effect, Adx_SplitSqueeze.fx, which added the ability
// to wipe between two titles.  That added needless complexity, when the same result can
// be obtained by overlaying two effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha split squeeze";
   string Category    = "Mix";
   string SubCategory = "Alpha transitions";
   string Notes       = "Splits a title in half and squeezes the halves apart horizontally or vertically";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Sup;
texture Vid;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Video = sampler_state { Texture = <Vid>; };

sampler s_Super = sampler_state
{
   Texture   = <Sup>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int Boost
<
   string Description = "If using a Lightworks text effect disconnect its input and set this first";
   string Enum = "Crawl/Roll/Titles,Video/External image";
> = 0;

float Amount
<
   string Description = "Progress";
   float MinVal = 0.0;
   float MaxVal = 1.0;
   float KF0    = 0.0;
   float KF1    = 1.0;
> = 0.5;

int SetTechnique
<
   string Description = "Transition";
   string Enum = "Expand horizontal,Squeeze horizontal,Expand vertical,Squeeze vertical";
> = 0;

float Split
<
   string Description = "Split centre";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define EMPTY (0.0).xxxx

//-----------------------------------------------------------------------------------------//
// Functions
//-----------------------------------------------------------------------------------------//

float4 fn_tex2D (sampler Vsample, float2 uv)
{
   if ((uv.x < 0.0) || (uv.y < 0.0) || (uv.x > 1.0) || (uv.y > 1.0)) return EMPTY;

   float4 retval = tex2D (Vsample, uv);

   if (Boost == 0) {
      retval.a    = pow (retval.a, 0.5);
      retval.rgb /= retval.a;
   }

   return retval;
}

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_expand_H (float2 uv : TEXCOORD1) : COLOR
{
   float amount = Amount - 1.0;
   float negAmt = Amount * Split;
   float posAmt = 1.0 - (Amount * (1.0 - Split));

   float4 Fgd = (uv.x > posAmt) ? fn_tex2D (s_Super, float2 ((uv.x + amount) / Amount, uv.y))
              : (uv.x < negAmt) ? fn_tex2D (s_Super, float2 (uv.x / Amount, uv.y)) : EMPTY;

   return lerp (tex2D (s_Video, uv), Fgd, Fgd.a);
}

float4 ps_squeeze_H (float2 uv : TEXCOORD1) : COLOR
{
   float amount = 1.0 - Amount;
   float negAmt = amount * Split;
   float posAmt = 1.0 - (amount * (1.0 - Split));

   float4 Fgd = (uv.x > posAmt) ? fn_tex2D (s_Super, float2 ((uv.x - Amount) / amount, uv.y))
              : (uv.x < negAmt) ? fn_tex2D (s_Super, float2 (uv.x / amount, uv.y)) : EMPTY;

   return lerp (tex2D (s_Video, uv), Fgd, Fgd.a);
}

float4 ps_expand_V (float2 uv : TEXCOORD1) : COLOR
{
   float amount = Amount - 1.0;
   float negAmt = Amount * (1.0 - Split);
   float posAmt = 1.0 - (Amount * Split);

   float4 Fgd = (uv.y > posAmt) ? fn_tex2D (s_Super, float2 (uv.x, (uv.y + amount) / Amount))
              : (uv.y < negAmt) ? fn_tex2D (s_Super, float2 (uv.x, uv.y / Amount)) : EMPTY;

   return lerp (tex2D (s_Video, uv), Fgd, Fgd.a);
}

float4 ps_squeeze_V (float2 uv : TEXCOORD1) : COLOR
{
   float amount = 1.0 - Amount;
   float negAmt = amount * (1.0 - Split);
   float posAmt = 1.0 - (amount * Split);

   float4 Fgd = (uv.y > posAmt) ? fn_tex2D (s_Super, float2 (uv.x, (uv.y - Amount) / amount))
              : (uv.y < negAmt) ? fn_tex2D (s_Super, float2 (uv.x, uv.y / amount)) : EMPTY;

   return lerp (tex2D (s_Video, uv), Fgd, Fgd.a);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique Expand_H
{
   pass P_1
   { PixelShader = compile PROFILE ps_expand_H (); }
}

technique Squeeze_H
{
   pass P_1
   { PixelShader = compile PROFILE ps_squeeze_H (); }
}

technique Expand_V
{
   pass P_1
   { PixelShader = compile PROFILE ps_expand_V (); }
}

technique Squeeze_V
{
   pass P_1
   { PixelShader = compile PROFILE ps_squeeze_V (); }
}

