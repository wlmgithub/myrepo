<?php
class Zend_View_Helper_EnvList 
{
	public function setView(Zend_View_Interface $view)
	{
		$this->view = $view;
	}
	public function envList($selected) {
		
		$envList = $this->view->env;
		$listhtml = '<select name="env" class="required" id="env"><option value="">Environment</option>';
		foreach ($envList as $env)  {
			$text;
			if ($env->env_name == $selected) {
				$text = 'selected="true"';
			}else {
				$text = "";
			}
			$listhtml .= "<option " . $text . " value='" . $env->env_name . "'>" . $env->env_name . " - " . $env->env_desc . "</option>";
		}
		$listhtml.= "</select>";
		return $listhtml;
	}
}
	
	
