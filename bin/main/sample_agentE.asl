{ include("mission-management3.asl", mm) }

/* Initial beliefs and rules */

current_mission("None"). // Exist only to avoid using the mm:: name space

my_name(bob).

num_printed(0).

/* Initial goals */

!initialize.

/* Plans */

+!initialize
   <- .print("Initializing...");
      .wait(1000);

      !my_missions.

+!my_missions
   <- !mm::create_mission(say_hi, 10, []);
      +mm::mission_plan(say_hi,["H","e","l","l","o"," ","W","o","r","l","d","!"]); 

      !mm::create_mission(interruption, 10, []);
      +mm::mission_plan(interruption,["COMBO","BREAKER!!!"]); 

      .print("Finished setting up missions.");

      !start.

+!start
   <- .print("Starting missions.");
      !mm::run_mission(say_hi).


/* MMLibrary related Plans */

+mm::current_mission(Id)
   <- -current_mission(_);
      +current_mission(Id).

+mm::mission_state(Id,S) 
   <- .print("Mission ",Id," state is ",S).

/* These plans were previously on the Auto Pilot*/
//+!mm::run_plan(CM,L)[source(Ag)] // Should I add source(self) for security?

// run_plan for mission say_hi
+!mm::run_plan(CM,L) // CM -> Current Mission name | L -> List of steps
   :  CM == say_hi
      & num_printed(N)
   <- -+current_mission(CM);
      -mission_plan(CM,_);
      +mission_plan(CM,L);

      !print_this(L) // L must contain a list of characters to print
      .

+!print_this(Charas) // Plan for print type of mission
   :  .length(Charas,N)
      & not (N == 0)
      & current_mission(CM)
   <- .print("Running plan for ", CM, ", next steps: ", Charas);
      .nth(0,Charas,SingleChara);
      .print(SingleChara);
      .wait(1000);
      
      // Feedback signal
      -+num_printed(N+1);

      .delete(0,Charas,RemCharas);
      // Iterate until empty
      !print_this(RemCharas).

+!print_this(L). // When L is empty does nothing



+num_printed(N)   // Feedback to indicate action was completed
   :  current_mission(CM) // Add CM == say_hi????
      & not (N == 0)
   <- -progress(CM,_);
      +progress(CM,N);
      .signal({+update_rem_plan(N,0)}).


+progress(CM,N) 
   :  not mission_loop(CM) 
      & mission_plan(CM,Plan) // unifies Plan with the original list of steps of CM,
      & .length(Plan,N)  // verifies if N matches with the length of Plan
   <- -progress(CM,_);
      +progress(CM,0);
      .print("Mission Finished");
      .signal({+finished}). // Signals it finished the mission (-> MM Library)

+!mm::stop_mission : current_mission(CM)
   <- -current_mission(_); // This is handled by the MM Library!
      .print("Mission ",CM," was stopped!").


//{ include("$jacamo/templates/common-cartago.asl") }
//{ include("$jacamo/templates/common-moise.asl") }
//{ include("$moise/asl/org-obedient.asl") }
