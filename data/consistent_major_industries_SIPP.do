/* This code uses industry classifications originally laid out by Bezhad Kianian,
but further aggregates the industries in order to get more consistent industries
across time (in particular, across years in which coding changed, such as the change
from 2002 to 2003). We use the standard major industry classifications, but in a
way that smooths over the changesin the more detailed industries.
*/


scalar Cencode80=0


capture drop mjrind
gen mjrind = .

/* Codes from the 1980 Census are consistent until January of 1990. Codes from 
the 1990 Census are consistent until January of 2003. And aside for some 
shuffling around *within* the groups defined here, the 2002 Census codes 
(based on 2000 Census codes, but with some alterations from the 2002 NAICS) 
are consistent until present. 
	For completeness, note that there is a slight change in codes Starting in 
January 2009, using the 2007 NAICS, and again in January 2014, using the 2012 
NAICS. These changes shuffle people around a bit at the most detailed level of
industry classifications, but all those changes have been taken into 
consideration here by extending the ranges to include any newly created 
industries. 
	The result is that despite there being 3 different coding systems after 
December 2002, we only need one indicator for that period, because we can 
control for all the changes after that point with one set of ranges. 
*/
	
#delimit ;

// missing
replace mjrind = -1 if ind<0;

***// ---- AGRICULTURE ---- //***
// Includes the Agriculture and Mining industries from Bezhad.;

// Agriculture
replace mjrind = 1 if
  (Cencode00==1 & ind >=170 & ind <=290) |
  (Cencode90==1 & inlist(ind, 10, 11, 30, 31, 32, 230)) |
  (Cencode80==1 & inlist(ind, 10, 11, 20, 30, 31, 230));

***// ---- MINING ---- //***
// Includes the Agriculture and Mining industries from Bezhad.;

// Mining
replace mjrind = 2 if 
  (Cencode00==1 & ind>=370 & ind<=490) |
  ((Cencode90==1|Cencode80==1) & inlist(ind, 42, 41, 40, 50));

 
***// ---- CONSTRUCTION ---- //***
//Includes the Construction industry from Bezhad.;
 
//Construction
replace mjrind = 3 if
  (Cencode00==1 & ind==770) |
  ((Cencode90==1 | Cencode80==1) & ind==60);
  

***// ---- NONDURABLE MANUFACTURING ---- //***
/*Includes the Food Manufacturing, Beverage & Tobacco Product Manufacturing, 
Textile Mills, Apparel Manufacturing, Leather & Allied Products Manufacturing, 
Paper Manufacturing, Printing, Petroleum & Coal Products, Chemical, and Plastic
& Rubber Product Manufacturing industries from Bezhad.*/;

//Food Manufacturing
replace mjrind = 4 if 
  (Cencode00==1 & ind>=1070 & ind<=1290) |
  ((Cencode90==1 | Cencode80==1) & 
  inlist(ind, 110, 112, 102, 101, 100, 610, 111, 121, 122));

//Beverage & Tobacco Manufacturing 
replace mjrind = 4 if
  (Cencode00==1 & (ind==1370 | ind==1390)) |
  ((Cencode90==1 | Cencode80==1) & (ind==120 | ind==130));
  
//Textile Mills & Textile Products
replace mjrind = 4 if
  (Cencode00==1 & ind>=1470 & ind<=1590) |
  ((Cencode90==1 | Cencode80==1) & inlist(ind, 140,141,142,150));
  
//Apparel Manufacturing
replace mjrind = 4 if
  (Cencode00==1 & ind>=1670 & ind<=1690) |
  ((Cencode90==1 | Cencode80==1) & inlist(ind, 132, 151, 152));
  
// Leather & Allied Products Manufacturing
replace mjrind = 4 if 
  (Cencode00==1 & ind>=1770 & ind<=1790) |
  ((Cencode90==1 | Cencode80==1) & inlist(ind, 221, 222, 220));

//Paper Manufacturing
replace mjrind = 4 if 
  (Cencode00==1 & ind>=1870 & ind<=1890) |
  ((Cencode90==1 | Cencode80==1) & inlist(ind, 160, 162, 161));
  
