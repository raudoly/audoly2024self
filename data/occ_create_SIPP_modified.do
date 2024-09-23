/*********************************************************************
This file createst consistent detailed occupation categories based
on a paper by Peter Meyer of the BLS. 
See: http://stat.bls.gov/ore/pdf/ec050090.pdf
The consistent categories are created with REMAPJOB_SIPP.do,
which is a file modified slightly from Meyer's program.
See: https://econterms.net/pbmeyer/research/occs/wiki/index.php?title=Remapjob.do#The_remapjob.do_code

After running the code, we then aggregate to about 80 categories.
This helps make the categories more consistent as the differences
from the 1990 Census Codes to the 2000 Census Codes are dramatic.

Finally, we label the categories.

1990 and 1991 SIPP Panels use 1980 Census Codes.
1992-2001 Panels use 1990 Census Codes
2004 and 2008 Panels use 2002 Census Codes.
----------------------------------------------------------------------
Sources:
http://www.census.gov/hhes/www/ioindex/pdfio/techtab02.pdf
http://usa.ipums.org/usa/volii/99occup.shtml
http://www.bls.gov/nls/quex/r1/y97r1cbka1.pdf
http://stat.bls.gov/ore/pdf/ec050090.pdf

Author: Behzad Kianian
Current Date: May 9, 2012

See occtest3.do for what I was originally working with.

It is intended that gen_vars within master_create will call this file.
***********************************************************************/ 

