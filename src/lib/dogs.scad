$fn=100;


dogblock = [20,20,10];
//dog(dogblock, type="small");
//dog(dogblock, type="large");
//cornerdog(dogblock, type="small");
//cornerdog(dogblock, type="large");
//handle(dogblock[2], "small");
//handle(dogblock[2], "large");
//pressureplate(dogblock[2]);

//pressurespiral(5, 10, 15);
//pressurespiral2(dogblock[2], 10, 15);
//turnkeyspiral(dogblock[2],"large", 20, 10); //biggest one that can fit on the sides
//turnkeyspiral(dogblock[2],"large", 60, 30);
//turnkeyspiral(dogblock[2],"large", 40, 15);
//spiralhandle();

//turnkey (dogblock[2]*2, "small");
//turnkey (dogblock[2]*2, "large");


module spiralhandle() {
    height=5;
    difference() {
        hull() {
            cylinder(height, 15, 15);
            translate([55,0,0]) cylinder(height,d=15);
        }
        // scale it one percent so the key will certainly fit
        rotate([0,0,45]) scale([1.01,1.01,1.01]) turnkey(height, "large"); 
    }
    
}
//Handle to clamp the stock
//the outer circle isn't concentric to the center one (in the hole)
//by turning it we put pressure on the material. Due to friction it
//stays in place
//Turn them upside down and you can use them as a wedge to lock the
//stock in place.
//Todo:  must have the geometry wrong, as the pressure functionality
//doesn't work yet.  It can be used as a wedge though.
module handle(h, type) {
  //we use half of the height to allow the use of "pressure" plates
  //to offer more flexibility
    
    //we don't use the half height to avoid friction when turning the handle
    height = h*0.48; 
    
    dogcyl(h, type);
    hull() {
        cylinder(height, 15, 15);
        translate([55,0,0]) cylinder(height,d=15);
    }
    //cylinder on the back to keep it flat on the bed
    translate([55,0,0]) cylinder(h,d=15);
    
    platediameter = dogdiameter(type);
    shift = dogdiameter("large")-platediameter;
    //cylinder to use pressure plate
    //depending on the size we need to shift it a bit
    //we won't make two types of pressure plates
    translate([0,-shift,0]) cylinder(h,d=dogdiameter("large")*2);
    //the line above should be a spiral
}

//We want to create a spiral, that with an equal amount of turning the
//presure increases equallly
//As such, for every degree turned, the pressure point should increase with
//the same distance
module pressurespiral(h, mind, maxd) {
    cyld = 1;
    travel = maxd-mind;
    degrees = 360;
    steps = 60;
    stepinc = degrees/steps;
    steptravel = travel/(steps*stepinc);
    
    
    for(i = [0:stepinc:degrees]) {
        rotate([0,0,i]) translate([mind-cyld/2+i*steptravel,0,0])
            cylinder(h,d=cyld);
    }
}

//improved pressurespiral using polygon (more efficient to generate)
module pressurespiral2(h, mind, maxd) {
    cyld = 1;
    travel = maxd-mind;
    degrees = 360;
    //we calculate the #of steps so the friction area is approximately 2mm
    //shortcut: calculate circumference of circle and then the # of steps
    //needed to have an arc of 2mm.
    circ = maxd*PI; //we use largest diameter
    steps = circ/2; //2mm of arc length flat for friction
    echo(steps);
    stepinc = degrees/steps;
    steptravel = travel/(steps*stepinc);

    //we go from the outside to the inside to make sure we reach the
    //furthest point, the smallest ones are unusuable anyway, so better to err on that side
    points=[
        for(i = [degrees:-stepinc:0])
            [
                (mind+i*steptravel) * cos(i),
                (mind+i*steptravel) * sin(i)
            ],
            [mind,0] // add the last point manually, purely cosmetic
    ];
    
    //add the hull as the space it fills up anyway, and the extra volume
    //should provide some extra strength
    hull()
        linear_extrude(h) polygon(points);
}


module turnkeyspiral (h, type, maxd, mind) {
    
    keywidth = 5;
    keylength = 2*mind;
    difference() {
        pressurespiral2(h, mind, maxd);
        // scale it one percent so the key will certainly fit
        scale([1.01,1.01,1.01]) turnkey (h, type); 
    }
}

