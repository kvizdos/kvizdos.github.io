let active;
let activeI;
let goTo;

function show(where, el) {
   switch(where) {
        case "RealWorldExperience":
            goTo = "#realWorldExperience";
            break;
        case "VolunteerExperience":
            goTo = "#VolunteerExperience";
            break;
        case "Mobile":
            goTo = "#Mobile";
            break;
        case "Websites":
            goTo = "#Websites";
            break;
        case "Extracurricular":
            goTo = "#Extracurricular";
            break;
   }

//    if(active == goTo) {
//        $(goTo).hide(150);
//        active = "";
//        return;
//    }

//    $(goTo).show(150);

    if(active !== goTo) {
        $(active).hide(150);
        $(activeI).css("transform", "rotate(0deg)");

        $(goTo).show(150);
        active = goTo;
        activeI = el;
        // $(el).removeClass('fa-caret-right');
        // $(el).addClass('fa-caret-down');
        console.log(el);
        $(el).css("transform", "rotate(90deg)");
    } else {
        

            let change = $(goTo).css('display') !== "none";
            if(change) {
                $(el).css("transform", "rotate(0deg)");
            } else {
                console.log("Add class down")      
                $(el).css("transform", "rotate(90deg)");
            }

        $(goTo).toggle(150);
    }

    console.log(active + " - " + goTo);
}