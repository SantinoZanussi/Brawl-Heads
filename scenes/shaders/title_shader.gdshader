shader_type canvas_item;
render_mode unshaded;

uniform vec4 glow_color : source_color = vec4(1.0, 0.84, 0.0, 1.0);
uniform float glow_size : hint_range(0.0, 20.0) = 12.0;
uniform float glow_strength : hint_range(0.0, 3.0) = 1.5;
uniform float threshold : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec4 modulate = COLOR;
    vec4 original = texture(TEXTURE, UV, 0.0) * modulate;
    
    float glow = 0.0;
    vec2 ps = TEXTURE_PIXEL_SIZE;
    
    for (float x = -glow_size; x <= glow_size; x++) {
        for (float y = -glow_size; y <= glow_size; y++) {
            float dist = length(vec2(x, y));
            if (dist <= glow_size) {
                float a = texture(TEXTURE, UV + vec2(x, y) * ps, 0.0).a;
                // Solo cuenta píxeles completamente opacos
                float solid = step(threshold, a);
                glow += solid * (1.0 - dist / glow_size);
            }
        }
    }
    
    glow = clamp(glow * glow_strength / (glow_size * glow_size * 0.5), 0.0, 1.0);
    
    float is_solid = step(threshold, original.a);
    float halo = glow * (1.0 - is_solid);
    
    vec3 lit_text = original.rgb + glow_color.rgb * glow * 0.8;
    
    COLOR.rgb = mix(glow_color.rgb * halo, lit_text, is_solid);
    COLOR.a = max(is_solid, halo * glow_color.a);
}
//shader_type canvas_item;
//uniform float glow_intensity : hint_range(0.0, 8.0) = 4.0;
//uniform vec4 glow_color : source_color = vec4(1.0, 0.85, 0.0, 1.0);
//
//void fragment() {
    //vec4 tex = texture(TEXTURE, UV);
    //vec4 tinted = vec4(glow_color.rgb * tex.rgb, tex.a);
//
    //float glow_near = 0.0;
    //float glow_mid  = 0.0;
    //float glow_far  = 0.0;
//
    //for (float x = -2.0; x <= 2.0; x++)
        //for (float y = -2.0; y <= 2.0; y++)
            //glow_near += texture(TEXTURE, UV + vec2(x,y) * TEXTURE_PIXEL_SIZE).a;
//
    //for (float x = -5.0; x <= 5.0; x++)
        //for (float y = -5.0; y <= 5.0; y++)
            //glow_mid += texture(TEXTURE, UV + vec2(x,y) * TEXTURE_PIXEL_SIZE).a;
//
    //for (float x = -10.0; x <= 10.0; x++)
        //for (float y = -10.0; y <= 10.0; y++)
            //glow_far += texture(TEXTURE, UV + vec2(x,y) * TEXTURE_PIXEL_SIZE).a;
//
    //glow_near /= 25.0;
    //glow_mid  /= 121.0;
    //glow_far  /= 441.0;
//
    //// Capas: núcleo brillante + halo medio + difusión lejana
    //float glow = (glow_near * 0.5 + glow_mid * 0.35 + glow_far * 0.15) * glow_intensity;
//
    //vec4 glow_result = glow_color * clamp(glow, 0.0, 1.0);
//
    //COLOR = mix(glow_result, tinted, tex.a);
    //COLOR.a = max(tex.a, glow * 0.95);
//}