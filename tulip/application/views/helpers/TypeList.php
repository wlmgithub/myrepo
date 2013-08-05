<?php
class Zend_View_Helper_TypeList 
{
	public function setView(Zend_View_Interface $view)
	{
		$this->view = $view;
	}
	public function typeList($selected) {
		
		$typeList = $this->view->type;
		$listhtml = '<select name="type" class="required" id="type"><option value="">Release Type</option>';
		foreach ($typeList as $type)  {
			$text;
			if ($type->type_name == $selected) {
				$text = 'selected="true"';
			}else {
				$text = "";
			}
			$listhtml .= "<option " . $text . " value='" . $type->type_name . "'>" . $type->type_name . " - " . $type->type_desc . "</option>";
		}
		$listhtml.= "</select>";
		return $listhtml;
	}
}
	
	
