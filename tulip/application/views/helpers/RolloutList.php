<?php
class Zend_View_Helper_RolloutList
{
	public function setView(Zend_View_Interface $view)
	{
		$this->view = $view;
	}
	public function rolloutList() {
		$all = $this->view->allRollOuts;
		$listhtml = "";
		$edit;
		if (count($all)){
			
			$listhtml .= "<table id='myTable' class='tablesorter'><thead><tr>";
			if ($this->view->value == 1) {
				$listhtml .=  "<th style='width:15%;'>Action</th>";
			}
			$listhtml .= "<th>Release Vehicle ID</th><th style='width:15%;'>Created</th><th style='width:15%;'>Owner</th></tr></thead><tbody> ";

			foreach ($all as $rollout)  {
				$listhtml .= "<tr>";
				if ($this->view->value == 1) {
					if ($rollout->executed != 2) {
						$edit =  "<a href='" . $this->view->urlHome . "/index/editpage?id=" . $rollout->release_vehicle_id . "'>edit</a>&nbsp;|&nbsp;";
					}else {
						$edit="";
					}
					$listhtml .=  "<td>".$edit. "<a href='" . $this->view->urlHome . "/index/copypage?id=" . $rollout->release_vehicle_id . "'>copy</a>&nbsp;|&nbsp;"  . "<a  href='" . $this->view->urlHome . "/index/execute?id=" . $rollout->release_vehicle_id . "'>execute</a>"."</td>";
				}
				$listhtml .= "<td><a href ='" . $this->view->urlHome . "/index/execute?id=" . $rollout->release_vehicle_id . "' >" . $rollout->release_vehicle_id . "</a>" .  "</td><td>" .  $rollout->created . "</td><td>" .  $rollout->username . "</td></tr>";
					
			}
			$listhtml .= "</tbody></table>";
		} else {
		   $listhtml .= "No Results Found";
		}
		return $listhtml;
	}
	
}