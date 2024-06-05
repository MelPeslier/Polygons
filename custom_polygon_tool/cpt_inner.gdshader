shader_type canvas_item;


uniform float p_c_d : hint_range(0.0, 1.0, 0.5) = 0.5;
// __________ TODO ___ Use #if to reduce performance costs and not calculating other parts than the actual one ?
uniform float is_elements_from_backbuffer_setup : hint_range(0.0, 1.0, 1.0) = 1.0;

uniform float use_sdf : hint_range(0.0, 1.0, 1.0) = 1.0;
uniform float sdf_aim : hint_range(0.0, 1000.0, 0.1) = 500.0;
uniform vec3 outer_line_color : source_color;


group_uniforms prototype;
uniform float p_tex_tiling = 1.0;
uniform vec2 p_tex_size = vec2(128.0);


group_uniforms custom_main;
uniform float c_tex_tiling = 1.0;
uniform vec2 c_tex_size = vec2(128.0);
uniform sampler2D c_main_sampler : hint_default_black, repeat_enable;
uniform sampler2D c_secondary_sampler : hint_default_black, repeat_enable;
uniform sampler2D c_mix_main_secondary_sampler : hint_default_black, repeat_enable; // Mixing the textures together depending on the texture (usually a noise)
uniform vec4 c_main_splats_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform sampler2D c_mix_main_splats_sampler : hint_default_black, repeat_enable; // To mix some shadows splats or else to the texture
// Using noises and for the intensity of the color applied, just tweak the noise color ramp




//group_uniforms debug;


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
	//float inside_sdf_mask = step(sdf_value, 0.0) ; 
	float inner_sdf = -sdf_value * sdf_aim / 10000.0 ; //* inside_sdf_mask;

// *** PROTOTYPE ***
	vec2 p_tex_uv = p_tex_tiling / p_tex_size; // Define the uv size and stretch
	vec2 p_world_uv = p_tex_uv * world_pos; // Apply size to world position to get world_uv
	vec4 p_main_tex = texture(c_main_sampler, p_world_uv);
	// ... TODO ! _____ Simple texture ans borders ? and shadow lines ? _____________ TODO _____________
	//vec2 d_uv = vec2( mod(world_uv.r, 1.0), mod(world_uv.g, 1.0) ); // UV to make tiles of 1
	vec4 p_final_tex = p_main_tex ;
// *** _____ ***


// *** CUSTOM ***
	vec2 c_tex_uv = c_tex_tiling / c_tex_size; // Define the uv size and stretch
	vec2 c_world_uv = c_tex_uv * world_pos; // Apply size to world position to get world_uv
	vec4 c_original_tex = texture(TEXTURE, UV);
	vec4 c_final_tex = vec4( vec3(0.0), c_original_tex.a);


// * Main texture *
	vec4 c_main_tex = texture(c_main_sampler, c_world_uv);

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
	float bb_pct = mix(1.0, bb_is_black * back_buffer_tex.a, is_elements_from_backbuffer_setup);
	c_main_tex = mix(back_buffer_tex, c_main_tex, bb_pct );

	float c_sdf_pct = mix(1.0, min(inner_sdf, 1.0), use_sdf);
	c_final_tex.rgb = mix(outer_line_color, c_main_tex.rgb, c_sdf_pct ); // Add result to the final texture output
// *** _____ ***


// *** DEBUG ***
	vec4 d_final_tex = texture(TEXTURE, UV);
// *** _____ ***


	// To switch from the different textures
	vec4 p_c = mix(p_final_tex, c_final_tex, step(0.25, p_c_d) ); // choose between prototype and custom
	vec4 final_tex = mix(p_c, d_final_tex, step(0.75, p_c_d) ); // choose between 2 previous result and debug
	COLOR = final_tex;
}


