shader_type canvas_item;
uniform float glow_intensity : hint_range(0.0, 5.0) = 2.0;
uniform vec4 glow_color : source_color = vec4(1.0, 0.85, 0.0, 1.0);

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    
    // Pulso animado
    float pulse = sin(TIME * 3.0) * 0.3 + 0.7;
    
    float is_text = tex.a;
    vec4 tinted = vec4(glow_color.rgb, tex.a);
    
    float glow = 0.0;
    for (float x = -4.0; x <= 4.0; x++)
        for (float y = -4.0; y <= 4.0; y++)
            glow += texture(TEXTURE, UV + vec2(x,y) * TEXTURE_PIXEL_SIZE).a;
    glow /= 81.0;
    glow *= glow_intensity * is_text * pulse; // <-- pulso acá
    
    if (tex.a < 0.1) {
        COLOR = tex;
    } else {
        COLOR = mix(glow_color * glow, tinted, tex.a);
    }
}