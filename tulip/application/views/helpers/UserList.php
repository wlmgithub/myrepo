<?php
class Zend_View_Helper_UserList 
{
	public function setView(Zend_View_Interface $view)
	{
		$this->view = $view;
	}
	public function userList($selected) {
		
		$userList = $this->view->user;
		$listhtml = '<select name="owner[]" ><option value="">Select Owner</option>';
		foreach ($userList as $user)  {
			if ($user->user_name == $selected){
				$s = "selected";
			}else {
				$s = "";
			}
			$listhtml .= "<option ". $s . " value='" . $user->user_name . "'>" . $user->user_name .  "</option>";
		}
		$listhtml.= "</select>";
		return $listhtml;
	}
}
	
	
