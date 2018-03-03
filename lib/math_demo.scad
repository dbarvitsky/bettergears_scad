use <bettergears.scad>;

$fs=10;

gear_spec = involute_gear_spec(diametral_pitch=3, pressure_angle=14.5);

g1 = build_gear_with(number_of_teeth = 13,spec=gear_spec);
g2 = build_gear_with(number_of_teeth = 9, spec=gear_spec);
g3 = build_gear_with(number_of_teeth = 16, spec=gear_spec);

g1_angle = 360*$t;
g2_orbit_angle = -720*$t;

rotate([0,0,g1_angle])
involute_gear_segment_3d(g1,height=0.5);

rotate([0,0,g2_orbit_angle])
translate([gear_pitch_radius(g1)+gear_pitch_radius(g2),0,0])
{
    g2_angle = pinion_angle(g1,g1_angle,g2,g2_orbit_angle);
    rotate([0,0,g2_angle])
    involute_gear_segment_3d(g2,height=0.5);

    g3_angle = pinion_angle(g2,g2_angle,g3,60);
    
    rotate([0,0,60])
    translate([gear_pitch_radius(g2)+gear_pitch_radius(g3),0,0])
    rotate([0,0,g3_angle])
    involute_gear_segment_3d(g3,height=0.5);
    
}
