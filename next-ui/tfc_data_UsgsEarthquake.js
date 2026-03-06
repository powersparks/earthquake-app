var tfc_data_UsgsEarthquake = function () {
                //https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson&starttime=2014-01-01&endtime=2014-01-02&callback=test
                //https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson&starttime=2014-01-01&endtime=2014-01-02&callback=quake558755&_=1481418159231
         var _baseUrl = "https://earthquake.usgs.gov/fdsnws/event/1/query",
        x3rand = Math.floor(Math.random() * 1000 + 0),
        y3rand = Math.floor(Math.random() * 1000 + 0),
        callbackname = "quake" + x3rand + y3rand,
        startDateTime = "2014-01-01",
        endDateTime =  "2014-01-02";
                function quakeResult(callback, startDate, endDate) { 
                    $.ajax({
                        url: _baseUrl,
                        dataType: "jsonp",
                        jsonpCallback: callbackname,
                        data: {
                            format: "geojson",
                            starttime: startDate ? startDate : startDateTime,
                            endtime: endDate ? endDate : endDateTime
                        },
                        dataType: 'jsonp',
                        cache: true,
                        success: function (response) {

                            if (typeof callback !== 'undefined' && typeof callback === 'function') {
                                callback(response);
                            }

                        },
                        error: function (state, status, message) {
                            console.error("fail: ");
                            console.error(state);
                            console.error(status);
                            console.error(message);
                        }
                    });
                };
                return quakeResult;
        };