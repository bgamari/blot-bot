use <MCAD/involute_gears.scad>;
include <MCAD/constants.scad>;

wheel_height = 8;
wheel_dia = 350;
wheel_pieces = 8;

beaker_recess = 5;
beaker_offset = 124;
beaker_dia = 60;
n_beakers = 8;

roller_r = 124;
roller_recess = 3;
n_arms = 4;
arm_width = 10;

// 608 bearing
bearing_width = 7;
bearing_outer_dia = 22;
bearing_inner_dia = 8;

m3_nut_minor_dia = 5.5;
m3_nut_thickness = 2.5;

gear_pitch = 400;

module bearing_holder() {
    translate([0, 0, bearing_outer_dia/2])
    difference() {
        cube([2*bearing_outer_dia, 4*bearing_width, bearing_outer_dia], center=true);
        translate([0, 0, 0.2*bearing_outer_dia]) {
            rotate([90,0,0]) cylinder(r=bearing_inner_dia/2, h=3*bearing_width, center=true);
            cube([1.2*bearing_outer_dia, 1.1*bearing_width, 1.1*bearing_outer_dia], center=true);
            translate([0,0,50/2]) cube([bearing_inner_dia, 3*bearing_width, 50], center=true);
        }
    }
}
    
module base() {
    module arm() {
        translate([-arm_width/2, 0, 0]) {
            cube([arm_width, roller_r-4*bearing_width/2, bearing_outer_dia]);
            translate([0, roller_r+4*bearing_width/2, 0])
            difference() {
                cube([arm_width, 80, bearing_outer_dia]);
                translate([-arm_width/2, 10, bearing_outer_dia/2])
                cube([2*arm_width, 80-20, 4.5]);
            }
        }

        translate([0, roller_r, 0])
        bearing_holder();
    }

    cylinder(r=bearing_inner_dia/2-0.1, h=50);

    for (theta=[0:360/n_arms:360])
    rotate([0,0,theta])
    arm();
}

module bearing_pin() {
    cylinder(r=0.97*bearing_inner_dia/2, h=2.9*bearing_width);
}

module dovetail(fudge=0) {
    a = 5 + fudge;
    b = 15 + fudge;
    c = 15;
    polygon([[-a,0], [-b,c], [b,c], [a,0]]);
}

module regular_polygon(n, min_r) {
    for (theta = [0:360/n:360])
    rotate(theta)
    square([min_r, min_r/tan(360/n)], center=true);
}

module wheel_center() {
    size = 89;

    difference() {
        linear_extrude(height=wheel_height)
        regular_polygon(6, size);

        // Bearing
        cylinder(r=bearing_outer_dia/2, h=2*bearing_width, center=true);
        cylinder(r=8/2, h=3*wheel_height);

        // Dovetails
        rotate(360/12)
        for (theta = [0:360/6:360])
        rotate(theta)
        translate([0,-45,-wheel_height])
        linear_extrude(height=3*wheel_height)
        dovetail(0.3);
    }
}

module wheel_sector() {
    holder_r = 1.2*beaker_dia / 2;

    difference() {
        linear_extrude(height=wheel_height) {
            rotate(90) dovetail();
            difference() {
                translate([0.3*holder_r,0])
                rotate(45)
                square([holder_r, holder_r], center=true);

                translate([-holder_r/2, 0])
                square([holder_r, holder_r], center=true);
            }

            translate([holder_r, 0])
            circle(r=holder_r);
        }
        translate([0,0,5])
        translate([holder_r, 0, 0])
        cylinder(r=beaker_dia/2, h=wheel_height, center=true);
    }
}

module annulus(r, dr) {
    difference() {
        circle(r=r+dr/2);
        circle(r=r-dr/2);
    }
}
    
module wheel_sectors() {
    for (theta = [0:360/6:360])
    rotate([0,0,theta])
    translate([45,0,0])
    wheel_sector();

    difference() {
        difference() {
            render()
            gear(circular_pitch=gear_pitch, number_of_teeth=120,
                gear_thickness=wheel_height, involute_facets=1, $fn=2);

            cylinder(r=115, h=3*wheel_height, center=true);
        }

        difference() {
            translate([0,0,-roller_recess])
            linear_extrude(height=2*roller_recess)
            annulus(roller_r, 1.5*bearing_width);
        }
    }
}

module wheel_assembly() {
    wheel_center();
    wheel_sectors();
}

// Stepper motor gear
module motor_gear() {
    difference() {
        gear(circular_pitch=gear_pitch, number_of_teeth=20,
            gear_thickness=wheel_height, rim_thickness=wheel_height,
            hub_thickness=20, hub_diameter=20, bore_diameter=5.5);

        translate([4, 0, 10 + 5 - m3_nut_minor_dia/2])
        translate([0, 0, 20/2])
        cube([m3_nut_thickness, m3_nut_minor_dia, 20], center=true);

        translate([0, 0, 10 + 5])
        rotate([0, 90, 0]) cylinder(r=3.3/2, h=30);
    }
}

// Assembly diagram
module assembly() {
    base();

    translate([0, 0, 30]) wheel_assembly();

    rotate([0,0,-30])
    translate([180, -30, 0]) motor_mount();
}

// Print plate
module print_plate() {
    base();

    for (i=[0:n_arms])
    translate([100+3*bearing_inner_dia*i,0,0])
    bearing_pin();

    translate([-80, 0, 0])
    motor_gear();
}

module wheel_sectors_print(i) {
    wheel_pieces = 6;
    fudge = 0.5; // degrees
    difference() {
        intersection() {
            rotate([0,0,(i+1/2)*360/wheel_pieces]) wheel_sectors();

            linear_extrude(h=1000)
            polygon([[0,0],
                     [1000, 0],
                     [1000*cos(360/wheel_pieces-fudge), 1000*sin(360/wheel_pieces-fudge)]
                    ]);
        }

        // Tick marks
        for (j = [1:i+1])
        translate([0.73*wheel_dia*cos(2*j)/2, 0.73*wheel_dia*sin(2*j)/2, wheel_height])
        cylinder(h=2, r=1, center=true);
    }
}

// Stepper motor mount
module motor_mount() {
    size = 120;
    mount_height = 100;
    wall_thickness = 2;
    translate([0,0,mount_height/2])
    difference() {
        cube([size, size, mount_height], center=true);

        translate([-wall_thickness*2, -wall_thickness*2, -wall_thickness*2])
        cube([size-wall_thickness, size-wall_thickness, mount_height-wall_thickness],
            center=true);

        rotate([0,0,45])
        translate([-size/4, 0, 0])
        cube([size, 3*size, size/5], center=true);

        // Motor shaft hole
        cylinder(r=23/2, h=2*mount_height);

        // Motor screw holes
        translate([0,0,mount_height/2])
        for (theta = [45:90:360])
        rotate([0, 0, theta])
        translate([1.725*mm_per_inch, 0, 0])
        cylinder(r=0.1968*mm_per_inch, h=50, center=true);

        rotate([0,0,45])
        translate([-65, 0, mount_height/2])
        cube([100, 200, 22], center=true);


        translate([0,0,bearing_outer_dia/2 - mount_height/2]) {
            translate([0,size/2,0]) cube([0.8*size, 10*wall_thickness, 4], center=true);
            translate([size/2,0,0]) cube([10*wall_thickness, 0.8*size, 4], center=true);
        }
    }
    motor_gear();
}

//print_plate();
wheel_sectors_print(1);
//wheel_center();

//assembly();
//motor_mount();

//wheel_center();
