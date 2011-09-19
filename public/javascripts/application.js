// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
var TogglePane = {
    toggleStatus: function(id){        
        $("thead tr th#header_"+ id).toggle()
        $("tbody tr td#td_" + id).toggle();
    }
}