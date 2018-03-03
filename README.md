# Yet another library for generating involute gears for OpenSCAD

This is yet another attempt to improve [OpenScad](http://www.openscad.org/) library for [involute gears](https://en.wikipedia.org/wiki/Gear).

The library is written from scratch using some optimization and object-oriented (for as much as this can be applied to OpenSCAD language) design in mind.
 
The key concepts are:
* `gear spec` (created by `involute_gear_spec`) is an "object" that defines how the gear would be generated. Normally you want to create a spec once and then generate gears with it just varying the number of teeth. The spec includes things like pressure angle, diametral pitch, clearance, etc.
 
* `gear` (created by `build_gear_with` and `build_gear`) is an "object" that contains calculated parameters for the gear, as well as polygons for the tooth and gum. You pass it to other functions to generate full gears, gear segments, etc.

There are some utility functions, such as `pinion_angle` which help with aligining and animating the gears.

See [./lib/math_demo.scad](demo) for examples (turn on animation).

# Synopsis
```
use <bettergears.scad>;

// Reasonably smooth surfaces
$fs=10;

// Create the gear spec:
gear_spec = involute_gear_spec(diametral_pitch=3, pressure_angle=14.5);

// Create some gears:
g1 = build_gear_with(number_of_teeth = 13,spec=gear_spec);
g2 = build_gear_with(number_of_teeth = 7,spec=gear_spec);

// Why not have some animation? (View->Animate, FPS=5, Steps=360)
g1_angle = 360*$t;

// Generate first (driver) gear:
rotate([0,0,g1_angle])
involute_gear_segment_3d(g1,height=0.5);

// Generate second (pinion) gear and rotate it to align 
// with driver:
g2_angle = pinion_angle(g1,g1_angle,g2,30);
rotate([0,0,30])
translate([gear_pitch_radius(g1)+gear_pitch_radius(g2),0,0]) {
   rotate([0,0,g2_angle])
   involute_gear_segment_3d(g2,height=0.5);
}
```

# Acknowledgements

This library has been inspired by the works of:
* [GregFrost](http://www.thingiverse.com/thing:3575)
* D1plo1d (originally came with OpenScad)
* [Nicholas Carter](http://www.cartertools.com/involute.html)
* [Kohara Gears Industry](http://khkgears.net/new/gear_knowledge/gear_technical_reference/involute_gear_profile.html)
* [Prof. Meung J. Kim](http://www.ceet.niu.edu/faculty/kim/mee430/documents/Involute%20Gear.html)
