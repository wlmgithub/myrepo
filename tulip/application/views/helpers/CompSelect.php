<?php
class Zend_View_Helper_CompSelect
{
	public function setView(Zend_View_Interface $view)
	{
		$this->view = $view;
	}
	public function compSelect($class, $components_selected) {
		
		$components = $this->view->components;
		asort($components);

                // sort comps
                $sorted_components = array();
                foreach ($components as $comp) {
                        array_push( $sorted_components, $comp->component_name );
                }
                asort( $sorted_components );
		$uniq_sorted_components = array_unique($sorted_components);

		$dbpatches = $this->view->dbpatches;
		$selected = explode(", ",$components_selected);
		
		$value ="";
		$db_value = "";
		$listhtml = '<select id="show_multiple_0"   multiple="multiple" class="'. $class .'" >';
/*
		foreach ($components as $component)  {
			if (in_array($component->component_name,$selected) ){
				$value="selected";
			}else {
				$value="";
			}
			$listhtml .= "<option ". $value . " value='" . $component->component_name . "'>" . $component->component_name .  "</option>";
		}
*/
                foreach ($uniq_sorted_components  as $component)  {
                        if (in_array($component,$selected) ){
                                $value="selected";
                        }else {
                                $value="";
                        }
                        $listhtml .= "<option ". $value . " value='" . $component . "'>" . $component .  "</option>";
                }
		foreach ( $dbpatches as $patch) {
			if (in_array($patch->db_patch,$selected) ){
				$value="selected";
			}else {
				$value="";
			}
			$listhtml .= "<option ". $value . " value='" . $patch->db_patch . "'>" . $patch->db_patch .  "</option>";
		}
		$listhtml.= "</select>";
		return $listhtml;
	}
}
	
	
