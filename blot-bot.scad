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

center_r = 20;
arm_flange_width = 3*arm_width;
arm_flange_depth = 5;

module bearing_holder() {
    translate([0, 0, bearing_outer_dia/2])
    difference() {
        cube([2*bearing_outer_dia, 4*bearing_width, bearing_outer_dia], center=true);

        translate([0, 0, 0.2*bearing_outer_dia]) {
            rotate([90,0,0])
            cylinder(r=bearing_inner_dia/2, h=3*bearing_width, center=true);

            cube([1.2*bearing_outer_dia, 1.1*bearing_width, 1.1*bearing_outer_dia],
                 center=true);

            translate([0,0,50/2])
            cube([bearing_inner_dia, 3*bearing_width, 50], center=true);
        }
    }
}

module arm_flange_holes() {
    for (x = [-1,+1])
    for (z = [3:5:bearing_outer_dia])
    translate([x*0.85*arm_flange_width/2, 0, z])
    rotate([90, 0, 0])
    cylinder(r=3/2, h=100, center=true);
}

module base_arm() {
    translate([0, center_r, 0])
    difference() {
        translate([-arm_flange_width/2, 0, 0])
        cube([arm_flange_width, arm_flange_depth, bearing_outer_dia]);
        arm_flange_holes();
    }

    translate([-arm_width/2, 0, 0]) {
        translate([0, center_r, 0])
        cube([arm_width, roller_r-4*bearing_width/2-center_r, bearing_outer_dia]);

        translate([0, roller_r+4*bearing_width/2, 0])
        difference() {
            cube([arm_width, 60, bearing_outer_dia]);
            translate([-arm_width/2, 10, bearing_outer_dia/2])
            cube([2*arm_width, 60-20, 4.5]);
        }
    }

    translate([0, roller_r, 0])
    bearing_holder();
}

module base_center() {
    difference() {
        linear_extrude(height=bearing_outer_dia)
        regular_polygon(n=4, min_r=center_r);

        cylinder(r=bearing_inner_dia/2+0.1, h=3*bearing_outer_dia, center=true);

        for (theta = [0:360/n_arms:360])
        rotate(theta)
        arm_flange_holes();

        // center bolt head
        cylinder(r=18/2, h=12, center=true);
    }
}

module base() {
    base_center();

    for (theta=[0:360/n_arms:360])
    rotate([0,0,theta])
    base_arm();
}

module bearing_pin() {
    cylinder(r=0.97*bearing_inner_dia/2, h=2.9*bearing_width);
}

// Dovetail
//
//        |-- b --|
//        _________  _
//        \       /  |
//         \     /   |c   
//          \___/    |
//                   -
//          |---|
//            a
module dovetail(a=10, b=30, c=15, fudge=0) {
    aa = a/2 + fudge;
    bb = b/2 + fudge;
    cc = c;
    polygon([[-aa,0], [-bb,cc], [bb,cc], [aa,0]]);
}

module regular_polygon(n, min_r) {
    if (n==3) {
        echo("regular_polygon: unimplemented: triangles");
    } else if (n==4) {
        square([2*min_r, 2*min_r], center=true);
    } else if (n > 4) {
        for (theta = [0:360/n:360])
        rotate(theta)
        translate([0, -min_r*tan(360/n/2)])
        square([min_r, 2*min_r*tan(360/n/2)]);
    }
}

module wheel_center() {
    size = 44.7;

    difference() {
        linear_extrude(height=wheel_height)
        #regular_polygon(6, size);

        // Bearing
        cylinder(r=bearing_outer_dia/2+0.5, h=2*bearing_width, center=true);
        cylinder(r=8/2, h=3*wheel_height);

        // Dovetails
        rotate(360/12)
        for (theta = [0:360/6:360])
        rotate(theta)
        translate([0,-45,-wheel_height])
        linear_extrude(height=3*wheel_height)
        dovetail(0.55);
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
            hub_thickness=20, hub_diameter=20, bore_diameter=5.5+0.5);

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

    translate([155, arm_width/2+5/2, 0]) {
        motor_mount();
        translate([0,0,30])
        rotate([0,0,10])
        motor_gear();
    }
}

// Print plates
module print_plate_1() {
    translate([0, -100, 0]) {
        for (i = [0:n_arms])
        translate([50*i-100, 0, 0]) base_arm();
    }
}

module print_plate_2() {
    base_center();

    for (i=[1:n_arms])
    translate([40, 2*bearing_inner_dia*i, 0])
    bearing_pin();

    translate([-60, 0, 0])
    motor_gear();
}

module wheel_sectors_print(i) {
    wheel_pieces = 6;
    fudge = 0.1; // degrees
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
    mount_height = 60;
    wall_thickness = 2;
    rotate([0,0,-45])
    translate([0,0,mount_height/2])
    difference() {
        cube([size, size, mount_height], center=true);

        translate([-wall_thickness*2, -wall_thickness*2, -wall_thickness*2])
        cube([size-wall_thickness, size-wall_thickness, mount_height-wall_thickness],
            center=true);

        // Cut out for wheel
        rotate([0,0,45])
        translate([-size/4, 0, -0])
        cube([size, 3*size, wheel_height*3], center=true);

        // Motor shaft hole
        cylinder(r=23/2, h=2*mount_height);

        // Motor screw holes
        translate([0,0,mount_height/2])
        for (theta = [45:90:360])
        rotate([0, 0, theta])
        translate([1.725*mm_per_inch, 0, 0])
        cylinder(r=3/2+0.5, h=50, center=true);

        // Cut off top
        rotate([0,0,45])
        translate([-65, 0, mount_height/2])
        cube([100, 200, 22], center=true);

        // Cut out side
        translate([-wall_thickness*2, 0, -mount_height/2])
        cube([size, 2*size, 2*(bearing_outer_dia+1)], center=true);

        translate([-8, 0, -25])
        rotate([0, 10, 0])
        cube([size, 2*size, mount_height], center=true);
    }

    translate([80/2, 0, bearing_outer_dia/2])
    difference() {
        cube([80, 5, bearing_outer_dia], center=true);
        cube([0.8*80, 10, 4.5], center=true);
    }
}

//print_plate_1();
//print_plate_2();
//wheel_sectors_print(2);

//base();

assembly();
//motor_mount();

//wheel_center();
