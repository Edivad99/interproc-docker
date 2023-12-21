window.onload = function () {
    var select = document.getElementById("example_lbl");
    var prevSelectedIndex = select.options.selectedIndex;
    var textarea = document.getElementById("program_area");

    function changeProgram(path) {
        fetch(path)
            .then(function (response) {
                if (response.status !== 200) {
                    console.log("Error", response.status);
                    return;
                }
                response.text()
                    .then(function (text) { textarea.value = text.trim(); })
                    .catch(function (error) { console.error(error); })
            })
            .catch(function (error) { console.error(error); });
    }

    select.addEventListener('change', function (event) {
        var selectedIndex = event.target.options.selectedIndex;
        var fileOption = select.options[selectedIndex];
        var option = fileOption.value;
    
        if (option != "none") {
            if (textarea.value !== "" && prevSelectedIndex === 0) {
                if (confirm("Delete existing user-supplied program?")) {
                    changeProgram(option);
                }
            }
            else {
                changeProgram(option);
            }
        }
        prevSelectedIndex = selectedIndex;
    });
    
    textarea.addEventListener('input', function (event) {
        if (select.options.selectedIndex !== 0) {
            select.options.selectedIndex = prevSelectedIndex = 0;
        }
    });
};
