shader_type canvas_item;

// Bu değeri koddan (GDScript) güncelleyeceğiz
uniform float current_distance = 100.0; 

// Bir tirenin dünyadaki sabit uzunluğu (Örn: 20 piksel)
uniform float dash_width = 20.0; 
uniform float dash_ratio : hint_range(0.0, 1.0) = 0.5;
uniform vec4 line_color : source_color = vec4(1.0);

void fragment() {
    // Stretch modu UV.x'i 0-1 arasına hapseder.
    // Biz bunu mesafe ile çarparak tekrar "dünya piksellerine" çeviriyoruz.
    float world_x = UV.x * current_distance;
    
    // Dünyadaki piksel pozisyonuna göre mod alıyoruz (Sabit boyda kalır)
    float pattern = fract(world_x / (dash_width / dash_ratio));
    
    float alpha = step(pattern, dash_ratio);
    
    COLOR = line_color;
    COLOR.a *= alpha;
}