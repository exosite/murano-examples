$(function() {

		//REPLACE DEVICE UNIQUE IDENTIFIER / SERIAL NUMBER HERE
		var myDevice = 'FDA28A7FCF5C';

		//REPLACE WITH FULL APP DOMAIN IF RUNNING LOCALLY, OTHEWISE LEAVE AS "/"
    var app_domain = '/';

		var data = [];
		var updateInterval = 1000;
		var red_color = '#990033';

    var graph_options = {
        series: {
            lines: { show: true, lineWidth: 1.5, fill: 0.1},
            points: { show: true, radius: 0.7, fillColor: "#41C4DC" }
        },
				legend: {
					position: "nw",
					backgroundColor: "#66666",
					backgroundOpacity: 0.7
				},
        yaxis: {
          min: 0,
          max: 100
        },
        xaxis: {
          mode: "time",
					timeformat: "%I:%M %p"
        },
        colors: ["#41C4DC","#FF5847","#FFC647", "#5D409C", "#BF427B","#D5E04D" ]
		};

    $("#appstatus").text('Running');
    $("#appstatus").css('color', 'green');
    $("#appconsole").text('starting...');
    $("#appconsole").css('color', '#555555');
		$("#specificdevice").append(myDevice);

    function fetchData() {
				console.log('fetching data from Murano');
        $("#appconsole").text('Fetching Data From Server...');

        function onDataReceived(newdata) {
          $("#appstatus").text('Running');
          $("#appstatus").css('color', 'green');
          $("#appconsole").text('Processing Data');
          var data_to_plot = [];
					// Load all the data in one pass; if we only got partial
					// data we could merge it with what we already have.
          //console.log(series)
          for (j = 0; j < newdata.timeseries.results[0].series.length; j++)
          {
					  var data = newdata.timeseries.results[0].series[j].values;
            var friendly = newdata.timeseries.results[0].series[j].name;
            var units = "";
						var last_val = newdata.timeseries.results[0].series[j].values[data.length-1][1];
            if (friendly == "temperature")
            {
              units = "F";
							friendly = "Temperature";
            }
            else if (friendly == "humidity")
            {
              units = "%";
							friendly = "Humidity";
            }
            data_to_plot.push({
                  label: friendly + ' - '+ last_val + units,
                  data: data,
                  units: "F"
              });
          }
					$.plot("#placeholder", data_to_plot, graph_options);
          setTimeout(fetchData, updateInterval);
          $("#appconsole").text('waiting');
				}

        function onError( jqXHR, textStatus, errorThrown) {
          console.log('error: ' + textStatus + ',' + errorThrown);
          $("#appconsole").text('No Server Response');
          $("#appstatus").text('Server Offline');
          $("#appstatus").css('color', red_color);
          setTimeout(fetchData, updateInterval+3000);
        }

				$.ajax({
					url: app_domain+"admin/lightbulb/"+myDevice,
					type: "GET",
					dataType: "json",
					success: onDataReceived,
          crossDomain: true,
          error: onError,
          statusCode: {
            504: function() {
              console.log( "server not responding" );
              $("#appstatus").text('Server Not Responding 504');
              $("#appstatus").css('color', red_color);
            }
          }
          ,timeout: 10000
        });

			}


		// Set up the control widget

		$("#updateInterval").val(updateInterval).change(function () {
			var v = $(this).val();
			if (v && !isNaN(+v)) {
				updateInterval = +v;
				if (updateInterval < 1) {
					updateInterval = 1;
				} else if (updateInterval > 20000) {
					updateInterval = 20000;
				}
				$(this).val("" + updateInterval);
			}
		});

		fetchData();

		$("#footer").prepend("Exosite Murano Example");
	});
