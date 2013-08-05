<?php
class Zend_View_Helper_WorkflowList
{
	public function setView(Zend_View_Interface $view)
	{
		$this->view = $view;
	}
	public function workflowList() {

		$all = $this->view->allWorkflow;
		$listhtml = "";

		if ( count($all) )  {
			
//			$listhtml .= "<table id='myTable' class='tablesorter'><thead><tr>";
//			$listhtml .= "<th>Release Name</th><th>Step Name</th><th>Status</th><th>Notes</th><th style='width:15%;'>Created</th><th style='width:15%;'>Owner</th></tr></thead><tbody> ";
			$listhtml .= "<table border='1'> <thead><tr>";
			$listhtml .= "<th>Release Name</th><th>Step Name</th><th>Status</th><th>Notes</th><th>Created</th><th>Owner</th></tr></thead><tbody> ";

			foreach ($all as $workflow) {
				$listhtml .= "<tr>";
				$listhtml .= "<td>" . $workflow->releasename . "</td><td>" . $workflow->stepname . "</td><td>" .  $workflow->status .  "</td><td>" . $workflow->notes . "</td><td>" . $workflow->created . "</td><td>" .  $workflow->username . "</td></tr>" ;
			}
	
			$listhtml .= "</tbody></table>";

		} else {
			$listhtml .= "No Results Found";
  		}


/*

foreach ($all as $workflow) {
  $listhtml .= $workflow->releasename ;
  $listhtml .= $workflow->stepname ;
  $listhtml .= $workflow->status ;
  $listhtml .= $workflow->notes ;
  $listhtml .= $workflow->created ;
  $listhtml .= $workflow->username ;
}

*/

return $listhtml;

	}	
}
