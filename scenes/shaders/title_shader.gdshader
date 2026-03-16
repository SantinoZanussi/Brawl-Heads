shader_type canvas_item;
uniform float glow_intensity : hint_range(0.0, 8.0) = 4.0;
uniform vec4 glow_color : source_color = vec4(1.0, 0.85, 0.0, 1.0);

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    vec4 tinted = vec4(glow_color.rgb * tex.rgb, tex.a);

    float glow_near = 0.0;
    float glow_mid  = 0.0;
    float glow_far  = 0.0;

    for (float x = -2.0; x <= 2.0; x++)
        for (float y = -2.0; y <= 2.0; y++)
            glow_near += texture(TEXTURE, UV + vec2(x,y) * TEXTURE_PIXEL_SIZE).a;

    for (float x = -5.0; x <= 5.0; x++)
        for (float y = -5.0; y <= 5.0; y++)
            glow_mid += texture(TEXTURE, UV + vec2(x,y) * TEXTURE_PIXEL_SIZE).a;

    for (float x = -10.0; x <= 10.0; x++)
        for (float y = -10.0; y <= 10.0; y++)
            glow_far += texture(TEXTURE, UV + vec2(x,y) * TEXTURE_PIXEL_SIZE).a;

    glow_near /= 25.0;
    glow_mid  /= 121.0;
    glow_far  /= 441.0;

    // Capas: núcleo brillante + halo medio + difusión lejana
    float glow = (glow_near * 0.5 + glow_mid * 0.35 + glow_far * 0.15) * glow_intensity;

    vec4 glow_result = glow_color * clamp(glow, 0.0, 1.0);

    COLOR = mix(glow_result, tinted, tex.a);
    COLOR.a = max(tex.a, glow * 0.95);
}