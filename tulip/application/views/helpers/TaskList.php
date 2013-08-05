<?php
class Zend_View_Helper_TaskList 
{
	public function setView(Zend_View_Interface $view)
	{
		$this->view = $view;
	}
	public function taskList($selected) {
		
		$taskList = $this->view->task;
		$listhtml = '<select name="task[]"><option value="">Select Task</option>';
		$s = "";
		foreach ($taskList as $task)  {
			if ($task->task == $selected){
				$s = "selected";
			}else {
				$s = "";
			}
			$listhtml .= "<option " . $s ." value='" . $task->task . "'>" . $task->task .  "</option>";
		}
		$listhtml.= "</select>";
		return $listhtml;
	}
}

	
	
