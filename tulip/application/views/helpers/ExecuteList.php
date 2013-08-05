<?php
require_once('models/Task.php');
class Zend_View_Helper_ExecuteList
{
	public function setView(Zend_View_Interface $view)
	{
		$this->view = $view;
	}
	public function executeList() {
		$plan = $this->view->plan;
		$listhtml = "";
		$disabled = "";
		if (count($plan)){
			// lwang: per Noy, added "edit" link here
			// -- BEGIN --
			if ($rollout->executed != 2) {
				$edit =  "<a href='" . $this->view->urlHome . "/index/editpage?id=" . $this->view->id . "'> Edit</a>&nbsp";
			}else {
				$edit="";
			}
			$listhtml .= "$edit";
			// -- END --

			// lwang: per Baski, make release vehicle prominent here
			$listhtml .= '<div style="text-align:center;padding:10px;font-size:12px;">Release Vehicle ID: &nbsp; <b>' . $this->view->id . '</b> </div>';

			$listhtml .= "<table id='dataentry'><thead><tr><th>Step</th><th>Sub Step</th><th>Task</th><th>Owner</th><th>Status</th><th>Notes</th><th>Action</th></tr></thead><tbody> ";

			// get components in the plan
			$components_array = array();
			// $components_count holds the number of components deployed in the release vehicle   
			$components_count = 0;
			for ($i=0; $i < count($plan); $i++) {
				$html = "";
				// lwang: per Punsri, the logic is changed to: always show button for each step
				$showbutton =0;
				//$showbutton = 1;
				$log="";
				//STATUS
				// completed step
				if ($plan[$i][status] == 2){
					$status = "Completed";
				// in progress
				}else if ($plan[$i][status] == 1){
					$status = "In Progress";
				}else {
					$status="Not Started";
				}
				if ($plan[$i][task] == "audit" || $plan[$i][task] == "deploy"){
					if ($plan[$i][status]){
						// if task is "audit", show showAudit link
					                $items = preg_split("/-/", $this->view->id);
							if ( count($items) == 6 ) {
					                  $env = $items[2];
							} else {
					                  $env = $items[1];
							}
						if ( $plan[$i][task] == "audit" ) {
// http://rotozip.corp.foobar.com/cgi-bin/lwang/showAudit.pl?env=ech3&release=928Step5
							$log="<a href='http://rotozip.corp.foobar.com/cgi-bin/lwang/showAudit.pl?env=" . $env . "&release=" . $this->view->id . "' target='_blank'>View Log</a>";
						// if task is "deploy", show manual audit instruction, if plan step ownder is login user or login user is admin
						} else if ( $plan[$i][task] == "deploy"  ) {

// https://sandbox01.corp.foobar.com/cgi-bin/lwang/tulip/showManualCheckInstruction.pl?release=R940-MR-ech3-RC-6-21&step=1&owner=krana
							if ( $plan[$i][owner] == $this->view->username || $this->view->is_admin ) {
								$log="<a href='https://sandbox01.corp.foobar.com/cgi-bin/lwang/tulip/showManualCheckInstruction.pl?release=" .  $this->view->id . "&step=" . $plan[$i][step] . "&owner=" . $plan[$i][owner] .  "' target='_blank'> Step Check </a>";
								$log .= "<br />";
							}

// feature creep:  step audit needs to be viewable by everyone
							$log .="<a href='http://rotozip.corp.foobar.com/cgi-bin/lwang/showAudit.pl?env=" . $env . "&release=" .  $this->view->id . "-step-" . $plan[$i][step] . "' target='_blank'> View Step Audit Log </a>";

						// otherwise, show no link
						} else {
							$log="<a href=''>   </a>";
						}

					}
					
				}
				//ACTION
				// lwang: only allow owner of action or admin to view action buttons
/*
echo "plan owner (plan step owner): " . $plan[$i][owner] . "<br/>";
echo "this username (the login user): " . $this->view->username. "<br/>";
echo "this head (plan creator): " . $this->view->head. "<br/>";
echo "this is_admin: " . $this->view->is_admin . "<br/>";
*/

				if ($plan[$i][owner]  == $this->view->username || $this->view->head == $this->view->username || $this->view->is_admin ) {
					$showbutton=1;
				}else {
					//you are not the owner of this step
				}

				if ($plan[$i][status] != 2) {
/*
							if ( ( $plan[$i][step] != $plan[$i-1][step] || $plan[$i][sub_step] == $plan[$i-1][sub_step] ) && $plan[$i-1][status] != 2){
								$status="Can't start this step because previous step is not completed";
							}else {
								$showbutton=1;
							}
*/
/*
					// owner of this step
					if ($plan[$i][owner]  == $this->view->username || $this->view->head == $this->view->username) {
						if ($i==0){
							$showbutton=1;
						}else {
							if ($plan[$i-1][status] != 2){
								$status="Can't start this step because previous step is not completed";
							}else {
								$showbutton=1;
							}
						}
					}else {
						//you are not the owner of this step
					}
*/
				}
				//$backend_required = Model_Task::getBackend($plan[$i][task]);
				if ($showbutton){
					$text;
					if ($plan[$i][status] == 0) {
						$text ="Start";
					}elseif ($plan[$i][status] == 1){
						$text="Complete";
					}

// per Noy, let's not go to a separate page... rather refresh the execute page
// 	the logic is in otherAction in IndexController
					$html .= "<form method='post' action='". $this->view->urlHome . "/index/other" . "' type='submit' value='submit' >";
					$html .= "<input type='hidden' name='id' value='" . $plan[$i][id]  . "' />";
					$html .= "<input type='hidden' name='release_vehicle_id' value='" . $this->view->id  . "' />";
					$html .= "<input type='hidden' name='components' value='" . $plan[$i][components]  . "' />";
					$html .= "<input type='hidden' name='owner' value='" . $plan[$i][owner]  . "' />";
					$html .= "<input type='hidden' name='task' value='" . $plan[$i][task]  . "' />";
					$html .= "<input type='hidden' name='actiondone' value='" . $text  . "' />";
					$html .= "<input type='hidden' name='form_submitted' value='1' />";
					$html .= "<input class='submit' type='submit' value='".$text."' />";
					$html .= "</form>";
				}
				
				// eye candy for Noy
				$mytr = "";
				if ( $plan[$i][step] % 2 ) {
				  $mytr = '<tr bgcolor="#FFFFFF">';
				} else {
				  $mytr = '<tr bgcolor="#CCFFCC">';
				}

				// we want to present the components one per line 
				// and get the count of components too
				$components_presented =  preg_replace( "/,/", "<br />", $plan[$i][components]) ;
				$components_array_i =  explode( ", ",  $plan[$i][components]) ;
				$components_count_i = count($components_array_i);

				if ( $status == 'Completed' ) { # no need to show button if status is "Completed"
#					$listhtml .= $mytr . "<td>".$plan[$i][step] . "</td><td>" . $plan[$i][sub_step] . "</td><td>" . "<b>" . $plan[$i][task] . "</b>" . "<br /><br/>" . $components_presented . "</td><td>" . $plan[$i][owner] . "</td><td>". "<b>" . $status . "</b>" . "<br/>". $log ."</td><td>". htmlspecialchars($plan[$i][notes]) . "</td><td>" . " " . "</td></tr>";
					$listhtml .= $mytr . "<td>".$plan[$i][step] . "</td><td>" . $plan[$i][sub_step] . "</td><td>" . "<b>" . $plan[$i][task] . "</b>" . "<br /><br/>" . $components_presented . "</td><td>" . $plan[$i][owner] . "</td><td>". "<b>" . $status . "</b>" . "<br/>". $log ."</td><td>". $plan[$i][notes] . "</td><td>" . " " . "</td></tr>";
				} 
				else {
#					$listhtml .= $mytr . "<td>".$plan[$i][step] . "</td><td>" . $plan[$i][sub_step] . "</td><td>" . "<b>" . $plan[$i][task] . "</b>" . "<br /><br/>" . $components_presented  . "</td><td>" . $plan[$i][owner] . "</td><td>". "<b>" . $status . "</b>" . "<br/>". $log ."</td><td>". htmlspecialchars($plan[$i][notes]) . "</td><td>" . $html . "</td></tr>";
					$listhtml .= $mytr . "<td>".$plan[$i][step] . "</td><td>" . $plan[$i][sub_step] . "</td><td>" . "<b>" . $plan[$i][task] . "</b>" . "<br /><br/>" . $components_presented  . "</td><td>" . $plan[$i][owner] . "</td><td>". "<b>" . $status . "</b>" . "<br/>". $log ."</td><td>". $plan[$i][notes] . "</td><td>" . $html . "</td></tr>";
				}				

				// only count toward the final count if task is 'deploy'
				if ( $plan[$i][task] == 'deploy' ) {
					$components_count = $components_count + $components_count_i;
					foreach ( $components_array_i as $c ) {
						array_push( $components_array, $c );
					} 
//				array_push( $components_array, $components_array_i );
//				 $components_array =  $components_array_i ;
				}

			}
			$listhtml .= "</tbody></table>";


		} else {
		   $listhtml .= "No Results Found";
		}

		// deployment stats display.... restricted to admin for now
		if ( $this->view->is_admin ) {
//		$listhtml .= "<br /> Components count: " . $components_count;
//		$listhtml .= " | ";
		$listhtml .= " <br /> ";
		$listhtml .= " Components diff: <a href='http://sandbox01.corp.foobar.com/cgi-bin/lwang/tulip/showComponentsDiff.pl?release=" . $this->view->id . "' target='_blank'> details</a>";
		$listhtml .= " <br /> ";
		$listhtml .= " Deployments count: <a href='http://rotozip.corp.foobar.com/cgi-bin/lwang/countDeployments.pl?release=" . $this->view->id . "' target='_blank'> details</a>";

		$listhtml .= "<br />";
		$listhtml .= "<br />Components (" .  $components_count . ")  (you can cut-and-paste them into a file for auditing purpose):<br /><br /> ";
  			foreach ( $components_array as $c ) {
  				$listhtml .=   $c . "<br />";
  			}
		}

//		$listhtml .= '<meta http-equiv="refresh" content="5; url= '; 
//		$thispageurl = " $this->view->urlHome . "/index/execute?id=" . $this->view->id";
//		$listhtml .= " $thispageurl  \" >";
		$listhtml .= ' <meta http-equiv="refresh" content="60; url=' . $this->view->urlHome .  '/index/execute?id=' . $this->view->id . '">';
		return $listhtml;
	}
	
}

