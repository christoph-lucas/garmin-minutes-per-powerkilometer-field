using Toybox.WatchUi;
using Toybox.FitContributor as Fit;
using Toybox.Activity;

class LeistungskilometerDataFieldView extends WatchUi.SimpleDataField {

    enum {
    	AVG_PKM,
    	CUR_PKM,
    	TOTAL_PKM
    }

    const AVERAGE_MIN_PER_PKM_FIELD_ID = 0;
    const CURRENT_MIN_PER_PKM_FIELD_ID = 2;
    const TOTAL_PKM_FIELD_ID = 1;
    
    hidden var displayValueType = AVG_PKM;
    hidden var alpha = 0.9;
    hidden var maxMinPerPkm = 15.0;
    
    hidden var averageMinPerPkmField = null;
    hidden var currentMinPerPkmField = null;
    hidden var totalPkmField = null;
    
    hidden var lastDisplayValue = 0.0;
    
    hidden var lastCurrentMinutesPerPkm = null;
    hidden var lastTotalPkm = 0.0;
    hidden var lastTotalTimeInMs = 0;

    // Set the label of the data field here.
    function initialize() {
        SimpleDataField.initialize();
        loadProperties();
        // TODO depends on setting
        label = WatchUi.loadResource(Rez.Strings.minPerPkmUnit);
        
		averageMinPerPkmField = createField(
            WatchUi.loadResource(Rez.Strings.avgMinPerPkmLong),
            AVERAGE_MIN_PER_PKM_FIELD_ID,
            Fit.DATA_TYPE_STRING,
            {:mesgType=>Fit.MESG_TYPE_SESSION, :units=>WatchUi.loadResource(Rez.Strings.minPerPkmUnit), :count=>16}
        );
        averageMinPerPkmField.setData(displayTime(0.0));

		currentMinPerPkmField = createField(
            WatchUi.loadResource(Rez.Strings.curMinPerPkmLong),
            CURRENT_MIN_PER_PKM_FIELD_ID,
            Fit.DATA_TYPE_FLOAT,
            {:mesgType=>Fit.MESG_TYPE_RECORD, :units=>WatchUi.loadResource(Rez.Strings.minPerPkmUnit)}
        );
        currentMinPerPkmField.setData(0.0);

		totalPkmField = createField(
            WatchUi.loadResource(Rez.Strings.totalPkmLong),
            TOTAL_PKM_FIELD_ID,
            Fit.DATA_TYPE_FLOAT,
            {:mesgType=>Fit.MESG_TYPE_SESSION, :units=>WatchUi.loadResource(Rez.Strings.pkmUnit)}
        );
        totalPkmField.setData(0.0);
    }
    
    function loadProperties() {
        var app = Application.getApp();

        var alphaProperty = app.getProperty("alpha");
		alpha = isValidAlphaValue(alphaProperty) ? alphaProperty : 0.9;

        var maxMinPerPkmProperty = app.getProperty("maxMinPerPkm");
		maxMinPerPkm = greaterZero(maxMinPerPkmProperty) ? maxMinPerPkmProperty : 15.0;

        var diplayValueTypeProperty = app.getProperty("diplayValueType");
        if (diplayValueTypeProperty == null || diplayValueTypeProperty == 0) {
        	displayValueType = AVG_PKM;
        } else if (diplayValueTypeProperty == 1) {
        	displayValueType = CUR_PKM;
        } else {
        	displayValueType = AVG_PKM;
        }
    }
    
    function isValidAlphaValue(value) {
    	return greaterZero(value) && value <= 1.0;
    }

    // The given info object contains all the current workout
    // information. Calculate a value and return it in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    // See Activity.Info in the documentation for available information.
    function compute(info) {
    	if (info == null || info.timerState != Activity.TIMER_STATE_ON) {
    		return displayTime(lastDisplayValue);
    	}
    	
    	if ((greaterZero(info.elapsedDistance) || greaterZero(info.totalAscent))
    		&& greaterZero(info.timerTime)) {
    		var totalPkm = updateTotalPkm(info);
			var avgMinPerPkm = updateAverageMinutesPerPkm(info);
			var curMinPerPkm = updateCurrentMinutesPerPkm(info, totalPkm);
			
			lastTotalTimeInMs = info.timerTime;
    		lastTotalPkm = totalPkm;
    		
    		switch (displayValueType) {
    			case AVG_PKM:
    				lastDisplayValue = avgMinPerPkm;
		    		return displayTime(lastDisplayValue);
    			case CUR_PKM:
    				lastDisplayValue = curMinPerPkm;
		    		return displayTime(lastDisplayValue);
    			case TOTAL_PKM:
    				lastDisplayValue = totalPkm;
    				return lastDisplayValue;
    		}
    	}
    	
        return displayTime(lastDisplayValue);
    }

	function updateTotalPkm(info) {
		var totalPkm = (info.elapsedDistance / 1000) + (info.totalAscent / 100);
        totalPkmField.setData(totalPkm);
        return totalPkm;
	}
    
    function updateAverageMinutesPerPkm(info) {
		var avgMinPerPkm = info.timerTime / (60 * info.elapsedDistance + 600 * info.totalAscent);
        averageMinPerPkmField.setData(displayTime(avgMinPerPkm));
        return avgMinPerPkm;
    }
    
    function updateCurrentMinutesPerPkm(info, totalPkm) {
		var timeDeltaInMs = info.timerTime - lastTotalTimeInMs;
		var timeDeltaInMin = timeDeltaInMs / 60000.0;
		var pkmDelta = totalPkm - lastTotalPkm;
		
		var curMinPerPkm = null;
		if (greaterZero(pkmDelta)) {
			curMinPerPkm = timeDeltaInMin / pkmDelta;
		} else {
			// if pkmDelta=0 then curMinPerPkm is +inf
			if (lastCurrentMinutesPerPkm == null) {
				curMinPerPkm = 0.0;
			} else {
				curMinPerPkm = lastCurrentMinutesPerPkm;
			}
		}
		
		var result = null;
		var time_in_s = info.timerTime / 1000.0;
		if (lastCurrentMinutesPerPkm == null || time_in_s <= 0) {
			result = curMinPerPkm;
		} else {
			// given alpha, the smoothed average provokes a lag of 1/alpha steps
			// assume that 1 step corresponds to 1s, then alpha is too small when time_in_s < 1.0 / alpha
			var cur_alpha = max(alpha, 1.0 / time_in_s);  
			result = (cur_alpha * curMinPerPkm) + ((1-cur_alpha) * lastCurrentMinutesPerPkm);
		}

		// apply cap to chart data to avoid outliers
        currentMinPerPkmField.setData(min(result, maxMinPerPkm));
		lastCurrentMinutesPerPkm = result;
        return result;
    }
    
    function greaterZero(value) {
    	return value != null && value > 0.0;
    }
    
    function displayTime(value) {
    	var fullMinutes = Math.floor(value);
    	var fraction = value - fullMinutes;
    	var seconds = Math.round(fraction * 60);
    	return fullMinutes.format("%d") + ":" + seconds.format("%02d");
    }
    
    function max(a, b) {
    	return a > b ? a : b;
    }

    function min(a, b) {
    	return a < b ? a : b;
    }

}