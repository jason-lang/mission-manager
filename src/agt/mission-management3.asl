+!create_mission(Id,ExpEnergy, Args) 
   <- +mission_energy(Id,ExpEnergy,0);
      if ( .member(drop_when_interrupted, Args)) { //checks if drop_when_interrupted is in Args 
        +mission_drop_when_interrupted(Id);
      }
      if ( .member(loop, Args)) {   //checks if loop is in Args | there are no loop on Args for any mission on uav.asl...?
        +default::mission_loop(Id); // Test if ok?
      }      
   .

// @[atomic] plans cannot be interrupted!
// If run_mission(Id) goal is added, but the Id of the mission is the same as the current mission being executed, then does nothing (avoids error message)
@[atomic] +!run_mission(Id) : current_mission(Id). 
@[atomic] +!run_mission(Id)  // If there is no current mission but a suspended mission exists
   :  not current_mission(_) & 
      mission_state(Id,suspended) & // !!
      mission_step(Id,Step) &
      mission_plan(Id,Plan)  
      //my_ap(AP) 
   <- .delete(0,Step,Plan,RemPlan); // deletes 0-Step (number) of elements from Plan (list), result is unified in RemPlan 
      .print("[MM] Resuming ",Plan,", remaining plan is ",RemPlan," (",Step,"/",.length(Plan),")"); 
      +current_mission(Id);
      !change_state(Id,running);
      //.send(AP,achieve,run_plan(Id,RemPlan)). 
      !run_plan(Id,RemPlan). /* A +!mm::run_plan(_,_) should be added to the agent!!!! */
@[atomic] +!run_mission(Id) // If there is no current mission
   :  not current_mission(_) & 
      mission_plan(Id,Plan) 
      //my_ap(AP) 
   <- .print("[MM] Mission ", Id, " has started with plan: ", Plan);
      +current_mission(Id);
      !change_state(Id,running);
      //.send(AP,achieve,run_plan(Id,Plan)).
      !run_plan(Id,Plan). 
@[atomic] +!run_mission(Id)  // If there's a current mission, then drops it or else suspends it
   :  current_mission(CMission) & 
      CMission \== Id  
      //my_ap(AP)
   <- //.send(AP,achieve,stop_mission);
      !stop_mission; /* A +!mm::stop_mission should be added to the agent!!!! */
      -current_mission(CMission);
      /* This will most likely have to be altered to deal with priority and critical missions */
      if (mission_drop_when_interrupted(CMission)) {
         !change_state(CMission,dropped); // Keeps track of which mission was dropped too?
         .print("[MM] Mission ",CMission," was dropped!");
      } else {
         !change_state(CMission,suspended);
         .print("[MM] Mission ",CMission," was suspended!");
      }
      !run_mission(Id).

@[atomic] +!stop_mission(Id,R)
   :  current_mission(Id)  
      //my_ap(AP)
   <- //.send(AP,achieve,stop_mission); 
      !stop_mission; 
      -current_mission(Id);
      !change_state(Id,stopped[reason(R)]);
      !auto_resume. // resume some other suspended mission if it exists

@[atomic] +!drop_mission(Id,R) // What is the difference between dropped and stopped???
   :  current_mission(Id)  
      //my_ap(AP)
   <- //.send(AP,achieve,stop_mission); 
      !stop_mission; 
      -current_mission(Id);
      !change_state(Id,dropped[reason(R)]);
      !auto_resume.

@[atomic] +!stop_mission(Id,R)
   <- !auto_resume.

+!start_mission(Id) // What is the purpose of this plan??? It is never triggered...
   :  enough_energy(Id) &
      mission_plan(Id,Plan)  
      //my_ap(AP)
   <- //.send(AP,achieve,run_plan(Id,Plan)).
      !run_plan(Id,Plan).

+default::finished // default name space of the agent!  
   <- -current_mission(Id);
      !change_state(Id,finished);
      !auto_resume.

+default::update_rem_plan(Step,Energy) // Why is this not a plan???
   :  current_mission(Mission) & 
      mission_energy(Mission,EE,US) 
   <- //.print("Updating ",Mission,", step #", Step);
      -mission_step(Mission,_);
      +mission_step(Mission,Step);
      -mission_energy(Mission,EE,US);
      +mission_energy(Mission,EE,US+Energy).

+!auto_resume // for when mission is stopped, dropped or finished
   :  not current_mission(_) & // Isn't this verification pointless? This goal is only added if there is no current mission
      mission_state(Mission,suspended) & // What happens if there are multiple mission_state(Mission,suspended) beliefs? -> 1st oldest
      enough_energy(Mission)
   <- !run_mission(Mission).
+!auto_resume. // if no mission_state(Mission,suspended) then does nothing
   /* Missing something here, in case there's no suspended mission*/
   // <- Go_home. or another default mission

+!change_state(Mission, State) // drop prev mission_state belief and replace with updated State
   <- -mission_state(Mission, _);
      +mission_state(Mission, State).


+!default::update_energy(E)
   <- -+available_energy(E).
      
available_energy(100000000). 

enough_energy(RE)      :- .number(RE) & available_energy(A) & A > RE.
enough_energy(Mission) :- mission_energy(Mission,EE,US) & available_energy(A) & A > (EE-US).

+available_energy(_)    <- !test_enough_energy.
+mission_energy(Mission,EE,US) <- !test_enough_energy.

+!test_enough_energy
    : current_mission(Mission) & 
      mission_energy(Mission,EE,US) & 
      Rem = math.max(0,EE-US) &
      not enough_energy(Rem)
   <- ?available_energy(A);
      !!stop_mission(Mission,lack_of_energy(required(Rem),available(A))). 
+!test_enough_energy.

// This is not necessary since this is just a transmission of the uav agent
/*+mission_loop(Id)
   : my_ap(AP) 
   <- .send(AP,tell,mission_loop(Id)). */