//Printing & Related Support Activities
replace mjrind = 4 if
  (Cencode00==1 & ind==1990) |
  ((Cencode90==1 | Cencode80==1) & ind==172);

//Petroleum & Coal Products Manufacturing
replace mjrind = 4 if
  (Cencode00==1 & ind>=2070 & ind<=2090) |
  ((Cencode90==1 | Cencode80==1) & inlist(ind, 200, 201));
  
//Chemical Manufacturing
replace mjrind = 4 if 
  (Cencode00==1 & ind>=2170 & ind<=2290) |
  ((Cencode90==1 | Cencode80==1) & inlist(ind, 180, 191, 181, 190, 182, 192));
 
//Plastic & Rubber Product Manufacturing
replace mjrind = 4 if 
  (Cencode00==1 & ind>=2370 & ind<=2390) |
  ((Cencode90==1 | Cencode80==1) & inlist(ind, 212, 210, 211));
  

***// ---- DURABLE MANUFACTURING ---- //***
/* Includes the Nonmetallic Mineral Product Manufacturing, Metal, Machinery,
Computer & Electronic Product, Electrical Equip., Appliances and Component, 
Transportation Equipment, Wood Products, and Miscellaneous Manufacturing 
industries from Bezhad. */;

//Nonmetallic Mineral Product Manufacturing
replace mjrind = 4 if
  (Cencode00==1 & ind>=2470 & ind<=2590) |
  ((Cencode90==1 | Cencode80==1) & inlist(ind, 261, 252, 250, 251, 262));
  
//Metal Industries
replace mjrind = 4 if
  (Cencode00==1 & ind>=2670 & ind<=2990) |
  ((Cencode90==1 | Cencode80==1) &
  inlist(ind, 270, 271, 272, 280, 281, 282, 290, 291, 292, 300, 301));
  
//Machinery Manufacturing
replace mjrind = 4 if 
  (Cencode00==1 & ind>=3070 & ind<=3290) |
  ((Cencode90==1 | Cencode80==1) &
  inlist(ind, 311, 312, 321, 380, 320, 310, 331, 332));
  
//Computer and Electronic Product Manufacturing
replace mjrind = 4 if
  (Cencode00==1 & ind>=3360 & ind<=3390) |
  ((Cencode90==1 | Cencode80==1) & 
  inlist(ind, 322, 341, 371, 381, 342));
  
//Electrical Equipment, Appliances, and Compnent Manufacturing
replace mjrind = 4 if
  (Cencode00==1 & ind>=3470 & ind<=3490) |
  ((Cencode90==1 | Cencode80==1) & inlist(ind, 340, 350));
  
//Transportation Equipment Manufacturing
replace mjrind = 4 if
  (Cencode00==1 & ind>=3570 & ind<=3690) |
  ((Cencode90==1 | Cencode80==1) & 
  inlist(ind, 351, 352, 362, 361, 360, 370));
  
//Wood Product Manufacturing
replace mjrind = 4 if
  (Cencode00==1 & ind>=3770 & ind<=3895) |
  ((Cencode90==1 | Cencode80==1) &
  inlist(ind, 231, 232, 241, 242));
  
//Miscellaneous Manufacturing
replace mjrind = 4 if
  (Cencode00==1 & ind>=3960 & ind<=3990) |
  (Cencode90==1 & inlist(ind, 372, 390, 391, 392)) |
  (Cencode80==1 & inlist(ind, 372, 390, 391, 392, 382));
  
  
***// ---- WHOLESALE TRADE ---- //***
/*Includes the Durable Goods, Wholesalers and Nondurable Goods, Wholesalers
industries from Bezhad.*/;

//Durable Goods, Wholesalers
replace mjrind = 5 if
  (Cencode00==1 & ind>=4070 & ind<=4290) |
  (Cencode90==1 & inlist(ind, 500, 501, 502, 510, 511, 512, 521, 530, 531, 532)) |
  (Cencode80==1 & inlist(ind, 500, 501, 502, 510, 511, 512, 521, 522, 530, 531, 532));

  
//Nondurable Goods, Wholesalers
replace mjrind = 5 if
  (Cencode00==1 & ind>=4370 & ind<=4590) |
  ((Cencode90==1 | Cencode80==1) &
  inlist(ind, 540, 541, 542, 550, 551, 552, 560, 561, 562, 571));
  