** (2) ** The rest creates 80 or so broader categories that we will use **
gen ocdest_m = .
// Executive, Administrative, and Managerial Occupations
// Coded as 003 to 022 in the 1990 Classification System.
replace ocdest_m = 1 if (ocdest>=3 & ocdest<=22)
// Management Related Occupations
// Codes as 023 to 037 in the 1990 Classification System.
replace ocdest_m = 2 if (ocdest>=23 & ocdest<=37)
// Architects: 43
replace ocdest_m = 3 if ocdest==43
// Engineers: 44 to 59
replace ocdest_m = 4 if (ocdest>=44 & ocdest<=59)
// Math and Computer Scientists: 64 to 68
replace ocdest_m = 5 if (ocdest>=64 & ocdest<=68)
// Natural Scientists: 69 to 83
replace ocdest_m = 6 if (ocdest>=69 & ocdest<=83)
** Consider combining 84 through 106 **
// Health Diagnosing Occupations: 84 to 89
replace ocdest_m = 7 if (ocdest>=84 & ocdest<=89)
// Health Assessment & Treating Occupations: 95 to 97
replace ocdest_m = 8 if (ocdest>=95 & ocdest<=97)
// Therapists: 98 to 106
replace ocdest_m = 9 if (ocdest>=98 & ocdest<=106)
// Teachers Post-secondary: 113 to 154
replace ocdest_m = 10 if (ocdest>=113 & ocdest<=154)
// Teachers non-Post-secondary: 155 to 159
replace ocdest_m = 11 if (ocdest>=155 & ocdest<=159)
** ALSO include vocational and educational counselors: 163
replace ocdest_m = 11 if (ocdest==163)
// Librarians, Archivists, and Curators: 164 and 165
replace ocdest_m = 12 if (ocdest>=164 & ocdest<=165)
// Social Scientists and Urban Planners: 166 to 173
replace ocdest_m = 13 if (ocdest>=166 & ocdest<=173)
// Social, Recreation and Religious Workers: 174 to 176/177
replace ocdest_m = 14 if (ocdest>=174 & ocdest<=176)
// Lawyers and Judges: 178 to 179
replace ocdest_m = 15 if (ocdest>=178 & ocdest<=179)
// Writers, Artists, Entertainers, and Athletes: 183 to 200 (not 199)
replace ocdest_m = 16 if (ocdest>=183 & ocdest<=200)
// Health Technologists and Technicians: 203 to 208
replace ocdest_m = 17 if (ocdest>=203 & ocdest<=208)
// Engineering and Related Technologists and Technicians: 213 to 218
** This might warrant some investigation.**
replace ocdest_m = 18 if (ocdest>=213 & ocdest<=218)
// Science Technicians: 223 to 225
replace ocdest_m = 19 if (ocdest>=223 & ocdest<=225)
// Technicians, except health, engineering and science: 226 to 235
replace ocdest_m = 20 if (ocdest>=226 & ocdest<=235)
// Sales supervisors and proprietors: 243
replace ocdest_m = 21 if (ocdest==243)
// Sales Representatives, Finance and Business Services: 253 to 256
replace ocdest_m = 22 if (ocdest>=253 & ocdest<=256)
// Sales Engineers: 258
replace ocdest_m = 23 if (ocdest==258)
** MASHING SOME OF THESE SALES THINGS TOGETHER **
// Salespersons, NEC, clerks, cashiers, promoters, models: 274 to 283
replace ocdest_m = 24 if (ocdest>=274 & ocdest<=283)
** MAKE NOTE OF THE FOLLOWING ** 
// Office Supervisors: 303
replace ocdest_m = 25 if (ocdest==303)
// Computer and peripheral equipment operators: 308
replace ocdest_m = 26 if (ocdest==308)
// Secretaries, Stenographers, Typists: 313 to 315
replace ocdest_m = 27 if (ocdest>=313 & ocdest<=315)
// Information Clerks: 316 to 323
replace ocdest_m = 28 if (ocdest>=316 & ocdest<=323)
// Records Processing Occ, Except Financial: 326-336
replace ocdest_m = 29 if (ocdest>=326 & ocdest<=336)
// Records processing Financial: 337 to 344
replace ocdest_m = 30 if (ocdest>=337 & ocdest<=344)
// Duplicating & office Machine Operators: 345 to 347
replace ocdest_m = 31 if (ocdest>=345 & ocdest<=347)
// Telephone & Telecom: 348 & 349
replace ocdest_m = 32 if (ocdest>=348 & ocdest<=349)
// Mail Occupations: 354 to 357
replace ocdest_m = 33 if (ocdest>=354 & ocdest<=357)
// material Recording/Scheduling/Distributing: 359 to 373
replace ocdest_m = 34 if (ocdest>=359 & ocdest<=373)
// Adjusters and Investigators: 375 to 378
replace ocdest_m = 35 if (ocdest>=375 & ocdest<=378)
// Miscellaneous Admin Support Occupations: 379 to 389
replace ocdest_m = 36 if (ocdest>=379 & ocdest<=389)
// Private Household Occupations: 405 and 407
replace ocdest_m = 37 if (ocdest>=405 & ocdest<=407)
** THESE ARE DIFFERENT FROM 1990 CATEGORIES ** 
// Supervisors of Guards: 415
replace ocdest_m = 38 if (ocdest==415)
// Firefighting, prevention and inspection: 417
replace ocdest_m = 39 if (ocdest==417)
// Police detectives and private investigators, & Other law enf.: 418, 423
replace ocdest_m = 40 if (ocdest>=418 & ocdest<=423)
// crossing guards, watchmen, and protective nec. : 424 to 427
replace ocdest_m = 41 if (ocdest>=424 & ocdest<=427)
// Food Prep and Service: 433 to 444
replace ocdest_m = 42 if (ocdest>=433 & ocdest<=444)
// Health Service Occupations: 445 to 447
replace ocdest_m = 43 if (ocdest>=445 & ocdest<=447)
// Cleaning & Building, exc. Household: 448 to 455
replace ocdest_m = 44 if (ocdest>=448 & ocdest<=455)
// Personal Service Occupations: 456 to 469
replace ocdest_m = 45 if (ocdest>=456 & ocdest<=469)
// Farm Operators and Managers: 473 to 476
** DOESNT SEEM VERY CONSISTENT OVER TIME **
replace ocdest_m = 46 if (ocdest>=473 & ocdest<=476)
// Farm Occupations Except Managerial: 479 to 484
replace ocdest_m = 47 if (ocdest>=479 & ocdest<=484)
// Related Agricultural Occupations: 485 to 489
replace ocdest_m = 48 if (ocdest>=485 & ocdest<=489)
// Forestry and Logging Occupations: 496
replace ocdest_m = 49 if (ocdest==496)
// Fishers, Hunters, and kindred: 498
replace ocdest_m = 50 if (ocdest==498)
// Supervisors of Mechanics and Repairers: 503
replace ocdest_m = 51 if (ocdest==503)
// Vehicle & Mobile Eq. Repairers: 505 to 519
replace ocdest_m = 52 if (ocdest>=505 & ocdest<=519)
// Electrical & Electronic Eq. Repairers: 523 to 534
replace ocdest_m = 53 if (ocdest>=523 & ocdest<=534)
// Miscellaneous Mechanics & Repairers: 535 to 549
replace ocdest_m = 54 if (ocdest>=535 & ocdest<=549)
// Supervisors of Construction: 558
replace ocdest_m = 55 if (ocdest==558)
// Other Construction: 563 to 599
replace ocdest_m = 56 if (ocdest>=563 & ocdest<=599)
// Extractive Occupations: 613 to 617
replace ocdest_m = 57 if (ocdest>=613 & ocdest<=617)
// Precision Production, Supervisors: 628
replace ocdest_m = 58 if (ocdest==628)
// Precision Metal Working Occupations: 634 to 653
replace ocdest_m = 59 if (ocdest>=634 & ocdest<=653)
// Precision Woodworking Occupations: 657 to 659
replace ocdest_m = 60 if (ocdest>=657 & ocdest<=659)
// Precision Textile, Apparel, Furnishings Machine Workers: 666 to 674
replace ocdest_m = 61 if (ocdest>=666 & ocdest<=674)
// Precision Workers: Assorted Materials: 675 to 684
replace ocdest_m = 62 if (ocdest>=675 & ocdest<=684)
// Precision Food Production Occupations: 686 to 688
replace ocdest_m = 63 if (ocdest>=686 & ocdest<=688)
** DIFFERS, EMPTY FOR 2000 **
// Adjusters and Calibrators: 693
replace ocdest_m = 64 if (ocdest==693)
// Plant and System Operators: 694 to 699
replace ocdest_m = 65 if (ocdest>=694 & ocdest<=699)
// Machine Operators & Tenders, Exc. .....: 703 to 717
replace ocdest_m = 66 if (ocdest>=703 & ocdest<=717)
// Metal and Plastic Processing Machine Operators: 719 to 724
replace ocdest_m = 67 if (ocdest>=719 & ocdest<=724)
// Woodworking Machine Operators: 726 to 733
replace ocdest_m = 68 if (ocdest>=726 & ocdest<=733)
// Printing machine operators: 734 to 736
replace ocdest_m = 69 if (ocdest>=734 & ocdest<=736)
// Textile, Apparel, Furnishing Machine Operators: 738 to 749
replace ocdest_m = 70 if (ocdest>=738 & ocdest<=749)
// Machine Operators, Assorted Materials: 753 to 779
replace ocdest_m = 71 if (ocdest>=753 & ocdest<=779)
// Fabricators, Assemblers, and Hand Workign Occs: 783 to 789
replace ocdest_m = 72 if (ocdest>=783 & ocdest<=789)
// Production Inspectors, Testers. . . .: 796 to 799
replace ocdest_m = 73 if (ocdest>=796 & ocdest<=799)
// Motor Vehicle Operators: 803 to 813
replace ocdest_m = 74 if (ocdest>=803 & ocdest<=813)
// Transportation Occupations, except Motor Vehicles: 823 to 859
** THIS MAY BE (POSSIBLY) BROKEN DOWN FURTHER **
replace ocdest_m = 75 if (ocdest>=823 & ocdest<=859)
// Helpers, Constructions: 865
replace ocdest_m = 76 if (ocdest==865)
// Helpers surveyors, construction laborers, and production helpers: 866 to 874
replace ocdest_m = 77 if (ocdest>=866 & ocdest<=874)
// Freight, stock, material handlers: 875 to 889
replace ocdest_m = 78 if (ocdest>=875 & ocdest<=889)
// MILITARY: 905
replace ocdest_m = 79 if (ocdest==905)


