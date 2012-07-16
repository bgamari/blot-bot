use <MCAD/involute_gears.scad>;
include <MCAD/constants.scad>;

wheel_height = 10;
wheel_dia = 350;

beaker_recess = 5;
beaker_offset = 100;
beaker_dia = 60;
n_beakers = 8;

roller_r = 250/2;
n_arms = 3;
arm_width = 10;

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

    cylinder(r=8, h=50);

    for (theta=[0:360/n_arms:360])
    rotate([0,0,theta])
    arm();
}

module bearing_pin() {
    cylinder(r=0.97*bearing_inner_dia/2, h=2.9*bearing_width);
}

module wheel() {
    bearing_groove = 2;
    difference() {
        //cylinder(r=wheel_dia/2, h=wheel_height);
        render()
        gear(circular_pitch=gear_pitch, number_of_teeth=130,
            gear_thickness=wheel_height, rim_thickness=wheel_height, hub_thickness=wheel_height,
            involute_facets=1, $fn=2);

        cylinder(r=8.2, h=3*wheel_height, center=true);

        translate([0, 0, wheel_height])
        for (theta = [0:360/n_beakers:360])
        rotate([0, 0, theta])
        translate([beaker_offset, 0, 0])
        cylinder(r=beaker_dia/2, h=2*beaker_recess, center=true);

        translate([0, 0, -bearing_groove]);
        difference() {
            cylinder(r=roller_r+1.5*bearing_width, h=2*bearing_groove, center=true);
            cylinder(r=roller_r-1.5*bearing_width, h=4*bearing_groove, center=true);
        }
    }
}

module motor_gear() {
    difference() {
        gear(circular_pitch=gear_pitch, number_of_teeth=20,
            gear_thickness=wheel_height, rim_thickness=wheel_height,
            hub_thickness=20, hub_diameter=20, bore_diameter=5);

        translate([4, 0, 10 + 5 - m3_nut_minor_dia/2])
        translate([0, 0, 20/2])
        cube([m3_nut_thickness, m3_nut_minor_dia, 20], center=true);

        translate([0, 0, 10 + 5])
        rotate([0, 90, 0]) cylinder(r=3.3/2, h=30);
    }
}

module assembly() {
    base();

    translate([0, 0, 30]) wheel();

    rotate([0,0,-30])
    translate([180, -30, 0]) motor_mount();
}

module print_plate() {
    base();

    for (i=[0:n_arms])
    translate([100+3*bearing_inner_dia*i,0,0])
    bearing_pin();

    translate([-80, 0, 0])
    motor_gear();
}

module wheel_print(i) {
    for (i = [0:3])
    translate([0, 2*i*wheel_height, 0])
    rotate([90,0,0])
    intersection() {
        rotate([0,0,90*i]) wheel();
        cube([1000,1000,1000]);
    }

    translate([40,-40,0]) motor_gear();
}

module motor_mount() {
    size = 120;
    mount_height = 100;
    wall_thickness = 4;
    translate([0,0,mount_height/2])
    difference() {
        cube([size, size, mount_height], center=true);

        translate([-wall_thickness*2, -wall_thickness*2, -wall_thickness*2])
        cube([size-wall_thickness, size-wall_thickness, mount_height-wall_thickness],
            center=true);

        rotate([0,0,45])
        translate([-size/4, 0, 0])
        cube([size, 3*size, size/5], center=true);

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
wheel_print();

//assembly();
//motor_mount();