***// ---- RETAIL TRADE ---- //***
//Includes the Retail Trade industry from Bezhad.;

//Retail Trade
replace mjrind = 6 if 
  (Cencode00==1 & ind>=4670 & ind<=5790) |
  (Cencode90==1 & 
  inlist(ind,612,622,620,631,632,633,580,581,582,601,611,602,650,642,682,621,623,630,660,651,662,640,652,591,600,592,681,661,590,663,670,672,671,691)) |
  (Cencode80==1 &
  inlist(ind,612,622,620,632,640,580,581,582,601,611,602,650,642,682,621,630,631,660,651,661,640,652,591,600,592,681,661,590,662,670,672,671,691));


***// ---- TRANSPORTATION AND WAREHOUSING ---- //***
//Includes the Transportation and Warehousing industry from Bezhad.;

//Transportation and Warehousing
replace mjrind = 7 if 
  (Cencode00==1 & ind>=6070 & ind<=6390) |
  ((Cencode90==1 | Cencode80==1) &
  inlist(ind,421,400,420,410,401,402,422,412,411));
  
 ***// ---- UTILITIES ---- //***
//Includes the Utilities industry from Bezhad.;

//Utilities
replace mjrind = 7 if 
  (Cencode00==1 & ind>=570 & ind<=690) |
  (Cencode90==1 & inlist(ind, 450,451,452,470,472)) |
  (Cencode80==1 & inlist(ind, 460,461,462,470,472));
  
  
***// ---- INFORMATION ---- //***
/*Includes the Publishing, Broadcasting & Communications, and Information 
Services & Data Processing Services Industries from Bezhad.*/;

//Publishing Industries
replace mjrind = 8 if
  (Cencode00==1 & ind>=6470 & ind<=6590) |
  ((Cencode90==1 | Cencode80==1) & inlist(ind, 171, 800));
  
//Broadcasting & Communications
replace mjrind = 8 if
  (Cencode00==1 & ind>=6670 & ind<=6695) |
  ((Cencode90==1 | Cencode80==1) & inlist(ind,440,441,442));

//Information Services & Data Processing Services
replace mjrind = 8 if
  (Cencode00==1 & ind>=6770 & ind<=6780) |
  ((Cencode90==1 | Cencode80==1) & ind==852);
  
  
***// ---- FINANCIAL SERVICES ---- //***
/*Includes the Finance & Insurance and Real Estate, Rental, & Leasing industries
from Bezhad. */;

//Finance & Insurance
replace mjrind = 9 if
  (Cencode00==1 & ind>=6870 & ind<=6990) |
  ((Cencode90==1 | Cencode80==1) & inlist(ind, 700,701,702,710,711));
  
//Real Estate, Rental, & Leasing 
replace mjrind = 9 if
  (Cencode00==1 & ind>=7070 & ind<=7190) |
  (Cencode90==1 & inlist(ind, 712, 742, 801)) |
  (Cencode80==1 & ind==712);
  

***// ---- PROFESSIONAL SERVICES ---- //***
/*Includes the Professional, Scientific, & Technical Services and Management, 
Admin. & Support, & Waste Management Services from Bezhad. */;

//Professional, Scientific, & Technical Services
replace mjrind = 10 if
  (Cencode00==1 & ind>=7270 & ind<=7490) |
  (Cencode90==1 & inlist(ind, 841, 890, 882, 732, 892, 891, 721, 012, 893)) |
  (Cencode80==1 & inlist(ind, 841, 890, 882, 732, 891, 721, 892, 730, 740));
  
//Management, Admin. & Support, & Waste Management Services
replace mjrind = 10 if
  (Cencode00==1 & ind>=7570 & ind<=7790) |
  (Cencode90==1 & inlist(ind,731,741,432,740,722,20,471)) |
  (Cencode80==1 & inlist(ind,731,742,432,741,722,21,471));
  
  
***// ---- EDUCATION ---- //***
//Includes the Educational Services industry from Bezhad.;

//Educational Services
replace mjrind = 11 if
  (Cencode00==1 & ind>=7860 & ind<=7890) |
  ((Cencode90==1 | Cencode80==1) & inlist(ind, 842,850,851,860));

  
