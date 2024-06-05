shader_type canvas_item;

uniform float p_c_f_d : hint_range(0.0, 1.0, 0.33) = 0.5;
uniform float uv_local_global : hint_range(0.0, 1.0, 1.0) = 1.0; 

group_uniforms prototype;
uniform float p_use_sdf : hint_range(0.0, 1.0, 1.0) = 1.0;
uniform float p_sdf_aim : hint_range(0.0, 1000.0, 0.1) = 500.0;
uniform float p_tex_tiling = 1.0;
uniform vec2 p_tex_size = vec2(128.0);
uniform vec3 p_sdf_color : source_color;
uniform sampler2D p_main_sample : hint_default_black, repeat_enable;



group_uniforms custom_main;
uniform float c_use_back_buffer : hint_range(0.0, 1.0, 1.0) = 1.0;
uniform float c_use_sdf : hint_range(0.0, 1.0, 1.0) = 1.0;
uniform float c_sdf_aim : hint_range(0.0, 1000.0, 0.1) = 500.0;
uniform vec3 c_sdf_color : source_color;
uniform float c_tex_tiling = 1.0;
uniform vec2 c_tex_size = vec2(128.0);
uniform sampler2D c_main_sampler : hint_default_black, repeat_enable;
uniform sampler2D c_secondary_sampler : hint_default_black, repeat_enable;
uniform sampler2D c_mix_main_secondary_sampler : hint_default_black, repeat_enable; // Mixing the textures together depending on the texture (usually a noise)
uniform vec4 c_main_splats_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform sampler2D c_mix_main_splats_sampler : hint_default_black, repeat_enable; // To mix some shadows splats or else to the texture
// Using noises and for the intensity of the color applied, just tweak the noise color ramp


group_uniforms fractal;
uniform float f_sdf_aim : hint_range(0.0, 1000.0, 0.1) = 300.0;
uniform sampler2D f_color_sample : hint_default_black;


group_uniforms debug;


group_uniforms BackBuffer;
uniform sampler2D back_buffer_s : hint_screen_texture;


varying vec2 world_pos; // Keep the variable for the fragment shader


void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy; // Get world position
}


void fragment() {
	
	// * Get SDF from occluders *
	vec2 sdf_pos = screen_uv_to_sdf(SCREEN_UV);
	float sdf_value = texture_sdf(sdf_pos);
	
	
	vec4 original_tex = texture(TEXTURE, UV);

// *** PROTOTYPE ***
	vec2 p_tex_uv = p_tex_tiling / p_tex_size;
	vec2 p_world_uv = p_tex_uv * world_pos;
	vec2 p_uv = mix(UV, p_world_uv, uv_local_global);
	
	vec4 p_main_tex = texture(p_main_sample, p_uv);
	
	vec4 p_final_tex = vec4( vec3(0.0), original_tex.a) ;
	
	float p_inner_sdf = -sdf_value * p_sdf_aim / 10000.0 ;
	float p_sdf_pct = mix(1.0, min(p_inner_sdf, 1.0), p_use_sdf);
	p_final_tex.rgb = mix(p_sdf_color, p_main_tex.rgb, p_sdf_pct ); 
	
// *** _____ ***


// *** CUSTOM ***
	vec2 c_tex_uv = c_tex_tiling / c_tex_size;
	vec2 c_world_uv = c_tex_uv * world_pos;
	vec2 c_uv = mix(UV, c_world_uv, uv_local_global);
	vec4 c_final_tex = vec4( vec3(0.0), original_tex.a);


// * Main texture *
	vec4 c_main_tex = texture(c_main_sampler, c_uv);

	// _____ TODO _____ make the uv  being different , no same shit texture  all the time, ad variations, in intensity and  positionning
	// _ Then add secondary texture
	vec4 c_secondary_tex = texture(c_secondary_sampler, c_world_uv);
	float c_mix_tex_coef = texture(c_mix_main_secondary_sampler, c_world_uv).r;
	c_main_tex = mix(c_main_tex, c_secondary_tex, c_mix_tex_coef);

	// _ Then add color splats
	float c_mix_main_color_splats = texture(c_mix_main_splats_sampler, c_world_uv).r;
	c_main_tex.rgb = mix(c_main_tex.rgb, c_main_splats_color.rgb, c_mix_main_color_splats);

	// * Mix outer elements from back buffer *
	// TODO ______________ Add variations ? like a noise and it makes it smoothly mix or not
	vec4 back_buffer_tex = texture(back_buffer_s, SCREEN_UV);
	float bb_is_black = step(back_buffer_tex.r, 0.0) * step(back_buffer_tex.g, 0.0) * step(back_buffer_tex.b, 0.0);
	float bb_pct = mix(1.0, bb_is_black * back_buffer_tex.a, c_use_back_buffer);
	c_main_tex = mix(back_buffer_tex, c_main_tex, bb_pct );
	
	float c_inner_sdf = -sdf_value * c_sdf_aim / 10000.0 ;
	float c_sdf_pct = mix(1.0, min(c_inner_sdf, 1.0), c_use_sdf);
	c_final_tex.rgb = mix(c_sdf_color, c_main_tex.rgb, c_sdf_pct ); // Add result to the final texture output
// *** _____ ***


// *** FRACTAL ***
	float f_inner_sdf = -sdf_value * f_sdf_aim / 10000.0 ;
	float f_fract = fract( f_inner_sdf );
	vec4 f_final_tex = texture(f_color_sample, vec2(f_fract, 0.0) ) ;
// *** _____ ***


// *** DEBUG ***
	vec4 d_final_tex = texture(TEXTURE, UV);
// *** _____ ***


	// To switch from the different textures
	vec4 p_c = mix(p_final_tex, c_final_tex, step(0.125, p_c_f_d) );
	vec4 p_c_f = mix(p_c, f_final_tex, step(0.425, p_c_f_d) );
	vec4 final_tex = mix(p_c_f, d_final_tex, step(0.825, p_c_f_d) );
	COLOR = final_tex;
}


