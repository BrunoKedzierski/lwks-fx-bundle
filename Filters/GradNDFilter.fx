// @Maintainer jwrl
// @Released 2018-12-04
// @Author khaver
// @Created 2014-07-10
// @see https://www.lwks.com/media/kunena/attachments/6375/GradNDFilter_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect GradNDFilter.fx
//
// Original effect by khaver, this is a neutral density filter which can be tinted,
// and its blend modes can be adjusted.  Select vertical or horizontal, flip the
// gradient, adjust strength and use the on-screen handles to move where the gradient
// starts and ends.
//
// Cross platform compatibility check 1 August 2017 jwrl.
// Explicitly defined samplers to fix cross platform default sampler state differences.
// Fully defined float3 variables and constants to address behavioural differences
// between the D3D and Cg compilers.
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 4 December 2018 jwrl.
// Added creation date.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Graduated ND Filter";
   string Category    = "Stylize";
   string SubCategory = "User Effects";
> = 0;

//-----------------------------------------------------------------------------------------//
// Input and sampler
//-----------------------------------------------------------------------------------------//

texture Input;

sampler InputSampler = sampler_state
{
   Texture   = <Input>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

int Direction
<
        string Description = "Direction";
        string Enum = "Vertical,Horizontal";
> = 0;

bool Flip
<
	string Description = "Flip";
> = false;

int Mode
<
        string Description = "Blend mode";
        string Enum = "Add,Subtract,Multiply,Screen,Overlay,Soft Light,Hard Light,Exclusion,Lighten,Darken,Difference,Burn";
> = 2;

float4 Tint
<
	string Description = "Tint";
> = { 0.0, 0.0, 0.0, 1.0 };

float Mixit
<
	string Description = "Strength";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float SX
<
   string Description = "Start";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.25;

float SY
<
   string Description = "Start";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.75;

float EX
<
   string Description = "End";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.75;

float EY
<
   string Description = "End";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.25;


#pragma warning ( disable : 3571 )

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 main1( float2 uv : TEXCOORD1 ) : COLOR
{
   float top =1.0;
   float v1 = 1.0-SY;
   float v2 = 1.0-EY;
   float bottom = 0.0;
   float left = 0.0;
   float h1 = SX;
   float h2 = EX;
   float right = 1.0;
   float4 orig = tex2D(InputSampler,uv);
   float3 newc, fg, bg;
   bg = orig.rgb;
   fg = Tint.rgb;
   if (Mode == 0) newc = saturate(bg + fg);	//Add

   if (Mode == 1) newc = saturate(bg - fg);	//Subtract

   if (Mode == 2) newc = bg * fg;		//Multiply

   if (Mode == 3) newc = 1.0.xxx - ((1.0.xxx - fg) * (1.0 - bg));	//Screen

   if (Mode == 4) {						//Overlay
	if (bg.r < 0.5) newc.r = 2.0 * fg.r * bg.r;
	else newc.r = 1.0 - (2.0 * ( 1.0 - fg.r) * ( 1.0 - bg.r));
	
	if (bg.g < 0.5) newc.g = 2.0 * fg.g * bg.g;
	else newc.g = 1.0 - (2.0 * ( 1.0 - fg.g) * ( 1.0 - bg.g));
	
	if (bg.b < 0.5) newc.b = 2.0 * fg.b * bg.b;
	else newc.b = 1.0 - (2.0 * ( 1.0 - fg.b) * ( 1.0 - bg.b));
  }

   if (Mode == 5) newc = ( 1.0.xxx - bg) * (fg * bg) + (bg * (1.0.xxx - ((1.0.xxx - bg) * (1.0.xxx - fg)))); //Soft Light

   if (Mode == 6) { 									//Hard Light
	if (fg.r < 0.5 ) newc.r = 2.0 * fg.r * bg.r;
	else newc.r = 1.0 - ( 2.0 * (1.0 - fg.r) * (1.0 - bg.r));
	
	if (fg.g < 0.5 ) newc.g = 2.0 * fg.g* bg.g;
	else newc.g = 1.0 - ( 2.0 * (1.0 - fg.g) * (1.0 - bg.g));
	
	if (fg.b < 0.5 ) newc.b = 2.0 * fg.b * bg.b;
	else newc.b = 1.0 - ( 2.0 * (1.0 - fg.b) * (1.0 - bg.b));
   }

   if (Mode == 7) newc = fg + bg - (2.0 * fg * bg);	//Exclusion

   if (Mode == 8) newc = max(fg, bg);	//Lighten

   if (Mode == 9) newc = min(fg, bg);	//Darken

   if (Mode == 10) newc = abs( fg - bg);		//Difference

   if (Mode == 11) newc = saturate(1.0.xxx - (( 1.0.xxx - fg) / bg));	//Burn

   float3 outc;
   float deltv = abs(EY - SY);
   float delth = abs(EX - SX);
   if (Flip) {
   if (Direction == 0) {
	if (uv.y < v1)  outc = bg;
	if (uv.y >= v1 && uv.y <= v2) outc = lerp(newc, bg, (v2 - uv.y) / deltv);
	if (uv.y > v2) outc = newc;
   }
   if (Direction == 1) {
	if (uv.x < h1)  outc = bg;
	if (uv.x >= h1 && uv.x <= h2) outc = lerp(bg, newc, (uv.x - h1) / delth);
	if (uv.x > h2) outc = newc;
   }
   }
  else {
   if (Direction == 0) {
	if (uv.y < v1)  outc = newc;
	if (uv.y >= v1 && uv.y <= v2) outc = lerp(bg, newc, (v2 - uv.y) / deltv);
	if (uv.y > v2) outc = bg;
   }
   if (Direction == 1) {
	if (uv.x < h1)  outc = newc;
	if (uv.x >= h1 && uv.x <= h2) outc = lerp(newc, bg, (uv.x - h1) / delth);
	if (uv.x > h2) outc = bg;
   }
   }
   return lerp(orig, float4(outc, orig.a), Mixit);
	
}

//-----------------------------------------------------------------------------------------//
// Technique
//-----------------------------------------------------------------------------------------//

technique GradNDFilter
{
   pass Pass1
   {
      PixelShader = compile PROFILE main1();
   }
}
