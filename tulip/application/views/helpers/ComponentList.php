<?php
class Zend_View_Helper_ComponentList 
{
	public function setView(Zend_View_Interface $view)
	{
		$this->view = $view;
	}
	public function componentList() {
		
		$componentList = $this->view->component;
		$listhtml = '<select size="20" multiple="multiple" style="width:200px;" id="firstSelect">';
		foreach ($componentList as $component)  {
			$listhtml .= "<option value='" . $component->app_name . "'>" . $component->app_name .  "</option>";
		}
		$listhtml.= "</select>";
		return $listhtml;
	}
}
	
	
