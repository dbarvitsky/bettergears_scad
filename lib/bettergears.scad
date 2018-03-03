function involute_gear_spec(
    circular_pitch = false,
    diametral_pitch = false,
    pitch_diameter = false,
    pressure_angle = 20,
    clearance = 0.0,
    round_gum = false
    ) = 
    [
        circular_pitch,
        diametral_pitch,
        pitch_diameter,
        pressure_angle,
        clearance,
        round_gum
    ]
;

function build_gear_with(
    number_of_teeth,
    spec = involute_gear_spec(diametral_pitch=3)
) = 
    number_of_teeth < 3 ? undef :
    build_gear(
        number_of_teeth,
        spec[0],
        spec[1],
        spec[2],
        spec[3],
        spec[4],
        spec[5]
    )
;
//
// Returns an array containing gear parameters used by other functions (refered 
// to as "gear" hereinafter.
// 
function build_gear(
    number_of_teeth,
    circular_pitch = false,
    diametral_pitch = false,
    pitch_diameter = false,
    pressure_angle = 20,
    clearance = 0.0,
    round_gum = false) =
    
    // Assertions:
    (
        circular_pitch == false && 
        diametral_pitch == false && 
        pitch_diameter == false ) ? undef :
    (number_of_teeth < 3) ? undef :
    (pressure_angle < 0 ) ? undef :
    
    // Pitch radius: 
    let (
        pitch_radius =
            pitch_diameter != false ? pitch_diameter / 2 :
            circular_pitch != false ? number_of_teeth * circular_pitch / 360 :
            diametral_pitch != false ? number_of_teeth / diametral_pitch / 2 :
            undef
    )
    
    // Base circle:
    let (base_radius = pitch_radius * cos(pressure_angle))
    let (pitch_diametrial = number_of_teeth / (pitch_radius * 2))
    
    // Addendum:
    let (addendum = 1/pitch_diametrial)
    
    //Outer circle:
	let(outer_radius = pitch_radius + addendum)
	
    // Dedendum:
    let(dedendum = addendum + clearance)
    
    // Root circle:
    let (root_radius = pitch_radius - dedendum)
    
    // Tooth half-thick angle:
    let (half_thick_angle = 360 / (4 * number_of_teeth))
    
    (
        root_radius > 0 &&
        root_radius < base_radius && 
        base_radius < pitch_radius &&
        pitch_radius < outer_radius &&
        half_thick_angle > 0
    ) ?
    
    let ( params =
    [
        /*0 */ number_of_teeth,
        /*1 */ clearance,
        
        /*2 */ root_radius,
        /*3 */ base_radius,
        /*4 */ pitch_radius,
        /*5 */ outer_radius,
        /*6 */ half_thick_angle,

        /*7 */ addendum,
        /*8 */ dedendum,
    ])
    
    let (tooth = involute_tooth_2d(params))
    let (tooth_and_gum = round_gum ? concat(tooth,__tooth_arc_gum(params)) : tooth)
    
    concat( 
        params, 
        /*9 */ [tooth],
        /*10 */ [tooth_and_gum]
    )
   : []
;

//
// Returns the number of teeth for a given gear
//
function gear_teeth(gear) = gear[0];

//
// Returns the pitch radius for a given gear
//            
function gear_pitch_radius(gear) = gear[4];

//
// Returns the tooth polygon already calculated for the gear.
//
function gear_tooth(gear) = gear[10];

//
// Returns a 2D polygon containing an involute tooth shape for the given gear.
//
function involute_tooth_2d(gear) =
    
    let (root_radius = gear[2])
    let (base_radius = gear[3])
    let (pitch_radius = gear[4])
    let (outer_radius = gear[5])
    let (half_thick_angle = gear[6])
    let (si = sin(half_thick_angle))
    let (co = cos(half_thick_angle))
    let (m1 = [
        [ co, si ],
        [ -si, co ]
    ])
    let (m2 = [
        [ co, si ],
        [ si, -co ]
    ])
    let (p0 = [co * root_radius, si*root_radius])
    let (p1 = [co * root_radius, -si*root_radius])
    let (curve = __involute_curve(base_radius, outer_radius))
    let (curve_r = __reverse(curve))
    let (c1 = [for (v=curve) __v_x_m_2d(v,m2)])
    let (c2 = [for (v=curve_r) __v_x_m_2d(v,m1)])
    concat(
        [p0],
        c1,
        c2,
        [p1]
    );
    
//
// Returns a polygon containing a segment of gear (or full gear if "n" is omitted).
//
            
function involute_gear_segment_2d(gear,n = false) =
    let (teeth = gear[0])
    let (tooth = gear[10])    
    let (lastTooth = n ? n-1 : gear[0]-1 )
    [
        for ( i = [0:1:lastTooth] )
            let (angle = i *360 / teeth)
            let (si = sin(angle))
            let (co = cos(angle))
            let (m = [
                    [co, si],
                    [-si, co]
                ])
            for (v=tooth) __v_x_m_2d(v,m)
     ]
;

//
// Calculates the angle of the pinion (driven) gear.
//
// Parameters:
// - driver - the driver gear
// - driver_angle - the own angle of the driver gear
// - pinion - the gear for wich the angle needs to be calculated
// - pinion_angle - the own angle of the pinion gear relative to the driver
//
// Returns: the own angle of the pinion gear
function pinion_angle(driver,driver_angle,pinion,pinion_angle) =
    let (teeth1=driver[0])
    let (teeth2=pinion[0])
    let (k=teeth1/teeth2)
    let (adj=teeth2 %2 == 0? 180/teeth2 : 0)
    let (g2_self_angle=(pinion_angle-driver_angle)*k+adj)
    g2_self_angle
;

module involute_gear_segment_3d(gear,n=false,height=1) {
    linear_extrude(height=height) polygon(involute_gear_segment_2d(gear,n));
}
            
//
// Internal functions below:
//
            
function __radial_step() = $fn > 0 ? $fn : $fs;
            
function __v_x_m_2d(v,m) =
    [   
        v[0]*m[0][0]+v[1]*m[0][1],
        v[0]*m[1][0]+v[1]*m[1][1]
    ];

function __involute_t(base_radius, r) =
    let ( r0 = r / base_radius )
    2 * sqrt( r0*r0 - 1) / PI
;

function __involute_point(base_radius,t) = 
    let( s = PI*base_radius*t / 2)
    let( si = sin(t*90))
    let( co = cos(t*90))
    let( c = [base_radius*co,base_radius*si])
    [c[0]+s*si,c[1]-s*co]
;

function __involute_curve(
    base_radius, outer_radius, r=base_radius, limit=outer_radius ) =
    
    r > limit ? [] :
    let (delta = (outer_radius-base_radius)/__radial_step())
    let (t = __involute_t(base_radius,r))
    let (p = __involute_point(base_radius,t))
    r == limit ? [p] :
    concat(
        [p],
        __involute_curve(
            base_radius,
            outer_radius,
            r + delta >= limit ? limit : r+delta
        )
    ) 
;

function __tooth_arc_gum(gear) =
    let (root_radius = gear[2])
    let (angle = 360 / gear[0])
    [for ( i = [gear[6]:$fa:angle-gear[6]]) 
        [ root_radius*cos(i), root_radius*sin(-i) ]]
;

function __reverse(vector,i=0) = 
    (vector[i] == undef) ? [] : concat(__reverse(vector,i+1),[vector[i]])
;        
    
