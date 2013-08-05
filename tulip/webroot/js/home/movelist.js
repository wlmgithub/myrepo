$(document).ready(function() {
	  $("#component_name").each(function(){
	            $("#component_name option").attr("selected","selected"); }
	  		);
	 $("#create_form").validate({
	  errorPlacement: function(error, element) {
			error.appendTo( element.parent());
		},
		// specifying a submitHandler prevents the default submit, good for the demo
		submitHandler: function(form) {
			$('#release_vehicle_id').val('R' + $('#id1').val() + '-' + $('#type option:selected').val() + '-' + $('#env option:selected').val() + '-RC-' + $('#id2').val() +  $('#id3').text());
			form.submit();
		}
	 
	 
	 });

                        // sorts all the combo select boxes
                        function sortBoxes(){
                                $('#firstSelect, #component_name').find('option').selso({
                                        type: 'alpha', 
                                        extract: function(o){ return $(o).text(); } 
                                });

                                // clear all highlighted items
                                $('#firstSelect, #component_name').find('option:selected').removeAttr('selected');
                        }

	$('#movefront').click(function () { 
	  //var selected = $('#firstSelect option:selected').val();
	  $('#firstSelect option:selected').appendTo('#component_name'); 
	 /* $("#component_name").each(function(){
	  	$("#component_name option").removeAttr("selected"); 
	  }); */
	  $('#firstSelect option:selected').remove();

			sortBoxes();
	  return false; 
	}); 
	
	$('#moveback').click(function () { 
	  $('#component_name option:selected').appendTo('#firstSelect'); 
	  $('#component_name option:selected').remove();
			sortBoxes();
	  return false; 
	}); 
	$('#env').change(function () { 
	  $('#env_text').html('-' + $('#env option:selected').val() + '-');
	  return false; 
	}); 
	$('#type').change(function () { 
	  $('#type_text').html('-' + $('#type option:selected').val());
	  return false; 
	}); 	
	/*$('#create_form').submit(function (e) { 
		 $("#component_name").each(function(){
	            $("#component_name option").attr("selected","selected"); }
	  	);
		$('#release_vehicle_id').val('R' + $('#id1').val() + '-' + $('#env option:selected').val() + '-RC-' + $('#id2').val() +  $('#id3').text());
		return true;
	});*/
 });
