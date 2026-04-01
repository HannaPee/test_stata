clear
global wd "C:\Users\42610\OneDrive - Handelshögskolan i Stockholm\Documents\Test_stata"
global figures "$wd\figures"

cap "$wd"

sysuse auto, clear

scatter price mpg 
graph export ./figures/figure1.png, replace wid(1000)
scatter length weight
graph export ./figures/figure2.png, replace wid(1000)
scatter price weight
graph export ./figures/figure3.png, replace wid(1000)
scatter length mpg
graph export ./figures/figure4.png, replace wid(1000)


// Create a RED.ME file, and choose the name (in this case test_stata)

! echo #  test_stata >> README.md

// Initialize got code 

! git init

// Add READ.ME file and comit 

! git add README.md
! git commit -m "my first upload"

//! git branch -M main
! git push -u origin main

// Define the directory where we wanto add this file 

! git remote add origin https://github.com/HannaPee/test_stata.git

// Push changes to directory 
! git branch -M main
! git push -u origin main


// Add do_file to repository 

! git status
! git add do_file.do
! git commit -m "Add do file_2"
! git push

// Add figures from folder "figures"

! git add figures/
! git commit -m "Add figures"
! git push