include <MCAD\gears.scad>;
$fn=60;


function gear_params(number_of_teeth,
		circular_pitch=false, diametral_pitch=false,
		pressure_angle=20, clearance = 0.0) =

	//Convert diametrial pitch to our native circular pitch
	let(circular_pitch = (circular_pitch!=false?circular_pitch:180/diametral_pitch))
    // Pitch diameter: Diameter of pitch circle.
    let(pitch_diameter  =  number_of_teeth * circular_pitch / 180)
	let(pitch_radius = pitch_diameter/2)

	// Base Circle
	let(base_diameter = pitch_diameter*cos(pressure_angle))
	let(base_radius = base_diameter/2)

	// Diametrial pitch: Number of teeth per unit length.
	let(pitch_diametrial = number_of_teeth / pitch_diameter)

	// Addendum: Radial distance from pitch circle to outside circle.
	let(addendum = 1/pitch_diametrial)

	//Outer Circle
	let(outer_radius = pitch_radius+addendum)
	let(outer_diameter = outer_radius*2)

	// Dedendum: Radial distance from pitch circle to root diameter
	let(dedendum = addendum + clearance)

	// Root diameter: Diameter of bottom of tooth spaces.
	let (root_radius = pitch_radius-dedendum)
	let (root_diameter = root_radius * 2)

	let (half_thick_angle = 360 / (4 * number_of_teeth))
    
    [
        /*0*/ pitch_radius,
        /*1*/ base_radius,
        /*2*/ outer_radius,
        /*3*/ root_radius,
        /*4*/ addendum,
        /*5*/ dedendum,
        /*6*/ half_thick_angle,
        /*7*/ number_of_teeth
    ];

function mul2d(a,m) = 
    [   
        a[0]*m[0][0]+a[1]*m[0][1],
        a[0]*m[1][0]+a[1]*m[1][1]
    ];
    
function mul2dSeq(seq,m) = [for (c=seq) mul2d(c,m)];

function involute_point(base_radius,t) = 
    let( s = PI*base_radius*t / 2)
    let( si = sin(t*90))
    let( co = cos(t*90))
    let( c = [base_radius*co,base_radius*si])
    [c[0]+s*si,c[1]-s*co]
;

function involute_t(base_radius, r) =
    let ( r0 = r / base_radius )
    2 * sqrt( r0*r0 - 1) / PI
;

function involute_curve(base_radius,outer_radius,r=base_radius) =
    let (t = involute_t(base_radius,r))
    let (p = involute_point(base_radius,t))
    ( r <= outer_radius) 
        ? 
            concat(
                involute_curve(
                    base_radius,
                    outer_radius,
                    r+1/$fn
                ),
                [p]
            ) 
        : [];

function reverse(a,i=0) =
    (a[i] == undef) ? []
        : concat(reverse(a,i+1),[a[i]]);

    
module involute_gear_tooth_(
					pitch_radius,
					root_radius,
					base_radius,
					outer_radius,
					half_thick_angle
					)
{
    si = sin(half_thick_angle);
    co = cos(half_thick_angle);
    si2 = sin(half_thick_angle*0.2);
    co2 = cos(half_thick_angle*0.2);

    m1 = [[ co,   si ],
          [-si,   co ]];
    m2 = [[ co,   si ],
          [ si,   -co ]];
    
    p0 = [co*root_radius,-si*root_radius];
    p1 = [co*base_radius,-si*base_radius];
    p2 = [co2*outer_radius,-si2*outer_radius];
    p3 = [co2*outer_radius,si2*outer_radius];
    p4 = [co*base_radius,si*base_radius];
    p5 = [co*root_radius,si*root_radius];

    c = involute_curve(base_radius,outer_radius);
    
    c2 = mul2dSeq(c,m2);
    c1 = concat([p5],reverse(mul2dSeq(c,m2)),/*[p3,p2],*/mul2dSeq(c,m1),[p0]);
    polygon(c1);
    echo(c1);

}

module ring(r,h=1,w=0.05){
    difference() {
        cylinder(h=h,r=r+w);
        translate([0,0,-0.1]) cylinder(h=h+0.2,r=r);
    }

}

module gear_p(params) {
    n = params[7];
    cylinder(r=params[3],h=1);
    //ring(params[0]);
    //ring(params[2]);
    for (i = [0:1:n])
        rotate([0,0,i*360/n])
    linear_extrude(height=1) {
        involute_gear_tooth_(
            pitch_radius=params[0],
            root_radius=params[3],
            base_radius=params[1],
            outer_radius=params[2],
            half_thick_angle=params[6]
        );
    }
}

g = gear_params(number_of_teeth=10,diametral_pitch=3, pressure_angle=14.5,clearance=0); 
echo(g);

   angle=-360*$t-180/10;
   angle2=360*$t;
    rotate([0,0,angle]) gear_p(g);
   translate([g[0]*2,0,0]) rotate([0,0,angle2]) gear_p(g);


/*
    involute_gear_tooth(
        pitch_radius=.625,
        root_radius=.5527,
        base_radius=.605,
        outer_radius=.6875,
        half_thick_angle=4.50
    );
*/