module turnkey (h, type) {
    maxd = 2*dogdiameter("large")*0.99; // slightly reduce to make sure it fits the plate well
    mind = maxd - 10;
    keywidth = 5;
    keylength = 2*mind;
        translate([0,-dogdiameter(type)/2,0]) dogcyl(h,type);
        translate([-keylength/2,-keywidth/2,0]) cube([keylength,keywidth,h]);
        rotate([0,0,90]) translate([-keylength/2,-keywidth/2,0]) cube([keylength,keywidth,h]);
   
}

module pressureplate(h) {
    //we don't use the half height to avoid friction when turning the handle
    height = h*0.48;
    dia = dogdiameter("large");
    difference() {
        cube([40,50,height]);
        translate([dia+5, dia+10,0]) cylinder(h,d=dia*2+1); //1mm larger to allow to turn
    }
}



//dog with 90 degree corner section
module cornerdog(s, type) {
    difference() {
        union() {
            half=[s[0]/2,s[1],s[2]];
            translate([-3,0,0]) finnedblock(s);
            translate([0,-s[1]+3,0]) rotate([0,0,90]) finnedblock(s);
            rotate([0,0,45]) translate([-half[0]/2,0,0]) finnedblock(half);
            d = dogdiameter (type);
            translate([-d/2,0,0]) dogcyl(s[2],type);
            
        }
        cylinder(s[2],2,2);
        translate([0,0,s[2]]) sphere(r=2);
    }
}


//complete dog with finned block and dogcylinder
module dog(s, type) {
    finnedblock(s);
    translate([s[0]/2,0]) {
        dogcyl(s[2], type);
    }    
}

//finned block to save some material when printing
module finnedblock(s,finwidth=3, findepthratio=0.7) {
    x=s[0];
    y=s[1];
    z=s[2];
    cube([x,y*(1-findepthratio),z]);
    
    //optimize by creating fins to reduce material
    //there are always an uneven number of fins; always a fin at the ends
    fincount = ceil((x/finwidth)/2);
    fingap = (x - fincount*finwidth)/(fincount-1);
    findepth = findepthratio*y;

    for(i=[0:fincount-1]) {
        translate([i*(fingap+finwidth),y-findepth,0]) {
        cube([finwidth, findepth, z], center=false);
        }
    }    
}

//cylinder to match the holes in the snapmaker wasteboard
//possible for both the large holes (used for the clamps)
//and small holes used for screwing the wasteboard to the bed
module dogcyl(h, type) {
    //OpenScad doesn't have real variables, so we can assign oonly once
    cyldiameter = dogdiameter(type);
    cylheight   = h + dogheight(type);
    cylminidiameter
                = dogminidiameter(type);
    cylminiheight
                = dogminiheight(type);
    
    translate([0,cyldiameter/2,0]) {
        cylinder(h=cylheight,d=cyldiameter);
        translate([0,0,cylheight]) {
            cylinder(h=cylminiheight,d=cylminidiameter);
        }
    }
}


//parameters to fill in
//depth and diameter of large holes
largedepth = 3.75;
largediameter = 10.00;
//and the minipart
largeminidepth = 2.50;
largeminidiameter = 3.00;

//depth and diameter of small holes
smalldepth = 3.85;
smalldiameter = 8.00;
//amd the minipart
smallminidepth=1.50;
smallminidiameter=2.40;

//OpenScad doesn't have real variables, so we can assign oonly once
//So we define some conenience functions to get the value we need for
//the parameters
//For an unknow type we return 0.  Some kind of exception might be better
function dogdiameter (type) =   type=="large" ? largediameter : 
                                type=="small" ? smalldiameter :
                                0;
function dogheight (type)   =   type=="large" ? largedepth : 
                                type=="small" ? smalldepth :
                                0;
function dogminidiameter (type)
                            =   type=="large" ? largeminidiameter : 
                                type=="small" ? smallminidiameter :
                                0;
function dogminiheight (type)
                            =   type=="large" ? largeminidepth : 
                                type=="small" ? smallminidepth :
                                0;