***// ---- HEALTH SERVICES ---- //**
//Includes the Health Care and Social Assistance industries from Bezhad.;

//Health Care
replace mjrind = 11 if(Cencode00==1 & ind>=7970 & ind<=8290) |
  ((Cencode90==1 | Cencode80==1) & 
  inlist(ind, 812, 820, 821, 822, 830, 840, 831, 832, 870));
  
//Social Assistance
replace mjrind = 11 if
  (Cencode00==1 & ind>=8370 & ind<=8470) |
  (Cencode90==1 & inlist(ind, 871, 861, 862, 863)) |
  (Cencode80==1 & inlist(ind, 871, 861, 862));
  
  
***// ---- LEISURE & HOSPITALITY ---- //***
/*Includes the Arts, Entertainment, & Recreation and Accomodations & Food 
Services industries from Bezhad.*/;

//Arts, Entertainment, & Recreation
replace mjrind = 12 if
  (Cencode00==1 & ind>=8560 & ind<=8590) |
  (Cencode90==1 & inlist(ind, 810, 872, 802)) |
  (Cencode80==1 & inlist(ind, 802, 872, 801));
  
//Accomodations & Food Services
replace mjrind = 12 if
  (Cencode00==1 & ind>=8660 & ind<=8690) |
  ((Cencode90==1 | Cencode80==1) & inlist(ind, 762, 770, 641));
  
  
***// ---- OTHER SERVICES ---- //***
/*Includes the Repair & Maintenance, Personal & Laundry Services, Religious,
Grantmaking, Civic, Business, & Similar Organizations and Private Households
industries from Bezhad.*/;

//Repair & Maintenance
replace mjrind = 13 if
  (Cencode00==1 & ind>=8770 & ind<=8890) |
  ((Cencode90==1 | Cencode80==1) & inlist(ind, 751, 750, 752, 760, 790, 782));
  
//Personal & Laundry Services
replace mjrind = 13 if
  (Cencode00==1 & ind>=8970 & ind<=9090) |
  ((Cencode90==1 | Cencode80==1) & inlist(ind, 780, 772, 771, 781, 791));
  
//Religious, Grantmaking, Civic, Business, & Similar Organizations
replace mjrind = 13 if
  (Cencode00==1 & ind>=9160 & ind<=9190) |
  (Cencode90==1 & inlist(ind, 880, 881, 873)) |
  (Cencode80==1 & inlist(ind, 880, 881));
  
//Private Households
replace mjrind = 13 if
  (Cencode00==1 & ind==9290) | ((Cencode90==1 | Cencode80==1) & ind==761);

  

***// ---- PUBLIC ADMINISTRATION ---- //***
//Includes the Public Administration industry from Bezhad.;

//Public Administration
replace mjrind = 14 if
  (Cencode00==1 & ind>=9370 & ind<=9590) |
  ((Cencode90==1 | Cencode80==1) & 
  inlist(ind, 900,921,901,910,922,930,931,932));
  
  
***// ---- MILITARY ---- //****
//Includes the Military, Etc. industry from Bezhad.;

//Military, Etc.
replace mjrind = 15 if 
  (Cencode00==1 & ind==9890) |
  ((Cencode90==1 | Cencode80==1) & ind==991);



********************************************************************************
							//Labeling Industries//
********************************************************************************
;
capture label drop mjrind;
label define mjrind 1 "Agriculture";
label define mjrind 2 "Mining", add;
label define mjrind 3 "Construction", add;
label define mjrind 4 "Manufacturing", add;
label define mjrind 5 "Wholesale Trade", add;
label define mjrind 6 "Retail Trade", add;
label define mjrind 7 "Transportation & Warehousing", add;
label define mjrind 8 "Information", add;
label define mjrind 9 "Financial Services", add;
label define mjrind 10 "Professional Services", add;
label define mjrind 11 "Educational, health and social services", add;
label define mjrind 12 "Arts, entertainment, recreation, accommodations, and food services", add;
label define mjrind 13 "Other Services", add;
label define mjrind 14 "Public Administration", add;
label define mjrind 15 "Military", add;
label define mjrind -1 "Missing", add;

#delimit cr

  









  
  
  
