 var index = 0;
 $(document).ready(function() {
 	$('#invisible').hide();
	$('.add').bind("click",addrow);
	$('.delete').bind("click",deleterow);
	$("#show_multiple_0").multiSelect({ oneOrMoreSelected: '*' });
	$(".current_comp").multiSelect({ oneOrMoreSelected: '*' });
	$('#plan').submit(function (e) {
		
		swapValues = [];
		var valid = 1;
		var seq = 1;
		$("tr:not(#invisible) input.step").each(function(i){
			var current = $("tr:not(#invisible) input.step").eq(i).val();
			var previous = $("tr:not(#invisible) input.step").eq(i-1).val();
			if (parseInt(current, 10) < parseInt(previous, 10) ){
		  		seq = 0;
		  	}
		  	if (isUnsignedInteger($(this).val()) == 0 ){
		  		valid = 0;
		  	}
		});
		if ((valid==1) && (seq==1)){
			$('#invisible').remove();
			return true;
		}else {
			alert("Please Enter Integer values in sequential order for steps.")
			return false;
		}
	});
	
	/*$('#plan').submit(function (e) {
		$('#invisible').remove();
		return true;
	}); */

 });
function addrow(e) {
	var currentRow = $("table#dataentry tr:last");
	var newRow = $('#invisible').clone();
	newRow.attr('id', "" );
	currentRow.after(newRow);
	newRow.show();
	newRow.highlightFade({
		speed:3000,
		color:"#DDF0F8"
	});
	$('.delete').bind("click",deleterow);
	index++;
	var element = newRow.find("#show_multiple_0");
	element.attr('id',"show_multiple" + index);
	$("#show_multiple" + index).multiSelect({ oneOrMoreSelected: '*' });
	return false;
}
function deleterow(e) {
	var currentRow = $(this).parent().parent();
	currentRow.remove();
	// prevent the default click
	return false;
}
function isUnsignedInteger(s) {
	return (s.toString().search(/^[0-9]+$/) == 0);
}

/*
<script type="text/javascript">
 $(document).ready(function() {
 	$('#invisible').hide();
	$('.add').bind("click",addrow);
	$('.delete').bind("click",deleterow);
	$(".current_comp").multiSelect({ oneOrMoreSelected: '*' });
	var index=0;
	function addrow(e) {
		var currentRow = $("table#dataentry tr:last");
		var newRow = $('#invisible').clone();
		newRow.attr('id', "" );
		currentRow.after(newRow);
		newRow.show();
		newRow.highlightFade({
			speed:3000,
			color:"#DFEDCB"
		});
		$('.delete').bind("click",deleterow);
		index++;
		var element = newRow.find("#show_multiple_0");
		element.attr('id',"show_multiple" + index);
		$("#show_multiple" + index).multiSelect({ oneOrMoreSelected: '*' });
		return false;
	}
	function deleterow(e) {
		var currentRow = $(this).parent().parent();
		currentRow.remove();
		// prevent the default click
		return false;
	}
	$('#plan').submit(function (e) {
		$('#invisible').remove();
		return true;
	});

 });

</script>
*/