#delimit ;
capture label drop ocdestml;
label define ocdestml 1 "(3-22) Executive, Admin., and Managerial Occs. ";
label define ocdestml 2 "(23-37) Management Related Occupations", add;
label define ocdestml 3 "(43) Architects", add;
label define ocdestml 4 "(44-59) Engineers", add;
label define ocdestml 5 "(64-68) Math & Comp. Scientists", add;
label define ocdestml 6 "(69-83) Natural Scientists", add;
label define ocdestml 7 "(84-89) Health Diagnosing Occs", add;
label define ocdestml 8 "(95-97) RNs, Pharmacists, Dieticians", add;
label define ocdestml 9 "(98-106) Therapists", add;
label define ocdestml 10 "(113-154) Teachers, Postsecondary", add;
label define ocdestml 11 "(155-159) Teachers, exc. Post, + Vocational", add;
label define ocdestml 12 "(164-165) Librarians, Archivists, Curators", add;
label define ocdestml 13 "(166-173) Social Scientists & Urban Planners", add;
label define ocdestml 14 "(174-176) Social, Recreation & Religious Workers", add;
label define ocdestml 15 "(178-179) Lawyers & Judges", add;
label define ocdestml 16 "(183-200) Writers, Artists, Entertainers & Athletes", add;
label define ocdestml 17 "(203-208) Health Technologists & Technicians", add;
label define ocdestml 18 "(213-218) Engineering & Related Techno. & Technicians", add;
label define ocdestml 19 "(223-225) Science Technicians", add;
label define ocdestml 20 "(226-235) Technicians ex. Health Engineering & Science", add;
label define ocdestml 21 "(243) Sales Supervisors & Proprietors", add;
label define ocdestml 22 "(253-256) Sales Reps, Finance and Business Services", add;
label define ocdestml 23 "(258) Sales Engineers", add;
label define ocdestml 24 "(274-283) ** Sales persons n.e.c., clerks, cashiers, promoters, models", add;
label define ocdestml 25 "(303) ** Office Supervisors", add;
label define ocdestml 26 "(308) ** Computer and Peripheral Equipment Operators", add;
label define ocdestml 27 "(313-315) ** Secretaries, Stenographers, Typists", add;
label define ocdestml 28 "(313-323) Information Clerks", add;
label define ocdestml 29 "(326-336) Records Processing Occs Ex. Financial", add;
label define ocdestml 30 "(337-344) Records Processing Financial", add;
label define ocdestml 31 "(345-357) Duplicating, Mail & Other Office Machine Oper.", add;
label define ocdestml 32 "(348-349) Telephone & Telecom Operators", add;
label define ocdestml 33 "(354-357) Mail & Message Distributing Occupations", add;
label define ocdestml 34 "(359-373) Material Recording, Scheduling & Distributing Clerks", add;
label define ocdestml 35 "(375-378) Adjusters & Investigators", add;
label define ocdestml 36 "(379-389) Miscellaneous Admin. Support Occupations", add;
label define ocdestml 37 "(405-407) Private Household Occupations", add;
label define ocdestml 38 "(415) ** Supervisors of Guards", add;
label define ocdestml 39 "(417) ** Firefighting, Prevention & Inspections", add;
label define ocdestml 40 "(418-423) ** Police, detec., priv. investigators & other law enf.", add;
label define ocdestml 41 "(424-427) ** Guards, Watchmen, & Other Protective Service NEC", add;
label define ocdestml 42 "(433-444) Food Preparation & Service Occ.", add;
label define ocdestml 43 "(445-447) Health Service Occupations", add;
label define ocdestml 44 "(448-455) Cleaning & Building Service, Exc. Household", add;
label define ocdestml 45 "(456-469) Personal Service Occupations", add;
label define ocdestml 46 "(473-476) Farm Operators & Managers", add;
label define ocdestml 47 "(479-484) Farm Occupations exc. Managerial", add;
label define ocdestml 48 "(485-489) Related Agricultural Occupations", add;
label define ocdestml 49 "(496) Timber, logging, and forestry workers", add;
label define ocdestml 50 "(498) Fishers, hunters, and kindred", add;
label define ocdestml 51 "(503) Supervisors of Mechanics & Repairers", add;
label define ocdestml 52 "(505-519) Vehicle & Mobile Equip. Mechanics & Repairers", add;
label define ocdestml 53 "(523-534) Electrical & Electronic Equipment Repairers", add;
label define ocdestml 54 "(535-549) Miscellaneous Mechanics & Repairers", add;
label define ocdestml 55 "(558) Supervisors of Construction Work", add;
label define ocdestml 56 "(563-599) Other Construction", add;
label define ocdestml 57 "(613-617) Extractive Occupations", add;
label define ocdestml 58 "(628) Production Supervisors or foremen", add;
label define ocdestml 59 "(634-653) Precision Metal Working Occupations", add;
label define ocdestml 60 "(657-659) Precision Woodworking Occupations", add;
label define ocdestml 61 "(666-674) Precision Textile, Apparel, Furnishings", add;
label define ocdestml 62 "(675-684) Precision Workers, Assorted Materials", add;
label define ocdestml 63 "(686-688) Precision Food Production Occupations", add;
label define ocdestml 64 "(693) ** Adjusters & Calibrators", add;
label define ocdestml 65 "(694-699) Plant & System Operators", add;
label define ocdestml 66 "(703-717) Machine Operators & Tenders, exc. . . ", add;
label define ocdestml 67 "(719-724) Metal & Plastic Processing Machine Operators", add;
label define ocdestml 68 "(726-733) Woodworking Machine Operators", add;
label define ocdestml 69 "(734-736) Printing Machine Operators", add;
label define ocdestml 70 "(738-749) Textile, Apparel, Furnishing Machine Operators", add;
label define ocdestml 71 "(753-779) Machine Operators, Assorted Materials", add;
label define ocdestml 72 "(783-789) Fabricators, Assemblers, & Hand Working Occs.", add;
label define ocdestml 73 "(796-799) Production Checkers, Inspectors & Graders/Sorters in Manu.", add;
label define ocdestml 74 "(803-813) Motor Vehicle Operators", add;
label define ocdestml 75 "(823-859) Transportation Occupations, Ex. Motor Vehicles", add;
label define ocdestml 76 "(865) Helpers, Constructions", add;
label define ocdestml 77 "(866-874) Helpers, Construction & Extractive Occupations", add;
label define ocdestml 78 "(875-889) Freight, Stock & Material Handlers", add;
label define ocdestml 79 "(905) ** MILITARY", add;
#delimit cr
label values ocdest_m ocdestml 
